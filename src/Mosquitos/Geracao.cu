#include "Geracao.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Macros/1_MOV_M.h"
#include "Fontes/Macros/5_GER_M.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Macros/MacrosGerais.h"
#include "Fontes/Seeds.h"

/*
  Este operador é paralelizado para cada AGENTE.
  
  Este operador é responsável pela estimativa da quantidade de ovos que serão
  inseridos no ambiente em decorrência do acasalamento entre mosquitos.

  Para isso, inicialmente são filtradas todas as fêmeas acasaladas.
  Para cada fêmea, são analisados os seguintes atributos:
    CE - Contador de ciclos entre posturas
    CG - Ciclos de gestação

  Antes de estar apta para postura, cada fêmea deve esperar um certo número
  de ciclos, representado pelos parâmetros:
    INTERVALO_ENTRE_POSTURAS_FEMEA + CICLOS_GESTACAO

  Além disso, para a postura de ovos a fêmea deve estar alimentada (repasto)
  e deve estar em um ponto de foco.

  Caso as condições para postura estejam cumpridas, a fêmea é marcada como
  apta para postura (FG - Flag de geração de ovos), e seus contadores são
  reiniciados.

  Caso a fêmea seja estéril ou esteja fora de uma posição de foco, a postura
  será realizada entretanto nenhum ovo sobreviverá, portanto seus ovos não são
  contabilizados.
*/
PreGeracao::PreGeracao(
  Ambiente *ambiente, Mosquitos *mosquitos,
  Parametros *parametros, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->seeds = seeds->PseedsDev;
  this->indFocos = ambiente->PindFocosDev;
  this->focos = ambiente->PfocosDev;
  this->pos = ambiente->PposDev;
  this->indQuadras = ambiente->PindQuadrasDev;
}

/*
  Operador () da classe PreGeracao.
*/
__host__ __device__
int PreGeracao::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);
  int nMosquitos = 0;

  int vd_m = GET_VD_M(id);
  int s_m = GET_S_M(id);
  int fs_m = GET_FS_M(id);
  int ta_m = GET_TA_M(id);

  // Filtra apenas fêmeas acasaladas
  if (vd_m == MORTO or s_m == MACHO) return 0;
  if (fs_m != ATIVA and fs_m != DECADENTE) return 0;
  if (ta_m == NENHUM) return 0;

  int ce_m = GET_CE_M(id);
  int cg_m = GET_CG_M(id);
  int pr_m = GET_PR_M(id);
  int am_m = GET_AM_M(id);

  if (ce_m < INTERVALO_ENTRE_POSTURAS_FEMEA) {
    SET_CE_M(id, ce_m + 1);
  } else { // Caso o intervalo entre posturas tenha acabado
    if (cg_m < CICLOS_GESTACAO) {
      SET_CG_M(id, cg_m + 1);
    } else { // Caso a gestação esteja concluída
      // Reinicia os contadores
      SET_CE_M(id, 0);
      SET_CG_M(id, 0);
      // Contabiliza os ovos e marca a fêmea como apta, caso esteja
      if (am_m == ALIMENTADO) {
        // Ativa a flag de geração de ovos
        SET_FG_M(id, 1);
        // Ignora fêmeas estéreis e fora de posições de foco
        if (pr_m != ESTERIL and estaEmFoco(id)) {
          nMosquitos += max(AS21_MAX, AI21_MAX);
        }
      }
    }
  }

  return nMosquitos;
}

/*
  Verifica se a posição atual de determinado mosquito é um ponto de foco. 
*/
__host__ __device__
bool PreGeracao::estaEmFoco(int id) {
  int x = GET_X_M(id); int y = GET_Y_M(id);
  int q = GET_Q_M(id); int l = GET_L_M(id);

  int inicioFocos = indFocos[indQuadras[q * 2] + l];
  int finalFocos = indFocos[indQuadras[q * 2] + l + 1];

  if (inicioFocos >= finalFocos) return false;
  
  for (int i = inicioFocos; i < finalFocos; i++) {
    if (x == pos[focos[i]].x and y == pos[focos[i]].y) {
      return true;
    }
  }
  return false;
}

