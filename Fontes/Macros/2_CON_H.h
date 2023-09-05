#ifndef __2_CON_H__
#define __2_CON_H__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Humanos/2-CON.csv":

  TAXA_INFECCAO_MOSQUITO:             Parâmetro  "CON001".
  TAXA_SUCESSO_INFECCAO_MOSQUITO:     Parâmetro  "CON002".
  TAXA_INFECCAO_HUMANO_SUSCETIVEL:    Parâmetros "CON003" a "CON008".
  TAXA_INFECCAO_HUMANO_RECUPERADO:    Parâmetros "CON009" a "CON014".
  TAXA_SUCESSO_INFECCAO_HUMANO:       Parâmetro  "CON015".
  TAXA_REPASTO:                       Parâmetro  "CON016".
  K_COMP_HM:                          Parâmetro  "CON017".
  K_COMP_MH:                          Parâmetro  "CON018".
  REDUCAO_CONTATO_MH:                 Parâmetro  "CON019".
  REPASTOS_POR_POSTURA:               Parâmetro  "CON020".
*/

#define TAXA_INFECCAO_MOSQUITO \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 0], \
parametros[DESL_2_CON_H + 1], \
(randPerc)))

#define TAXA_INFECCAO_MOSQUITO_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_2_CON_H + 0], \
parametros->parametros[DESL_2_CON_H + 1], \
(per)))

#define TAXA_SUCESSO_INFECCAO_MOSQUITO \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 2], \
parametros[DESL_2_CON_H + 3], \
(randPerc)))

#define TAXA_INFECCAO_HUMANO_SUSCETIVEL(fe) \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 4 + fe * 2], \
parametros[DESL_2_CON_H + 5 + fe * 2], \
(randPerc)))

#define TAXA_INFECCAO_HUMANO_SUSCETIVEL_(fe, per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_2_CON_H + 4 + fe * 2], \
parametros->parametros[DESL_2_CON_H + 5 + fe * 2], \
(per)))

#define TAXA_INFECCAO_HUMANO_RECUPERADO(fe) \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 16 + fe * 2], \
parametros[DESL_2_CON_H + 17 + fe * 2], \
(randPerc)))

#define TAXA_SUCESSO_INFECCAO_HUMANO \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 28], \
parametros[DESL_2_CON_H + 29], \
(randPerc)))

#define TAXA_REPASTO \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 30], \
parametros[DESL_2_CON_H + 31], \
(randPerc)))

#define K_COMP_HM \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 32], \
parametros[DESL_2_CON_H + 33], \
(randPerc)))

#define K_COMP_MH \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 34], \
parametros[DESL_2_CON_H + 35], \
(randPerc)))

#define REDUCAO_CONTATO_MH \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 36], \
parametros[DESL_2_CON_H + 37], \
(randPerc)))

#define REPASTOS_POR_POSTURA \
(int)(ENTRE_FAIXA( \
parametros[DESL_2_CON_H + 38], \
parametros[DESL_2_CON_H + 39], \
randPerc))

#endif
