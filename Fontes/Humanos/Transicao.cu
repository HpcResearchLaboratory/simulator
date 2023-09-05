#include "Transicao.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Macros/3_TRA_H.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador é paralelizado para cada AGENTE.

  Rresponsável pela transição de estados de saúde em relação à
  dengue para agentes humanos.

  De acordo com o estado atual do agente chama-se um método
  específico para a transição.
*/
TransicaoEstadosHumanos::TransicaoEstadosHumanos(
  Humanos *humanos, Parametros *parametros, Seeds *seeds
) {
  this->humanos = humanos->PhumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe TransicaoEstadosHumanos.
*/
__host__ __device__
void TransicaoEstadosHumanos::operator()(int id) {
  int idHumano = id;
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  int sd = GET_SD_H(idHumano);

  if (sd == MORTO) return;

  switch (sd) {
    case EXPOSTO: {
      transicaoExposto(idHumano, dist, seed);
    } break;
    case INFECTANTE: {
      transicaoInfectante(idHumano, dist, seed);
    } break;
    case HEMORRAGICO: {
      transicaoHemorragico(idHumano, dist, seed);
    } break;
    case RECUPERADO: {
      transicaoRecuperado(idHumano, dist, seed);
    } break;
  }
}

/*
  Aplica a lógica de transição a um agente humano no estado EXPOSTO.

  Se o período de exposição do agente terminou, ele é passado ao estado
  infectante. Caso contrário, incrementa seu contador de latência.
*/
__host__ __device__
void TransicaoEstadosHumanos::transicaoExposto(
  int idHumano, urd<double> dist, dre& seed
) {
  int c = GET_C_H(idHumano), fe = GET_FE_H(idHumano);
  if (c >= PERIODO_EXPOSTO_HUMANO(fe)) {
    SET_SD_H(idHumano, INFECTANTE);
    SET_C_H(idHumano, 0);
  } else {
    SET_C_H(idHumano, c + 1);
  }
}

/*
  Aplica a lógica de transição a um agente humano no estado INFECTANTE.

  Se o período de infectância do agente terminou, ele é passado ao estado
  recuperado. Caso contrário, incrementa seu contador de latência. O agente
  pode ser passado, probabilisticamente, ao estado hemorrágico da doença.
*/
__host__ __device__
void TransicaoEstadosHumanos::transicaoInfectante(
  int idHumano, urd<double> dist, dre& seed
) {
  int c = GET_C_H(idHumano), fe = GET_FE_H(idHumano), sc = GET_SC_H(idHumano);
  if (c >= PERIODO_INFECTADO_HUMANO(fe)) {
    SET_SD_H(idHumano, RECUPERADO);
    SET_C_H(idHumano, 0);
  } else {
    SET_C_H(idHumano, c + 1);
    int qS = contarSorotipos(sc) - 1;
    if (randPerc <= TAXA_EVOLUCAO_DENGUE_HEMORRAGICA(qS)) {
      SET_SD_H(idHumano, HEMORRAGICO);
      SET_C_H(idHumano, 0);
    }
  }
}

/*
  Aplica a lógica de transição a um agente humano no estado HEMORRAGICO.

  Se o período de permanência em estado hemorrágico do agente terminou, ele é
  passado ao estado recuperado. O agente pode ser passado, probabilisticamente,
  ao estado morto pela dengue hemorrágica.
*/
__host__ __device__
void TransicaoEstadosHumanos::transicaoHemorragico(
  int idHumano, urd<double> dist, dre& seed
) {
  int c = GET_C_H(idHumano), fe = GET_FE_H(idHumano);
  if (c >= PERIODO_HEMORRAGICO_HUMANO(fe)) {
    SET_SD_H(idHumano, RECUPERADO);
    SET_C_H(idHumano, 0);
  } else {
    SET_C_H(idHumano, c + 1);
    if (randPerc <= TAXA_MORTE_DENGUE) {
      SET_SD_H(idHumano, MORTO);
    }
  }
}

/*
  Aplica a lógica de transição a um agente humano no estado RECUPERADO.

  Se o período de recuperação do agente terminou, ele é passado ao estado
  suscetível.
*/
__host__ __device__
void TransicaoEstadosHumanos::transicaoRecuperado(
  int idHumano, urd<double> dist, dre& seed
) {
  int c = GET_C_H(idHumano), fe = GET_FE_H(idHumano);
  if (c >= PERIODO_RECUPERADO_HUMANO(fe)) {
    SET_SD_H(idHumano, SUSCETIVEL);
    SET_C_H(idHumano, 0);
  } else {
    SET_C_H(idHumano, c + 1);
  }
}

/*
  Determina com quantos sorotipos diferentes o agente já foi infectado.
*/
__host__ __device__
int TransicaoEstadosHumanos::contarSorotipos(int sc) {
  // Adaptado de "Hacker's Delight", pág. 66, Figura 5-2.
  sc -= (sc >> 1) & 5;
  return (sc & 3) + ((sc >> 2) & 3);
}

/*
  Este operador é paralelizado para cada LOCALIDADE do ambiente.

  Aplica as dosagens de vacinação, alterando o estado interno dos
  agentes afetados.
*/
CampanhaVacinacao::CampanhaVacinacao(
  Humanos *humanos, Ambiente *ambiente, Parametros *parametros, int ciclo,
  int sizeQuadVac, int sizeFEVac, int sizePerVac, int sizeCicVac, Seeds *seeds
) {
  this->humanos = humanos->PhumanosDev;
  this->indHumanos = humanos->PindHumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->sizeQuadVac = sizeQuadVac;
  this->sizeFEVac = sizeFEVac;
  this->sizePerVac = sizePerVac;
  this->sizeCicVac = sizeCicVac;
  this->quadVac = ambiente->PquadVacDev;
  this->fEVac = ambiente->PfEVacDev;
  this->perVac = ambiente->PperVacDev;
  this->cicVac = ambiente->PcicVacDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe CampanhaVacinacao.
*/
__host__ __device__
void CampanhaVacinacao::operator()(int id) {
  if (not periodoCampanhaVacinacao()) return;

  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);
  int fe_h, sd_h;

  // Determina a localidade que receberá vacinação
  int l = quadVac[id];

  // TODO Verificar a lógica que define este trecho / refatorar!
  double percentualVacinacao = 1.0 / perVac[0];

  // Percorre o vetor de agentes no recorte da localidade especificada
  for (int idHumano = indHumanos[l]; idHumano < indHumanos[l + 1]; ++idHumano) {
    // Acesso aos atributos do agente
    sd_h = GET_SD_H(idHumano);
    fe_h = GET_FE_H(idHumano);

    if (not faixaEtariaTeraVacinacao(fe_h)) continue;

    // Os agentes são vacinados probabilisticamente de acordo com o percentual
    if (sd_h == SUSCETIVEL and randPerc <= percentualVacinacao) {
      // Incrementa o contador de vacinações do agente
      int cvTotal = GET_CV_H(idHumano) + 1;
      SET_CV_H(idHumano, cvTotal);

      // A partir da terceira vacinação o agente pode ser imunizado
      if (cvTotal >= 3 and randPerc <= TAXA_EFICACIA_VACINA) {
        SET_SD_H(idHumano, IMUNIZADO);
      }
    }
  }
}

/*
  Verifica se há um período de campanha de vacinação ativo no ciclo atual.
*/
__host__ __device__
bool CampanhaVacinacao::periodoCampanhaVacinacao() {
  if (perVac[1] < perVac[0]) {
    for (int i = 0; i < sizeCicVac; ++i) {
      if (ciclo >= cicVac[i] and ciclo < (cicVac[i] + perVac[0])) {
        return true;
      }
    }
  }
  return false;
}

/*
  Verifica se a faixa etária passada como argumento deve receber vacinação.
*/
__host__ __device__
bool CampanhaVacinacao::faixaEtariaTeraVacinacao(int fe) {
  for (int i = 0; i < sizeFEVac; ++i) {
    if (fEVac[i] == fe) {
      return true;
    }
  }
  return false;
}

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.

  Incrementa o indicador do dia de vacinação (perVac[1]).
*/
PosCampanhaVacinacao::PosCampanhaVacinacao(
  Ambiente *ambiente, int ciclo, int sizePerVac, int sizeCicVac
) {
  this->ciclo = ciclo;
  this->sizePerVac = sizePerVac;
  this->sizeCicVac = sizeCicVac;
  this->perVac = ambiente->PperVacDev;
  this->cicVac = ambiente->PcicVacDev;
}

/*
  Operador () da classe PosCampanhaVacinacao.
*/
__host__ __device__
void PosCampanhaVacinacao::operator()(int id) {
  bool houveVacinacao = false;
  if (perVac[1] < perVac[0]) {
    for (int i = 0; i < sizeCicVac; ++i) {
      if (ciclo >= cicVac[i] and ciclo < (cicVac[i] + perVac[0])) {
        houveVacinacao = true;
        break;
      }
    }
  }
  // Se houve vacinação a campanha avança para o próximo dia.
  if (houveVacinacao) perVac[1]++;
  else perVac[1] = 0;
}

/*
  Este operador é paralelizado para as entradas de vacinação.

  Atualiza o contador de vacinas e imuniza agentes de acordo com o
  especificado no arquivo de entrada "Ambiente/2-CON.csv".
  Para a localidade especificada, busca-se um agente com os atributos
  (sexo e faixa etária) correspondentes ao que está definido no vetor
  "vacs", e seu atributo "cv" é atualizado de acordo
  com o número definido de doses. Para 3 doses o agente é imunizado.
*/
InsercaoVacinados::InsercaoVacinados(
  Humanos *humanos, Ambiente *ambiente, Parametros *parametros,
  int ciclo, Seeds *seeds
) {
  this->humanos = humanos->PhumanosDev;
  this->indHumanos = humanos->PindHumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->vacs = ambiente->PvacsDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe InsercaoVacinados.
*/
__host__ __device__
void InsercaoVacinados::operator()(int id) {
  // Filtra as inserções passadas e futuras
  if (vacs[id].processado) return;
  if (vacs[id].ciclo > ciclo) return;

  // Acesso aos atributos da vacinação
  int q = vacs[id].quadra;
  int s = vacs[id].sexo;
  int fe = vacs[id].faixaEtaria;
  int doses = vacs[id].doses;

  // Percorre o vetor de agentes no recorte da quadra especificada
  for (int idHumano = indHumanos[q]; idHumano < indHumanos[q + 1]; idHumano++) {
    // Acesso aos atributos do agente humano
    int q_h = GET_Q_H(idHumano);
    int s_h = GET_S_H(idHumano);
    int fe_h = GET_FE_H(idHumano);
    int sd_h = GET_SD_H(idHumano);
    int cv_h = GET_CV_H(idHumano);

    // Filtra os humanos compatíveis com os atributos da vacinação
    if (q_h != q or s_h != s or fe_h != fe) continue;

    // Filtra apenas humanos suscetíveis / recuperados
    if (sd_h != SUSCETIVEL and sd_h != RECUPERADO) continue;

    // Ignora agentes já vacinados
    if (cv_h > 0) continue;

    SET_CV_H(idHumano, doses);

    // Para vacinações de 3 doses, imuniza o agente
    if (doses == 3) SET_SD_H(idHumano, IMUNIZADO);

    // Marca a vacinação como processada
    vacs[id].processado = true;
    break;
  }
}