/*
  Este operador é paralelizado para cada AGENTE.

  Este operador determina e insere os ovos que entrarão no ambiente resultantes
  da postura das fêmeas do mosquito.

  Inicialmente, são filtradas apenas as fêmeas acasaladas e marcadas como
  aptas para postura.

  O contador de postura é incrementado, e a partir deste valor verifica-se
  quando a fêmea necessita realizar repasto novamente. Nesse caso, a flag de
  alimentação do agente é desativada.

  Para fêmeas estéreis ou que não se encontram em um ponto de foco, os ovos
  são descartados (não sobrevivem). Além disso, caso a realocação do vetor não
  tenha ocorrido por limitações de memória, a postura também é cancelada.

  Finalmente, para as fêmeas que cumprem os requisitos, determina-se a
  quantidade e o tipo de ovos para inserção no ambiente de simulação.
*/
Geracao::Geracao(
  Ambiente *ambiente, Mosquitos *mosquitos,
  Parametros *parametros, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->nMosquitos = mosquitos->nMosquitos;
  this->parametros = parametros->PparametrosDev;
  this->alocarMosquitos = mosquitos->alocarMosquitos;
  this->seeds = seeds->PseedsDev;
  this->indFocos = ambiente->PindFocosDev;
  this->focos = ambiente->PfocosDev;
  this->pos = ambiente->PposDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->capFocos = ambiente->PcapFocosDev;
}

/*
  Operador () da classe Geracao.
*/
__host__ __device__
void Geracao::operator()(int id) {
  // dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);
  int i = 0;

  for (int id = 0; id < nMosquitos; ++id) {

    int vd_m = GET_VD_M(id);
    int s_m = GET_S_M(id);
    int fs_m = GET_FS_M(id);
    int ta_m = GET_TA_M(id);
    int fg_m = GET_FG_M(id);
    int cp_m = GET_CP_M(id);
    int pr_m = GET_PR_M(id);

    // Filtra apenas fêmeas acasaladas
    if (vd_m == MORTO or s_m == MACHO) continue;
    if (fs_m != ATIVA and fs_m != DECADENTE) continue;
    if (ta_m == NENHUM) continue;

    // Filtra fêmeas aptas para postura
    if (fg_m == 0) continue;

    // Incrementa o contador de posturas da fêmea e desativa a flag de geração
    SET_CP_M(id, cp_m + 1);
    SET_FG_M(id, 0);

    // Marca a fêmea como não alimentada
    SET_AM_M(id, NAO_ALIMENTADO);

    // Ignora fêmeas estéreis ou fora de posições de foco
    if (pr_m == ESTERIL or not estaEmFoco(id)) continue;

    // A postura não ocorre caso a realocação do vetor não tenha ocorrido
    if (alocarMosquitos) postura(id, i);
  }
}

/*
  Este método determina a quantidade e tipo dos ovos a serem
  inseridos a partir dos atributos internos da fêmea.
*/
__host__ __device__
void Geracao::postura(int id, int &i) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  int pr_m = GET_PR_M(id);
  int fs_m = GET_FS_M(id);

  switch (pr_m) {
    case SAUDAVEL: {
      switch (fs_m) {
        case ATIVA: {
          inserirOvos(id, i, AS21, PS21, SAUDAVEL);
        } break;
        case DECADENTE: {
          inserirOvos(id, i, H1 * AS21, PS31, SAUDAVEL);
        } break;
      }
    } break;
    case WOLBACHIA: {
      switch (fs_m) {
        case ATIVA: {
          inserirOvos(id, i, AI21, PI21, WOLBACHIA);
        } break;
        case DECADENTE: {
          inserirOvos(id, i, H2 * AI21, PI31, WOLBACHIA);
        } break;
      }
    } break;
  }
}

