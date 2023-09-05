#include "Controle.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Macros/3_TRA_M.h"
#include "Fontes/Macros/4_CON_M.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Macros/MacrosGerais.h"
#include <stdio.h>

/*
  Este operador é paralelizado para cada AGENTE.

  Responsável por eliminar, de acordo com um parâmetro
  probabilístico de idade máxima, os mosquitos que estão no fim de seu ciclo
  de vida (fase decadente).

  A taxa de sobrevivência é diferente de acordo com a saúde do mosquito, tanto
  em relação ao vírus da dengue quanto à presença de Wolbachia.
*/
ControleNaturalMosquitosPorIdade::ControleNaturalMosquitosPorIdade(
  Mosquitos *mosquitos, Parametros *parametros, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe ControleNaturalMosquitosPorIdade.
*/
__host__ __device__
void ControleNaturalMosquitosPorIdade::operator()(int id) {
  int idMosquito = id;
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  // Filtra apenas mosquitos vivos e na fase decadente
  if (GET_VD_M(idMosquito) == MORTO) return;
  if (GET_FS_M(idMosquito) != DECADENTE) return;

  int ie = GET_IE_M(idMosquito);
  int sw = GET_SW_M(idMosquito);
  int s = GET_S_M(idMosquito);

  if (GET_SD_M(idMosquito) == INFECTANTE) {
    if (ie >= IDADE_MAX_MOSQUITOS_DENGUE) {
      SET_VD_M(idMosquito, MORTO);
    }
  } else {
    if (ie >= IDADE_MAX_MOSQUITOS_DECADENTES(s, sw)) {
      SET_VD_M(idMosquito, MORTO);
    }
  }
}

/*
  Este operador é paralelizado para cada POSIÇÃO do ambiente.
  
  Controle de mosquitos por mortalidade natural.
*/
ControleNaturalMosquitosPorSelecao::ControleNaturalMosquitosPorSelecao(
  Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
  int ciclo, int idLira, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->pos = ambiente->PposDev;
  this->cli = ambiente->PcliDev;
  this->seeds = seeds->PseedsDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->indFocos = ambiente->PindFocosDev;
  this->focos = ambiente->PfocosDev;
  this->idLira = idLira;
  this->nLira = ambiente->nLira;
  this->contrLira = ambiente->PcontrLiraDev;
  this->sizePontEst = ambiente->sizePontEst;
  this->pontEst = ambiente->PpontEstDev;
  this->capFocos = ambiente->PcapFocosDev;
}

/*
  Operador () da classe ControleNaturalMosquitosPorSelecao.
*/
__host__ __device__
void ControleNaturalMosquitosPorSelecao::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  if (not (FREQ_CONTROLE_NATURAL_SELECAO > 0 and ciclo > 0 and
      ciclo % FREQ_CONTROLE_NATURAL_SELECAO == 0)) return;

  int x = pos[id].x, y = pos[id].y;
  int l = pos[id].lote, q = pos[id].quadra;

  int l_m, x_m, y_m, vd_m;

  // Calcula as taxas de eliminação para cada combinação de fase e saúde
  double tMSO = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(OVO, MACHO, SAUDAVEL);
  double tMSL = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(LARVA, MACHO, SAUDAVEL);
  double tMSP = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(PUPA, MACHO, SAUDAVEL);
  double tMSA = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(ATIVA, MACHO, SAUDAVEL);
  double tMWO = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(OVO, MACHO, WOLBACHIA);
  double tMWL = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(LARVA, MACHO, WOLBACHIA);
  double tMWP = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(PUPA, MACHO, WOLBACHIA);
  double tMWA = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(ATIVA, MACHO, WOLBACHIA);
  double tFSO = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(OVO, FEMEA, SAUDAVEL);
  double tFSL = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(LARVA, FEMEA, SAUDAVEL);
  double tFSP = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(PUPA, FEMEA, SAUDAVEL);
  double tFSA = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(ATIVA, FEMEA, SAUDAVEL);
  double tFWO = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(OVO, FEMEA, WOLBACHIA);
  double tFWL = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(LARVA, FEMEA, WOLBACHIA);
  double tFWP = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(PUPA, FEMEA, WOLBACHIA);
  double tFWA = TAXA_ELIM_CONTROLE_NATURAL_SELECAO(ATIVA, FEMEA, WOLBACHIA);

  if (idLira != -1) {
    tMSO *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tMWO *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tFSO *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tFWO *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tMSL *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tMWL *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tFSL *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tFWL *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tMSP *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tMWP *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tFSP *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tFWP *= ENTRE_FAIXA(cli[ciclo].txMinNaoAlados, cli[ciclo].txMaxNaoAlados, randPerc);
    tMSA *= ENTRE_FAIXA(cli[ciclo].txMinAlados, cli[ciclo].txMaxAlados, randPerc);
    tMWA *= ENTRE_FAIXA(cli[ciclo].txMinAlados, cli[ciclo].txMaxAlados, randPerc);
    tFSA *= ENTRE_FAIXA(cli[ciclo].txMinAlados, cli[ciclo].txMaxAlados, randPerc);
    tFWA *= ENTRE_FAIXA(cli[ciclo].txMinAlados, cli[ciclo].txMaxAlados, randPerc);
  }

  // Multiplica o controle para ovos de acordo com a distribuição de focos
  if (estaEmFoco(x, y, q, l)) { // 0.65
    if (idLira == -1) { // Pre-processamento
      tMSO *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tFSO *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tMWO *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tFWO *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tMSL *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tFSL *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tMWL *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tFWL *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tMSP *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tFSP *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tMWP *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
      tFWP *= TAXA_CONTROLE_OVOS_EM_FOCOS(0);
    } else {
      // double modControle = 0.65;
      int nivelLira = contrLira[nLira * q + idLira];
      tMSO *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tFSO *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tMWO *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tFWO *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tMSL *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tFSL *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tMWL *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tFWL *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tMSP *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tFSP *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tMWP *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
      tFWP *= TAXA_CONTROLE_OVOS_EM_FOCOS(nivelLira);
    }
  }

  for (int idM = indMosquitos[q]; idM < indMosquitos[q + 1]; ++idM) {
    l_m  = GET_L_M(idM); x_m  = GET_X_M(idM);
    y_m  = GET_Y_M(idM); vd_m = GET_VD_M(idM);

    if (vd_m == MORTO or l_m != l or x_m != x or y_m != y) continue;

    remove(seed, dist, idM, MACHO, SAUDAVEL, OVO, tMSO);
    remove(seed, dist, idM, MACHO, SAUDAVEL, LARVA, tMSL);
    remove(seed, dist, idM, MACHO, SAUDAVEL, PUPA, tMSP);
    remove(seed, dist, idM, MACHO, SAUDAVEL, ATIVA, tMSA);

    remove(seed, dist, idM, MACHO, WOLBACHIA, OVO, tMWO);
    remove(seed, dist, idM, MACHO, WOLBACHIA, LARVA, tMWL);
    remove(seed, dist, idM, MACHO, WOLBACHIA, PUPA, tMWP);
    remove(seed, dist, idM, MACHO, WOLBACHIA, ATIVA, tMWA);

    remove(seed, dist, idM, FEMEA, SAUDAVEL, OVO, tFSO);
    remove(seed, dist, idM, FEMEA, SAUDAVEL, LARVA, tFSL);
    remove(seed, dist, idM, FEMEA, SAUDAVEL, PUPA, tFSP);
    remove(seed, dist, idM, FEMEA, SAUDAVEL, ATIVA, tFSA);

    remove(seed, dist, idM, FEMEA, WOLBACHIA, OVO, tFWO);
    remove(seed, dist, idM, FEMEA, WOLBACHIA, LARVA, tFWL);
    remove(seed, dist, idM, FEMEA, WOLBACHIA, PUPA, tFWP);
    remove(seed, dist, idM, FEMEA, WOLBACHIA, ATIVA, tFWA);
  }
}

