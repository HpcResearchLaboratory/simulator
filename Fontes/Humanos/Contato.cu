#include "Contato.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Macros/0_INI_H.h"
#include "Fontes/Macros/2_CON_H.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador é paralelizado para cada POSIÇÃO do ambiente.

  Inicialmente percorre os vetores de agentes, a procura de humanos e
  mosquitos na mesma posição. Caso o mosquito seja fêmea, acasalada e
  não alimentada, existe a probabilidade de ocorrência de repasto
  sanguíneo, controlada por TAXA_REPASTO.

  Caso o repasto aconteça, o contador de repastos da fêmea é
  incrementado. Se o valor atingir o número necessário que é definido
  pelo parâmetro REPASTOS_POR_POSTURA, a fêmea é marcada como
  alimentada.

  Caso os estados internos dos agentes configurem uma das condições
  de possível transmissão, a respectiva taxa de infecção é aplicada
  e, em caso positivo, alteram-se os estados dos agentes.
*/
ContatoHumanos::ContatoHumanos(
  Mosquitos *mosquitos, Humanos *humanos, Ambiente *ambiente,
  Parametros *parametros, int ciclo, int periodo, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->humanos = humanos->PhumanosDev;
  this->indHumanos = humanos->PindHumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->pos = ambiente->PposDev;
  this->comp = ambiente->PcompDev;
  this->periodo = periodo;
  this->ciclo = ciclo;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe ContatoHumanos.
*/
__host__ __device__
void ContatoHumanos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  int x = pos[id].x, y = pos[id].y;
  int l = pos[id].lote, q = pos[id].quadra;

  // Índices correspondentes à quadra atual para os vetores de agentes
  int indInicialM = indMosquitos[q];
  int indFinalM = indMosquitos[q + 1];
  int indInicialH = indHumanos[q];
  int indFinalH = indHumanos[q + 1];

  // Percorre todos os mosquitos que estão nesta posição, filtrando apenas
  // fêmeas na fase alada, acasaladas e não alimentadas
  for (int idMosquito = indInicialM; idMosquito < indFinalM; ++idMosquito) {

    // Ignora agentes fora desta posição
    int l_m  = GET_L_M(idMosquito);
    int x_m  = GET_X_M(idMosquito);
    int y_m  = GET_Y_M(idMosquito);
    if (l_m != l or x_m != x or y_m != y) continue;
  
    // Ignora agentes mortos ou machos
    int s_m  = GET_S_M(idMosquito);
    int vd_m = GET_VD_M(idMosquito);
    if (vd_m == MORTO or s_m != FEMEA) continue;

    // Ignora ovos, larvas e pupas
    int fs_m = GET_FS_M(idMosquito);
    if (fs_m != ATIVA and fs_m != DECADENTE) continue;

    // Ignora fêmeas não acasaladas ou já alimentadas
    int ta_m = GET_TA_M(idMosquito);
    int am_m = GET_AM_M(idMosquito);
    if (ta_m == NENHUM or am_m == ALIMENTADO) continue;

    // Percorre todos os humanos que estão nesta posição
    for (int idHumano = indInicialH; idHumano < indFinalH; ++idHumano) {

      // Ignora agentes mortos ou fora desta posição
      int l_h = GET_L_H(idHumano);
      int x_h = GET_X_H(idHumano);
      int y_h = GET_Y_H(idHumano);
      int sd_h = GET_SD_H(idHumano);
      if (l_h != l or x_h != x or y_h != y or sd_h == MORTO) continue;

      // Aplica a redução de atividade noturna
      double chanceRepasto = TAXA_REPASTO;
      if (periodo == NOITE) chanceRepasto *= REDUCAO_CONTATO_MH;
      
      // Ao encontrar um mosquito e um humano na mesma posição, ocorre uma
      // tentativa de repasto
      if (randPerc <= chanceRepasto) {

        // Incrementa a quantidade de repastos da fêmea do mosquito e
        // a marca como alimentada caso alcance a quantidade necessária
        int nRepastosM = GET_CR_M(idMosquito);
        if (nRepastosM + 1 >= REPASTOS_POR_POSTURA) {
          SET_CR_M(idMosquito, 0);
          SET_AM_M(idMosquito, ALIMENTADO);
        } else {
          SET_CR_M(idMosquito, nRepastosM + 1);
        }

        // Incrementa o contador de repastos do humano
        int nRepastos = (GET_CR_H(idHumano) + 1) % (1 << TH_CR);
        SET_CR_H(idHumano, nRepastos);

        // Acesso ao estado relativo à dengue do agente mosquito
        int sd_m = GET_SD_M(idMosquito);

        // Infecção (mosquito infectante / humano suscetível)
        if (sd_m == INFECTANTE and sd_h == SUSCETIVEL)
          infeccaoHumano(idMosquito, idHumano, dist, seed);

        // Infecção (mosquito suscetível / humano infectante)
        if (sd_h == INFECTANTE and sd_m == SUSCETIVEL)
          infeccaoMosquito(idMosquito, idHumano, dist, seed);

        break; // Cada mosquito faz no máximo um repasto
               // a cada execução do operador
      }
    }
  }
}