/*
  Organiza e executa a inserção de uma determinada
  quantidade de ovos com os atributos especificados.
*/
__host__ __device__
void Geracao::inserirOvos(int id, int& i, int total, double frac, int sw) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);
  int x = GET_X_M(id), y = GET_Y_M(id);
  int l = GET_L_M(id), q = GET_Q_M(id);

  // Calcula o número de ovos que podem efetivamente ser inseridos,
  // considerando o limite dos focos.
  int idFoco = getIdFoco(id);
  if (idFoco == -1) return;
  int espacoParaOvos = LIMITE_FOCOS - capFocos[idFoco];
  if (espacoParaOvos <= 0) return;
  
  // Determina o número de machos e fêmeas
  int inseridos = (total > espacoParaOvos) ? espacoParaOvos : total;
  int nFemeas = lround(inseridos * frac);
  int nMachos = inseridos - nFemeas;

  // Contabiliza os ovos inseridos no foco
  capFocos[idFoco] += inseridos;

  // Inserção dos ovos machos.
  inserirMosquitos(nMachos, MACHO, sw, OVO, SUSCETIVEL, 0, q, l, x, y, i);
  // Inserção dos ovos fêmeas.
  inserirMosquitos(nFemeas, FEMEA, sw, OVO, SUSCETIVEL, 0, q, l, x, y, i);
}

/*
  Organiza e executa a inserção de uma determinada
  quantidade de mosquitos com os atributos especificados.
*/
__host__ __device__
void Geracao::inserirMosquitos(
  int quantidade, int s, int sw, int fs, int sd, int st,
  int q, int l, int x, int y, int& i
) {
  for (int j = 0; j < quantidade; ++j) {
    // Inicialização do novo agente.
    inicializarMosquito(i++, s, sw, fs, sd, st, q, l, x, y);
  }
}

/*
  Método de inicialização de agentes mosquitos.
  São atribuídos valores padrão para os atributos necessários,
  além de valores determinados pelos parâmetros desta função.
*/
__host__ __device__
void Geracao::inicializarMosquito(
  int id, int s, int sw, int fs, int sd, int st,
  int q, int l, int x, int y
) {
  SET_S_M(id, s);
  SET_SW_M(id, sw);
  SET_FS_M(id, fs);
  SET_IE_M(id, 0);
  SET_SD_M(id, sd);
  SET_ST_M(id, st);
  SET_VD_M(id, VIVO);
  SET_C_M(id, 0);

  SET_CR_M(id, 0);
  SET_FG_M(id, 0);
  SET_TI_M(id, SEM_INFLUENCIA);
  SET_FM_M(id, 1);
  SET_FP_M(id, 0);
  SET_FV_M(id, 0);
  SET_CG_M(id, 0);
  SET_CE_M(id, 0);
  SET_PR_M(id, NENHUM);
  SET_AM_M(id, 0);
  SET_TA_M(id, NENHUM);
  SET_CP_M(id, 0);

  SET_X_M(id, x);
  SET_Q_M(id, q);

  SET_Y_M(id, y);
  SET_L_M(id, l);

  // Sorteia um identificador para o novo agente
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);
  SET_ID_M(id, ENTRE_FAIXA(0, MAX_UINT32, randPerc));
}

/*
  Verifica se a posição atual de determinado mosquito é um ponto de foco. 
*/
__host__ __device__
bool Geracao::estaEmFoco(int id) {
  int x = GET_X_M(id); int y = GET_Y_M(id);
  int q = GET_Q_M(id); int l = GET_L_M(id);

  int inicioFocos = indFocos[indQuadras[q * 2] + l];
  int finalFocos = indFocos[indQuadras[q * 2] + l + 1];

  if (inicioFocos >= finalFocos) return false;
  
  for (int i = inicioFocos; i < finalFocos; i++) {
    if (x == pos[focos[i]].x and y == pos[focos[i]].y) {
      return true;
    }
  }
  return false;
}

/*
  Caso o agente esteja em um ponto de foco,
  retorna o índice desta posição no vetor de focos.
*/
__host__ __device__
int Geracao::getIdFoco(int id) {
  int x = GET_X_M(id); int y = GET_Y_M(id);
  int q = GET_Q_M(id); int l = GET_L_M(id);

  int inicioFocos = indFocos[indQuadras[q * 2] + l];
  int finalFocos = indFocos[indQuadras[q * 2] + l + 1];

  if (inicioFocos >= finalFocos) return -1;
  
  for (int i = inicioFocos; i < finalFocos; i++) {
    if (x == pos[focos[i]].x and y == pos[focos[i]].y) {
      return i;
    }
  }
  return -1;
}
