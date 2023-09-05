#include "Insercao.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Macros/5_INS_H.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.

  Responsável por determinar a quantidade de agentes humanos
  que serão inseridos no ambiente durante o ciclo atual da simulação.

  O valor obtido é utilizado antes da execução do operador "InsercaoHumanos"
  na rotina de redimensionamento do vetor de agentes humanos. 
*/
PreInsercaoHumanos::PreInsercaoHumanos(
  Parametros *parametros, int ciclo, Ambiente *ambiente
) {
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->sizeDistHumanos = ambiente->sizeDistHumanos;
  this->distHumanos = ambiente->PdistHumanosDev;
}

/*
  Operador () da classe PreInsercaoHumanos.
*/
__host__ __device__
int PreInsercaoHumanos::operator()(int id) {
  int nHumanos = 0;

  // Inserções parametrizadas no arquivo "../Humanos/5-INS.csv".
  if (ciclo == CICLO_ENTRADA_HUMANOS_S) nHumanos += QUANTIDADE_HUMANOS_S;
  if (ciclo == CICLO_ENTRADA_HUMANOS_I1) nHumanos += QUANTIDADE_HUMANOS_I1;
  if (ciclo == CICLO_ENTRADA_HUMANOS_I2) nHumanos += QUANTIDADE_HUMANOS_I2;
  if (ciclo == CICLO_ENTRADA_HUMANOS_I3) nHumanos += QUANTIDADE_HUMANOS_I3;
  if (ciclo == CICLO_ENTRADA_HUMANOS_I4) nHumanos += QUANTIDADE_HUMANOS_I4;

  // Inserções listadas no arquivo "../Ambiente/DistribuicaoHumanos.csv".
  for (int i = 0; i < sizeDistHumanos; i++) {
    if (distHumanos[i].cic == ciclo) nHumanos++;
  }

  return nHumanos;
}

/*
  Este operador não é paralelizado, sendo executado apenas uma vez por ciclo.
  
  Responsável pela inserção de agentes humanos no ambiente durante a
  simulação, de acordo com os arquivos de parametrização.
*/
InsercaoHumanos::InsercaoHumanos(
  Humanos *humanos, Ambiente *ambiente, Parametros *parametros,
  int ciclo, Seeds *seeds
) {
  this->humanos = humanos->PhumanosDev;
  this->indTrajFE = ambiente->PindTrajFEDev;
  this->indTraj = ambiente->PindTrajDev;
  this->indRotas = ambiente->PindRotasDev;
  this->rotas = ambiente->ProtasDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->indPos = ambiente->PindPosDev;
  this->pos = ambiente->PposDev;
  this->parametros = parametros->PparametrosDev;
  this->ciclo = ciclo;
  this->sizeDistHumanos = ambiente->sizeDistHumanos;
  this->distHumanos = ambiente->PdistHumanosDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe InsercaoHumanos.
*/
__host__ __device__
void InsercaoHumanos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);
  int i = 0;

  // Inserções parametrizadas no arquivo "../Humanos/5-INS.csv".
  if (ciclo == CICLO_ENTRADA_HUMANOS_S)
  inserirHumanosTrajeto(seed, dist, QUANTIDADE_HUMANOS_S, 0, i);
  if (ciclo == CICLO_ENTRADA_HUMANOS_I1)
  inserirHumanosTrajeto(seed, dist, QUANTIDADE_HUMANOS_I1, SOROTIPO_1, i);
  if (ciclo == CICLO_ENTRADA_HUMANOS_I2)
  inserirHumanosTrajeto(seed, dist, QUANTIDADE_HUMANOS_I2, SOROTIPO_2, i);
  if (ciclo == CICLO_ENTRADA_HUMANOS_I3)
  inserirHumanosTrajeto(seed, dist, QUANTIDADE_HUMANOS_I3, SOROTIPO_3, i);
  if (ciclo == CICLO_ENTRADA_HUMANOS_I4)
  inserirHumanosTrajeto(seed, dist, QUANTIDADE_HUMANOS_I4, SOROTIPO_4, i);

  // Inserções listadas no arquivo "../Ambiente/DistribuicaoHumanos.csv".
  inserirHumanosAleatorio(i);
}

