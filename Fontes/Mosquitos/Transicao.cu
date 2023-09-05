#include "Transicao.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Macros/3_TRA_M.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador é paralelizado para cada AGENTE.

  Executa a transição de fase dos mosquitos, tanto na fase aquática
  (ovos, larvas e pupas) quanto dos agentes na fase ativa, que transitam para a
  fase decadente.
  
  É aplicada uma taxa de sobrevivência definida pelos parâmetros TRA012 a
  TRA027, que varia de acordo com os seguintes atributos:
    - Fase (FS)
    - Sexo (S)
    - Saúde Wolbachia (SW)

  São ignorados os mosquitos cuja idade seja inferior ao limite máximo de idade
  de sua respectiva fase, determinado pelos parâmetros TRA001 a TRA007. Para a
  fase ativa esse valor depende de S e SW.
*/
TransicaoFasesMosquitos::TransicaoFasesMosquitos(
  Ambiente *ambiente, Mosquitos *mosquitos,
  Parametros *parametros, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->seeds = seeds->PseedsDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->pos = ambiente->PposDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->indFocos = ambiente->PindFocosDev;
  this->focos = ambiente->PfocosDev;
  this->capFocos = ambiente->PcapFocosDev;
}

/*
  Operador () da classe TransicaoFasesMosquitos.
*/
__host__ __device__
void TransicaoFasesMosquitos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  int x = pos[id].x;
  int y = pos[id].y;
  int l = pos[id].lote;
  int q = pos[id].quadra;
  int idFoco = getIdFoco(x, y, q, l);

  for (int i = indMosquitos[q]; i < indMosquitos[q + 1]; i++) {
    int idMosquito = i;

    // Filtra mosquitos na posição desejada
    if (GET_Q_M(idMosquito) != q) continue;
    if (GET_L_M(idMosquito) != l) continue;
    if (GET_X_M(idMosquito) != x) continue;
    if (GET_Y_M(idMosquito) != y) continue;

    int vd = GET_VD_M(idMosquito);
    int s = GET_S_M(idMosquito);
    int sw = GET_SW_M(idMosquito);
    int ie = GET_IE_M(idMosquito);
    int fs = GET_FS_M(idMosquito);

    if (vd == MORTO or fs >= DECADENTE) continue;

    // Ignora agentes que ainda não atingiram a idade necessária
    if (fs == ATIVA) {
      if (ie < IDADE_MAX_MOSQUITOS_ATIVOS(s, sw)) continue;
    } else {
      if (ie < IDADE_MAX_MOSQUITOS_NAO_ALADOS(fs)) continue;
    }

    // Aplica a taxa de sobrevivência correspondente
    double taxaSobrevivencia = TAXA_SOBREVIVENCIA(fs, s, sw);
    if (randPerc <= taxaSobrevivencia) {
      SET_FS_M(idMosquito, fs + 1);
      if (fs == PUPA and idFoco != -1) { // Transição pupa -> ativa
        capFocos[idFoco]--;
      }
    } else {
      SET_VD_M(idMosquito, MORTO);
      if (fs < ATIVA and idFoco != -1) { // Ovos, larvas e pupas removidos
        capFocos[idFoco]--;
      }
    }
  }
}

/*
  Retorna o índice que a posição atual de um mosquito na fase aquática
  assume no vetor de focos.
*/
__host__ __device__
int TransicaoFasesMosquitos::getIdFoco(int x, int y, int q, int l) {
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
  Este operador é paralelizado para cada AGENTE.

  Responsável por contabilizar os ciclos de latência da fêmea do
  mosquito, alterando seu estado de EXPOSTO para INFECTANTE após certo período
  de tempo.

  Também incrementa o atributo IE, que armazena a idade dos agentes.
*/
TransicaoEstadosMosquitos::TransicaoEstadosMosquitos(
  Mosquitos *mosquitos,  Parametros *parametros, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->parametros = parametros->PparametrosDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe TransicaoEstadosMosquitos.
*/
__host__ __device__
void TransicaoEstadosMosquitos::operator()(int id) {
  int idMosquito = id;
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  // Filtra os agentes vivos
  if (GET_VD_M(idMosquito) == MORTO) return;

  // Incrementa a idade de todos os agentes
  SET_IE_M(idMosquito, (GET_IE_M(idMosquito) + 1) & 255);

  // Filtra apenas mosquitos fêmeas
  if (GET_S_M(idMosquito) == MACHO) return;

  int sd = GET_SD_M(idMosquito);
  int c  = GET_C_M(idMosquito);
  
  if (sd == EXPOSTO) {
    if (c >= CICLOS_LATENCIA_MOSQUITOS) {
      SET_SD_M(idMosquito, INFECTANTE);
      SET_C_M(idMosquito, 0); // Atribui o valor 0 para contabilizar
    } else {
      SET_C_M(idMosquito, c + 1);
    }
  }

  // Impede que o mosquito seja contabilizado duas vezes como infectado
  if (sd == INFECTANTE and c == 0) {
    SET_C_M(idMosquito, 1);
  }
}