/*
  Método responsável pela infecção probabilística de agentes humanos. Ocorre
  quando um mosquito infectante entra em contato com um humano suscetível.

  Se o humano é infectado ele é passado ao estado exposto, seu sorotipo muda
  para o sorotipo do vírus carregado pelo mosquito e seu contador de latência
  (C) é iniciado em zero.
*/
__host__ __device__
void ContatoHumanos::infeccaoHumano(
  int idMosquito, int idHumano, urd<double> dist, dre& seed
) {

  // Retorna caso os estados dos agentes não sejam compatíveis com o cenário
  int sd_m = GET_SD_M(idMosquito);
  int sd_h = GET_SD_H(idHumano);
  if (sd_m != INFECTANTE or sd_h != SUSCETIVEL) return;

  // Humanos nunca contraem Dengue do mesmo sorotipo duas vezes
  int st_m = GET_ST_M(idMosquito); // Sorotipo carregado pelo mosquito
  int sc_h = GET_SC_H(idHumano); // Sorotipos já contraídos pelo humano
  if (contraiuEsteSorotipo(sc_h, st_m)) return;

  // Calcula a taxa de infecção
  double taxaInfeccao = TAXA_SUCESSO_INFECCAO_HUMANO * K_COMP_MH;

  // A taxa é diferente para humanos que já contraíram Dengue anteriormente
  int fe_h = GET_FE_H(idHumano); // Faixa etária do humano
  if (sc_h == 0) {
    taxaInfeccao *= TAXA_INFECCAO_HUMANO_SUSCETIVEL(fe_h);
  } else {
    taxaInfeccao *= TAXA_INFECCAO_HUMANO_RECUPERADO(fe_h);
  }

  if (randPerc <= taxaInfeccao) {
    // Em caso positivo executa as alterações nos atributos dos agentes
    SET_SD_H(idHumano, EXPOSTO);
    SET_ST_H(idHumano, st_m); // Marca o sorotipo do humano
    SET_SC_H(idHumano, sc_h + (1 << (st_m - 1))); // Adiciona aos sorotipos contraídos
    SET_C_H(idHumano, 0); // Inicializa o contador de latência

    // Aplica uma taxa de probabilidade de ocorrência assintomática
    if (randPerc <= PROBABILIDADE_HUMANO_ASSINTOMATICO) SET_A_H(idHumano, 1);
  }
}

/*
  Método responsável pela infecção probabilística de agentes mosquitos. Ocorre
  quando um mosquito suscetível entra em contato com um humano infectante.

  Se o mosquito é infectado ele é passado ao estado exposto, seu sorotipo muda
  para o sorotipo do vírus carregado pelo humano e seu contador de latência (C)
  é iniciado em zero.
*/
__host__ __device__
void ContatoHumanos::infeccaoMosquito(
  int idMosquito, int idHumano, urd<double> dist, dre& seed
) {

  // Retorna caso os estados dos agentes não sejam compatíveis com o cenário
  int sd_m = GET_SD_M(idMosquito);
  int sd_h = GET_SD_H(idHumano);
  if (sd_m != SUSCETIVEL or sd_h != INFECTANTE) return;

  // Mosquitos com Wolbachia não contraem a Dengue
  int sw_m = GET_SW_M(idMosquito);
  if (sw_m != SAUDAVEL) return;

  // Calcula a taxa de infecção
  double chanceInfeccao = TAXA_SUCESSO_INFECCAO_MOSQUITO * K_COMP_HM;
  chanceInfeccao *= TAXA_INFECCAO_MOSQUITO;
  chanceInfeccao *= comp[ciclo];

  if (randPerc <= chanceInfeccao) {
    // Em caso positivo executa as alterações nos atributos dos agentes
    int st_h = GET_ST_H(idHumano); // Sorotipo do vírus no humano
    SET_SD_M(idMosquito, EXPOSTO);
    SET_ST_M(idMosquito, st_h); // Marca o sorotipo do mosquito
    SET_C_M(idMosquito, 0); // Inicializa o contador de latência
  }
}

/*
  Verifica se o humano já contraiu determinado sorotipo anteriormente.
*/
__host__ __device__
bool ContatoHumanos::contraiuEsteSorotipo(int sc_h, int st_m) {
  return ((sc_h & (1 << (st_m - 1))) > 0);
}