/*
  Este método insere uma determinada quantidade de agentes humanos de acordo
  com os parâmetros do arquivo "Humanos/5-INS.csv". Os agentes inseridos são
  do sexo masculino, adultos, com movimentação do tipo trajeto.
*/
__host__ __device__
void InsercaoHumanos::inserirHumanosTrajeto(
  dre& seed, urd<double>& dist, int qtde, int st, int& i
) {
  int p, x, y, l, q, t, pInicial, pFinal;
  int s = MASCULINO, fe = ADULTO, k = TRAJETO;
  int sd = (st == 0) ? SUSCETIVEL : INFECTANTE;

  for (int j = 0; j < qtde; ++j) {
    // Escolha de um trajeto para o agente.
    t = ENTRE_FAIXA(indTrajFE[fe], indTrajFE[fe + 1], randPerc);

    // Obtenção da quadra e lote inicial do agente.
    l = rotas[indRotas[indTraj[t]] + 0];
    q = rotas[indRotas[indTraj[t]] + 1];

    // Escolha aleatória de uma posição para o agente.
    pInicial = indPos[indQuadras[2 * q] + l];
    pFinal = indPos[indQuadras[2 * q] + l + 1];
    p = ENTRE_FAIXA(0, (pFinal - pInicial), randPerc);
    x = pos[pInicial + p].x;
    y = pos[pInicial + p].y;

    // Inicialização do novo agente.
    inicializarHumano(i, sd, x, y, l, q, s, fe, t, k, st);
    i++;
  }
}

/*
  Este método insere uma determinada quantidade de agentes humanos de acordo
  com a lista do arquivo "../Ambiente/DistribuicaoHumanos.csv". Os
  agentes inseridos possuem movimentação do tipo aleatória.

  Os agentes inseridos por este método entram na simulação no estado
  infectante, de modo a modelar a introdução do vírus por fontes externas.
*/
void InsercaoHumanos::inserirHumanosAleatorio(int& i) {
  int sd, x, y, l, q, s, fe, t, k, st;
  for (int j = 0; j < sizeDistHumanos; ++j) {
    // Filtra entradas deste ciclo
    if (distHumanos[j].cic != ciclo) continue;

    // Determinação dos atributos do agente de acordo com a entrada do arquivo
    q = distHumanos[j].q;
    l = distHumanos[j].l;
    x = distHumanos[j].x;
    y = distHumanos[j].y;
    s = distHumanos[j].s;
    fe = distHumanos[j].fe;
    sd = distHumanos[j].sd;
    st = distHumanos[j].st;
    k = ALEATORIO;
    t = 0;

    // Ininialização do novo agente
    inicializarHumano(i, sd, x, y, l, q, s, fe, t, k, st);
    i++;
  }
}

/*
  Método de inicialização de agentes humanos.
  São atribuídos valores padrão para os atributos necessários,
  além de valores determinados pelos parâmetros desta função.
*/
__host__ __device__
void InsercaoHumanos::inicializarHumano(
  int id, int sd, int x, int y, int l, int q,
  int s, int fe, int t, int k, int st
) {
  // Determina os sorotipos contraídos
  int sc = (st == 0) ? 0 : 1 << (st - 1);

  // Atributos das variáveis bitstring
  SET_R_H(id, 0);
  SET_T_H(id, t);
  SET_F_H(id, 1);
  SET_M_H(id, 0);
  SET_K_H(id, k);

  SET_CR_H(id, 0);
  SET_S_H(id, s);
  SET_FE_H(id, fe);
  SET_SD_H(id, sd);
  SET_ST_H(id, st);
  SET_SC_H(id, sc);
  SET_A_H(id, 0);
  SET_C_H(id, 0);
  SET_CV_H(id, 0);

  SET_X_H(id, x);
  SET_L_H(id, l);

  SET_Y_H(id, y);
  SET_Q_H(id, q);

  // Identificador aleatório
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);
  SET_ID_H(id, ENTRE_FAIXA(0, MAX_UINT32, randPerc));
}
