#include "Insercao.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Macros/0_INI_M.h"
#include "Fontes/Macros/3_TRA_M.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.
  
  Responsável pela estimativa da quantidade de mosquitos que
  serão inseridos no ambiente, conforme os dados de entrada do arquivo
  "Entradas/MonteCarlo_{i}/Ambiente/DistribuicaoMosquitos.csv".
*/

PreInsercaoMosquitos::PreInsercaoMosquitos(int ciclo, Ambiente *ambiente) {
  this->ciclo = ciclo;
  this->sizeDistMosquitos = ambiente->sizeDistMosquitos;
  this->distMosquitos = ambiente->PdistMosquitosDev;
}

/*
  Operador () da classe PreInsercaoMosquitos.
*/
__host__ __device__
int PreInsercaoMosquitos::operator()(int id) {
  int nMosquitos = 0;
  for (int i = 0; i < sizeDistMosquitos; i++) {
    if (distMosquitos[i].cic == ciclo) {
      nMosquitos += distMosquitos[i].quant;
    }
  }
  return nMosquitos;
}

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.

  Responsável pela inserção de agentes mosquitos no ambiente durante a 
  simulação e inicialização de seus atributos.

  Para determinar esses atributos, utilizam-se os dados presentes no arquivo
  "Entradas/MonteCarlo_{i}/Ambiente/DistribuicaoMosquitos.csv".

  Cada entrada insere uma certa quantidade de agentes, representada pelo
  parâmetro "quant". Os sexo dos mosquitos é determinado pelo parâmetro "s" e
  a fase por "fs".

  O parâmetro "PROBABILIDADE_DISTRIBUICAO_MOSQUITOS" representa a probabilidade
  do novo agente ser inserido em um dos Pontos Estratégicos do ambiente. Caso
  contrário, o mosquito será inserido em uma posição aleatória da quadra "q"
  indicada no arquivo de distribuição.

  Cada mosquito inserido tem uma probabilidade de estar infectado, regulada
  pelo intervalo probabiístico entre os parâmetros "pmin" e "pmax". Quando
  infectados, os mosquitos portarão o sorotipo "st".
*/
InsercaoMosquitos::InsercaoMosquitos(
  Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
  int ciclo, int sizePontEst, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->ciclo = ciclo;
  this->sizeDistMosquitos = ambiente->sizeDistMosquitos;
  this->distMosquitos = ambiente->PdistMosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->nLotes = ambiente->PnLotesDev;
  this->indPos = ambiente->PindPosDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->pos = ambiente->PposDev;
  this->sizePontEst = sizePontEst;
  this->pontEst = ambiente->PpontEstDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe InsercaoMosquitos.
*/
__host__ __device__
void InsercaoMosquitos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  // Este contador indica a posição do vetor correspondente ao novo mosquito.
  // As operações de resize após a rotina de pré-inserção concentram no início
  // do vetor o espaço para novos agentes.
  int i = 0;

  for (int j = 0; j < sizeDistMosquitos; j++) {

    // Filtra apenas entradas para este ciclo
    if (distMosquitos[j].cic != ciclo) continue;

    // Resgate dos dados de entrada
    int q = distMosquitos[j].q;
    int s = distMosquitos[j].s;
    int fs = distMosquitos[j].fs; 
    int st = distMosquitos[j].st; 
    int quant = distMosquitos[j].quant;
    double pmin = distMosquitos[j].pmin;
    double pmax = distMosquitos[j].pmax; 

    for (int k = 0; k < quant; k++) {

      // Quadra e lote onde o mosquito será inserido
      int qIns, lIns;

      if (sizePontEst > 0
          and randPerc <= PROBABILIDADE_DISTRIBUICAO_MOSQUITOS) {
        // Caso existam PEs, há uma chance do mosquito ser inserido em PE
        int pe = ENTRE_FAIXA(0, sizePontEst / 2, randPerc);
        qIns = pontEst[2 * pe + 0];
        lIns = pontEst[2 * pe + 1];
      } else {
        // Caso contrário insere o mosquito em um lote aleatório da quadra 
        qIns = q;
        lIns = ENTRE_FAIXA(0, nLotes[qIns], randPerc);
      }

      // Determina uma posição aleatória no lote para inserção
      int pInicial = indPos[indQuadras[2 * qIns] + lIns];
      int pFinal = indPos[indQuadras[2 * qIns] + lIns + 1];
      int p = ENTRE_FAIXA(pInicial, pFinal, randPerc);
      int x = pos[p].x;
      int y = pos[p].y;
      
      int sw = SAUDAVEL;
      int sd = SUSCETIVEL;
      
      // Alguns agentes inseridos serão infectados com Dengue, de acordo 
      // com as probabilidades definidas no arquivo de entrada
      if (randPerc <= ENTRE_FAIXA(pmin, pmax, randPerc)) {
        sd = INFECTANTE;
      }

      // Escolha da idade do agente de acordo com a fase
      int ie = 0;
      switch (fs) {
        case OVO: ie = IDADE_MOSQUITOS_NAO_ALADOS(fs);
          break;
        case ATIVA: ie = IDADE_MOSQUITOS_ATIVOS(s, sw);
          break;
        case DECADENTE: ie = IDADE_MOSQUITOS_DECADENTES(s, sw);
          break;
      }

      // Inicialização do novo agente
      inicializarMosquito(i++, s, sw, fs, ie, sd, st, qIns, lIns, x, y);
    }
  }
}

/*
  Este método inicializa os novos mosquitos inseridos no ambiente.

  Alguns de seus atributos são inicializados com valores vazios (0), enquanto
  outros são determinados pelos argumentos do método. Ao final, um
  identificador é sorteado para o novo agente.
*/
__host__ __device__
void InsercaoMosquitos::inicializarMosquito(
  int id, int s, int sw, int fs, int ie, int sd, int st, int q,
  int l, int x, int y
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