/*
  Altera os atributos internos de um agente para identificá-lo
  como morto, sendo removido da lógica da simulação.
*/
__host__ __device__
void ControleNaturalMosquitosPorSelecao::remove(
  dre& seed, urd<double>& dist, int idM,
  int s, int sw, int fs, double prob
) {
  int s_m = GET_S_M(idM), sw_m = GET_SW_M(idM), fs_m = GET_FS_M(idM);
  if (s_m == s and sw_m == sw and fs_m == fs and randPerc <= prob) {
    // Para ovos, larvas e pupas, libera espaço em capFocos
    if (fs_m < ATIVA) {
      int idFoco = getIdFoco(idM);
      if (idFoco != -1) capFocos[idFoco]--;
    }
    SET_VD_M(idM, MORTO);
  }
}

/*
  Caso o agente esteja em um ponto de foco,
  retorna o índice desta posição no vetor de focos.
*/
__host__ __device__
int ControleNaturalMosquitosPorSelecao::getIdFoco(int idM) {
  int x = GET_X_M(idM); int y = GET_Y_M(idM);
  int q = GET_Q_M(idM); int l = GET_L_M(idM);

  // Retorna o índice do ponto de foco
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

/*
  Verifica se a posição indicada é um ponto de foco.
*/
__host__ __device__
bool ControleNaturalMosquitosPorSelecao::estaEmFoco(
  int x, int y, int q, int l
) {
  // Checa se o ponto é um foco ou não
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
  Verifica se a quadra indicada é um Ponto Estratégico.
*/
__host__ __device__
bool ControleNaturalMosquitosPorSelecao::estaEmPE(int q, int l) {
  // Checa se o lote é um ponto estratégico
  for (int i = 0; i < sizePontEst; i += 2) {
    if (q == pontEst[i] and l == pontEst[i + 1]) {
      return true;
    }
  }
  return false;
}

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.

  Responsável por determinar a intensidade do efeito residual dos controles
  químicos que serão aplicados no ciclo atual.
*/
PreControlesMosquitos::PreControlesMosquitos(
  Ambiente *ambiente, Parametros *parametros,
  int ciclo, int idContr, Seeds *seeds
) {
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->idContr = idContr;
  this->contr = ambiente->PcontrDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe PreControlesMosquitos.
*/
__host__ __device__
void PreControlesMosquitos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  if (
    (contr[idContr].tipoControle == 'R'
    or contr[idContr].tipoControle == 'T'
    or contr[idContr].tipoControle == 'P')
    and ciclo == contr[idContr].ciclo
  ) {
    contr[idContr].efeRes = ENTRE_FAIXA(
      contr[idContr].taxaMinQuimico,
      contr[idContr].taxaMaxQuimico, randPerc
    );
  }
}

/*
  Este operador é paralelizado para cada POSIÇÃO do ambiente.

  Responsável pela aplicação das rotinas de controle artificial.
*/
ControlesMosquitos::ControlesMosquitos(
  Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
  int ciclo, int idContr, int sizePontEst, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->idContr = idContr;
  this->pos = ambiente->PposDev;
  this->contr = ambiente->PcontrDev;
  this->pontEst = ambiente->PpontEstDev;
  this->sizePontEst = sizePontEst;
  this->indContrPontos = ambiente->PindContrPontosDev;
  this->contrPontos = ambiente->PcontrPontosDev;
  this->indRaios = ambiente->PindRaiosDev;
  this->raios = ambiente->PraiosDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe ControlesMosquitos.
*/
__host__ __device__
void ControlesMosquitos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  int x = pos[id].x, y = pos[id].y;
  int l = pos[id].lote, q = pos[id].quadra;

  if (q == RUA) return;
  if (contr[idContr].quadra != q) return;

  bool TemRaio = temRaio(q, l, x, y);
  bool TemPE = temPE(q, l);
  bool TemTratamento = temTratamento(q, l, x, y);
  bool TemBloqueio = temBloqueio(q, l, x, y);

  if (contr[idContr].efeRes > 0 and (TemRaio or TemPE or TemTratamento)) {
    controleQuimicoNaoAlados(seed, dist, x, y, l, q, contr[idContr].efeRes);
  }

  if (contr[idContr].ciclo == ciclo) {
    if (TemRaio or TemPE or TemTratamento) {
      controleMecanicoNaoAlados(seed, dist, x, y, l, q);
    }

    if (TemBloqueio) {
      controleQuimicoAlados(seed, dist, x, y, l, q);
    }
  }
}

/*
  Retorna se existe efeito do controle tipo Raio
  em determinada posição do ambiente.
*/
__host__ __device__
bool ControlesMosquitos::temRaio(int q, int l, int x, int y) {
  if (contr[idContr].tipoControle != 'R') {
    return false;
  }

  for (int i = indRaios[idContr]; i < indRaios[idContr + 1]; ++i) {
    if (raios[i].quadra == q and raios[i].lote == l and
        raios[i].x == x and raios[i].y == y) {
      return true;
    }
  }

  return false;
}

/*
  Retorna se existe efeito do controle tipo Bloqueio
  em determinada posição do ambiente.
*/
__host__ __device__
bool ControlesMosquitos::temBloqueio(int q, int l, int x, int y) {
  if (contr[idContr].tipoControle != 'B') {
    return false;
  }

  for (int i = indContrPontos[idContr]; i < indContrPontos[idContr + 1]; ++i) {
    if (contrPontos[i].quadra == q and contrPontos[i].lote == l and
        contrPontos[i].x == x and contrPontos[i].y == y) {
      return true;
    }
  }

  return false;
}

/*
  Retorna se existe efeito do controle tipo PE
  em determinada posição do ambiente.
*/
__host__ __device__
bool ControlesMosquitos::temPE(int q, int l) {
  if (contr[idContr].tipoControle != 'P') {
    return false;
  }

  int quadra, lote;
  for (int i = 0; i < sizePontEst; i += 2) {
    quadra = pontEst[i];
    lote = pontEst[i + 1];

    if (q == quadra and l == lote) {
      return true;
    }
  }

  return false;
}

/*
  Retorna se existe efeito do controle tipo Tratamento
  em determinada posição do ambiente.
*/
__host__ __device__
bool ControlesMosquitos::temTratamento(int q, int l, int x, int y) {
  if (contr[idContr].tipoControle != 'T') {
    return false;
  }

  for (int i = indContrPontos[idContr]; i < indContrPontos[idContr + 1]; ++i) {
    if (contrPontos[i].quadra == q and contrPontos[i].lote == l and
        contrPontos[i].x == x and contrPontos[i].y == y) {
      return true;
    }
  }

  return false;
}

/*
  Aplica controle químico com a taxa especificada sobre a população
  de mosquitos na fase aquática.
*/
__host__ __device__
void ControlesMosquitos::controleQuimicoNaoAlados(
  dre& seed, urd<double>& dist,
  int x, int y, int l, int q, double taxa
) {
  int l_m, x_m, y_m, vd_m, fs_m;

  for (int idMosquito = indMosquitos[q];
      idMosquito < indMosquitos[q + 1]; ++idMosquito) {
    l_m = GET_L_M(idMosquito); x_m = GET_X_M(idMosquito);
    y_m = GET_Y_M(idMosquito); vd_m = GET_VD_M(idMosquito);
    fs_m = GET_FS_M(idMosquito);

    if (vd_m == MORTO or l_m != l or x_m != x or y_m != y
       or fs_m == ATIVA or fs_m == DECADENTE) continue;

    if (randPerc <= taxa) {
      SET_VD_M(idMosquito, MORTO);
    }
  }
}

/*
  Aplica controle mecânico sobre a população
  de mosquitos na fase aquática.
*/
__host__ __device__
void ControlesMosquitos::controleMecanicoNaoAlados(
  dre& seed, urd<double>& dist,
  int x, int y, int l, int q
) {
  int l_m, x_m, y_m, vd_m, fs_m;

  double taxa = ENTRE_FAIXA(contr[idContr].taxaMinMecanico,
                            contr[idContr].taxaMaxMecanico, randPerc);

  for (int idMosquito = indMosquitos[q];
      idMosquito < indMosquitos[q + 1]; ++idMosquito) {
    l_m = GET_L_M(idMosquito); x_m = GET_X_M(idMosquito);
    y_m = GET_Y_M(idMosquito); vd_m = GET_VD_M(idMosquito);
    fs_m = GET_FS_M(idMosquito);

    if (vd_m == MORTO or l_m != l or x_m != x or y_m != y
       or fs_m == ATIVA or fs_m == DECADENTE) continue;

    if (randPerc <= taxa) {
      SET_VD_M(idMosquito, MORTO);
    }
  }
}

/*
  Aplica controle químico sobre a população
  de mosquitos na fase adulta.
*/
__host__ __device__
void ControlesMosquitos::controleQuimicoAlados(
  dre& seed, urd<double>& dist,
  int x, int y, int l, int q
) {
  int l_m, x_m, y_m, fs_m, vd_m;

  double taxa = ENTRE_FAIXA(contr[idContr].taxaMinQuimico,
                            contr[idContr].taxaMaxQuimico, randPerc);

  for (int idMosquito = indMosquitos[q];
      idMosquito < indMosquitos[q + 1]; ++idMosquito) {
    l_m = GET_L_M(idMosquito); x_m = GET_X_M(idMosquito);
    y_m = GET_Y_M(idMosquito); fs_m = GET_FS_M(idMosquito);
    vd_m = GET_VD_M(idMosquito);

    if (vd_m == MORTO or l_m != l or x_m != x or y_m != y) continue;

    if ((fs_m == ATIVA or fs_m == DECADENTE) and randPerc <= taxa) {
      SET_VD_M(idMosquito, MORTO);
    }
  }
}

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.

  Responsável por atualizar (decair) o nível residual de controles quimicos.
*/
PosControlesMosquitos::PosControlesMosquitos(
  Ambiente *ambiente, Parametros *parametros,
  int idContr, Seeds *seeds
) {
  this->parametros = parametros->PparametrosDev;
  this->idContr = idContr;
  this->contr = ambiente->PcontrDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe PosControlesMosquitos.
*/
__host__ __device__
void PosControlesMosquitos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  if (contr[idContr].efeRes > 0 and
      (contr[idContr].tipoControle == 'R'
       or contr[idContr].tipoControle == 'T'
       or contr[idContr].tipoControle == 'P')) {
    contr[idContr].efeRes -= DECAIMENTO_CONTROLES_QUIMICOS;
  }
}

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.

  Calcula a quantidade estimada de agentes que serão inseridos para
  realizar o controle biológico.
*/
PreControleBiologico::PreControleBiologico(
  Parametros *parametros, int ciclo
) {
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe PreControleBiologico.
*/
__host__ __device__
int PreControleBiologico::operator()(int id) {
  int nMosquitos = 0;

  if (FREQ_CONTROLE_BIOLOGICO > 0 and ciclo > 0 and
      ciclo % FREQ_CONTROLE_BIOLOGICO == 0) {
    nMosquitos += QUANT_MACHOS_ATIVOS_CONTROLE_BIOLOGICO;
    nMosquitos += QUANT_FEMEAS_ATIVAS_CONTROLE_BIOLOGICO;
  }
  return nMosquitos;
}

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.

  Realiza a inserção de mosquitos infectados com a bactéria Wolbachia
  para realizar o controle biológico.
*/
ControleBiologico::ControleBiologico(
  Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
  int ciclo, bool alocarMosquitos, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->conBio = ambiente->PconBioDev;
  this->nLotes = ambiente->PnLotesDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->indPos = ambiente->PindPosDev;
  this->pos = ambiente->PposDev;
  this->alocarMosquitos = alocarMosquitos;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe ControleBiologico.
*/
__host__ __device__
void ControleBiologico::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  if (not (alocarMosquitos and FREQ_CONTROLE_BIOLOGICO > 0
      and ciclo > 0 and ciclo % FREQ_CONTROLE_BIOLOGICO == 0)) return;

  int i, quadConBio, nMachos, nFemeas;

  // Quadra em que serao inseridos os mosquitos com Wolbachia
  quadConBio = conBio[id];

  nMachos = QUANT_MACHOS_ATIVOS_CONTROLE_BIOLOGICO;
  nFemeas = QUANT_FEMEAS_ATIVAS_CONTROLE_BIOLOGICO;

  i = id * (nMachos + nFemeas);

  inserirMosquitos(seed, dist, nMachos, MACHO, WOLBACHIA, ATIVA,
                    SUSCETIVEL, 0, quadConBio, i);
  inserirMosquitos(seed, dist, nFemeas, FEMEA, WOLBACHIA, ATIVA,
                    SUSCETIVEL, 0, quadConBio, i);
}

/*
  Método de inicialização de agentes mosquitos.
  São atribuídos valores padrão para os atributos necessários,
  além de valores determinados pelos parâmetros desta função.
*/
__host__ __device__
void ControleBiologico::inicializarMosquito(
  int id, int s, int sw, int fs, int ie, int sd,
  int st, int q, int l, int x, int y
) {
  SET_S_M(id, s);
  SET_SW_M(id, sw);
  SET_FS_M(id, fs);
  SET_IE_M(id, ie);
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
  Organiza e executa a inserção de uma determinada
  quantidade de mosquitos com os atributos especificados.
*/
__host__ __device__
void ControleBiologico::inserirMosquitos(
  dre& seed, urd<double>& dist, int quantidade, int s,
  int sw, int fs, int sd, int st, int q, int& i
) {
  int p, x, y, l, ie;

  for (int j = 0; j < quantidade; ++j) {
    l = ENTRE_FAIXA(0, nLotes[q], randPerc);

    p = (indPos[indQuadras[2 * q] + l + 1] -
          indPos[indQuadras[2 * q] + l]);
    p = ENTRE_FAIXA(0, p, randPerc);
    x = pos[indPos[indQuadras[q * 2] + l] + p].x;
    y = pos[indPos[indQuadras[q * 2] + l] + p].y;
    ie = IDADE_MOSQUITOS_ATIVOS(s, sw);
    inicializarMosquito(i, s, sw, fs, ie, sd, st, q, l, x, y);
    i += 1;
  }
}

/*
  Este operador é paralelizado para cada LOCALIDADE do ambiente.

  Aplica o efeito de tratamento ambiental sobre as localidades
  previstas na configuração de entrada da simulação.
*/
TratamentoAmbiental::TratamentoAmbiental(
  Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
  int ciclo, int sizeConAmb, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->sizeConAmb = sizeConAmb;
  this->conAmb = ambiente->PconAmbDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe TratamentoAmbiental.
*/
__host__ __device__
void TratamentoAmbiental::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  if (not (FREQ_TRATAMENTO_AMBIENTAL > 0 and ciclo > 0 and
      ciclo % FREQ_TRATAMENTO_AMBIENTAL == 0)) return;

  // Quadra em que sera aplicado o tratamento ambiental
  int quadConAmb = conAmb[id];

  int fs_m, ti_m, vd_m;

  for (int idM = indMosquitos[quadConAmb];
      idM < indMosquitos[quadConAmb + 1]; ++idM) {
    fs_m = GET_FS_M(idM), ti_m = GET_TI_M(idM), vd_m = GET_VD_M(idM);

    if (vd_m == MORTO or (fs_m != ATIVA and fs_m != DECADENTE) or
        ti_m != SEM_INFLUENCIA) continue;

    if (randPerc <= FRACAO_TRATAMENTO_AMBIENTAL) {
      if (randPerc <= TAXA_TIPO_INFLUENCIA_TRATAMENTO_AMBIENTAL) {
        SET_TI_M(idM, PARADO);
      } else {
        SET_TI_M(idM, ESPANTADO);
      }
    }
  }
}
