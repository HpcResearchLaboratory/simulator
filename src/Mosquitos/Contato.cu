#include "Contato.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Macros/2_CON_M.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador é paralelizado para cada POSIÇÃO do ambiente. 

  Este método é responsável pela aplicação do operador de contato entre agentes
  mosquitos, que representa o acasalamento entre os agentes machos e fêmeas.

  Inicialmente, são filtradas todas as fêmeas na fase alada que ainda não
  acasalaram.

  Para cada fêmea, determina-se o melhor candidato para reprodução que se
  encontra na mesma posição da fêmea, por meio da função getMacho(). Caso
  nenhum macho seja encontrado, a fêmea em questão não acasala.

  Finalmente, determina-se as características da prole de acordo com os
  atributos da fêmea e do macho, considerando a infecção por Wolbachia.
*/
ContatoMosquitos::ContatoMosquitos(
  Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
  int periodo, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->pos = ambiente->PposDev;
  this->periodo = periodo;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe ContatoMosquitos.
*/
__host__ __device__
void ContatoMosquitos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  int x = pos[id].x, y = pos[id].y;
  int l = pos[id].lote, q = pos[id].quadra;

  // Índices correspondentes à quadra atual para o vetor de mosquitos
  int indInicial = indMosquitos[q];
  int indFinal = indMosquitos[q + 1];

  // Percorre todos os mosquitos que estão nesta posição, filtrando fêmeas na
  // fase alada e ainda não acasaladas
  for (int idFemea = indInicial; idFemea < indFinal; ++idFemea) {

    // Acesso aos atributos do mosquito fêmea
    int q_f  = GET_Q_M(idFemea);
    int l_f = GET_L_M(idFemea);
    int x_f  = GET_X_M(idFemea);
    int y_f = GET_Y_M(idFemea);
    int sw_f = GET_SW_M(idFemea);
    int s_f = GET_S_M(idFemea);
    int vd_f = GET_VD_M(idFemea);
    int fs_f = GET_FS_M(idFemea);
    int ta_f = GET_TA_M(idFemea);

    // Ignora agentes fora desta posição
    if (l_f != l or x_f != x or y_f != y) continue;

    // Ignora agentes mortos ou machos
    if (vd_f == MORTO or s_f != FEMEA) continue;

    // Ignora ovos, larvas e pupas
    if (fs_f != ATIVA and fs_f != DECADENTE) continue;

    // Ignora fêmeas acasaladas
    if (ta_f != NENHUM) continue;

    // A fêmea procura um macho para acasalamento. 
    int idMacho = getMacho(x_f, y_f, l_f, q_f);
    if (idMacho == -1) continue;

    // Acesso aos atributos do mosquito macho
    int c_m = GET_C_M(idMacho);
    int sw_m = GET_SW_M(idMacho);

    int tipoAcasal, tipoProle;
    double fatorPref, probAcasal;

    // Tipo de acasalamento, prole, fator de preferência e probabilidade de
    // acasalamento são definidos de acordo com os estados da fêmea e do macho
    switch (sw_m) {
      case SAUDAVEL: {
        switch (sw_f) {
          case SAUDAVEL: { // Fêmea e macho saudáveis
            tipoAcasal = ACA_SAUDAVEL;
            tipoProle = SAUDAVEL;
            fatorPref = pow(K1, c_m);
            probAcasal = (c_m == 0) ? BETASS22 : BETASS23;
          } break;
          case WOLBACHIA: { // Fêmea infectada com Wolbachia e macho saudável
            tipoAcasal = ACA_SAUDAVEL;
            tipoProle = WOLBACHIA;
            fatorPref = pow(K1, c_m);
            probAcasal = (c_m == 0) ? BETAIS22 : BETAIS23;
          } break;
        }
      } break;
      case WOLBACHIA: {
        switch (sw_f) {
          case SAUDAVEL: { // Fêmea saudável e macho infectado com Wolbachia
            tipoAcasal = ACA_INFECTADO;
            tipoProle = ESTERIL;
            fatorPref = pow(K2, c_m);
            probAcasal = (c_m == 0) ? BETASI22 : BETASI23;
          } break;
          case WOLBACHIA: { // Fêmea e macho infectados com Wolbachia
            tipoAcasal = ACA_INFECTADO;
            tipoProle = WOLBACHIA;
            fatorPref = pow(K2, c_m);
            probAcasal = (c_m == 0) ? BETAII22 : BETAII23;
          } break;
        }
      } break;
    }

    double taxaSucesso = (fatorPref * probAcasal * TAXA_FECUNDIDADE_FEMEA);

    // Aplica a redução de atividade noturna
    if (periodo == NOITE) taxaSucesso *= REDUCAO_CONTATO_M;

    if (randPerc <= taxaSucesso) {
      // Altera o tipo de acasalamento e prole da fêmea
      SET_TA_M(idFemea, tipoAcasal);
      SET_PR_M(idFemea, tipoProle);

      // Zera os contadores de latência e de posturas da fêmea
      SET_C_M(idFemea, 0);
      SET_CP_M(idFemea, 0);

      // Incrementa o contador de acasalamentos do macho
      SET_C_M(idMacho, c_m + 1);
    }
  }
}

/*
  Este método encontra o melhor candidato para reprodução na posição designada.
  Para isso, retorna o id do mosquito macho com o menor número de acasalamentos
  que for encontrado. Caso não exista nenhum agente compatível, retorna -1.
*/
__host__ __device__
int ContatoMosquitos::getMacho(int x, int y, int l, int q) {
  int id = -1;
  int nAcasal = INT_MAX;

  // Índices correspondentes à quadra atual para o vetor de mosquitos
  int indInicial = indMosquitos[q];
  int indFinal = indMosquitos[q + 1];

  for (int idMacho = indInicial; idMacho < indFinal; ++idMacho) {
    // Acesso aos atributos do agente
    int l_m = GET_L_M(idMacho);
    int x_m  = GET_X_M(idMacho);
    int y_m = GET_Y_M(idMacho);
    int s_m  = GET_S_M(idMacho);
    int c_m = GET_C_M(idMacho);
    int vd_m = GET_VD_M(idMacho);
    int fs_m = GET_FS_M(idMacho);

    // Ignora agentes fora desta posição
    if (l_m != l or x_m != x or y_m != y) continue;

    // Ignora agentes mortos ou fêmeas
    if (vd_m == MORTO or s_m != MACHO) continue;

    // Ignora ovos, larvas e pupas
    if (fs_m != ATIVA and fs_m != DECADENTE) continue;

    if (c_m < nAcasal) {
      id = idMacho;
      nAcasal = c_m;
    }
  }
  return id;
}
