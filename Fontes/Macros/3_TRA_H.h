#ifndef __3_TRA_H__
#define __3_TRA_H__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Humanos/3-TRA.csv":

  PERIODO_EXPOSTO_HUMANO:               Parâmetros "TRA001" a "TRA006".
  PERIODO_INFECTADO_HUMANO:             Parâmetros "TRA007" a "TRA012".
  PERIODO_HEMORRAGICO_HUMANO:           Parâmetros "TRA013" a "TRA018".
  PERIODO_RECUPERADO_HUMANO:            Parâmetros "TRA019" a "TRA024".
  TAXA_EVOLUCAO_DENGUE_HEMORRAGICA:     Parâmetros "TRA025" a "TRA028".
  TAXA_MORTE_DENGUE:                    Parâmetro  "TRA029".
  TAXA_EFICACIA_VACINA:                 Parâmetro  "TRA030".
*/

#define PERIODO_EXPOSTO_HUMANO(ie) \
(int) (ENTRE_FAIXA( \
parametros[DESL_3_TRA_H + 0 + ie * 2], \
parametros[DESL_3_TRA_H + 1 + ie * 2], \
(randPerc)))

#define PERIODO_EXPOSTO_HUMANO_(ie, per) \
(int) (ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_H + 0 + ie * 2], \
parametros->parametros[DESL_3_TRA_H + 1 + ie * 2], \
(per)))

#define PERIODO_INFECTADO_HUMANO(ie) \
(int) (ENTRE_FAIXA( \
parametros[DESL_3_TRA_H + 12 + ie * 2], \
parametros[DESL_3_TRA_H + 13 + ie * 2], \
(randPerc)))

#define PERIODO_HEMORRAGICO_HUMANO(ie) \
(int) (ENTRE_FAIXA( \
parametros[DESL_3_TRA_H + 24 + ie * 2], \
parametros[DESL_3_TRA_H + 25 + ie * 2], \
(randPerc)))

#define PERIODO_RECUPERADO_HUMANO(ie) \
(int) (ENTRE_FAIXA( \
parametros[DESL_3_TRA_H + 36 + ie * 2], \
parametros[DESL_3_TRA_H + 37 + ie * 2], \
(randPerc)))

#define PERIODO_RECUPERADO_HUMANO_(ie, per) \
(int) (ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_H + 36 + ie * 2], \
parametros->parametros[DESL_3_TRA_H + 37 + ie * 2], \
(per)))

#define TAXA_EVOLUCAO_DENGUE_HEMORRAGICA(nSoro) \
(double) (ENTRE_FAIXA( \
parametros[DESL_3_TRA_H + 48 + nSoro * 2], \
parametros[DESL_3_TRA_H + 49 + nSoro * 2], \
(randPerc)))

#define TAXA_MORTE_DENGUE \
(double) (ENTRE_FAIXA( \
parametros[DESL_3_TRA_H + 56], \
parametros[DESL_3_TRA_H + 57], \
(randPerc)))

#define TAXA_EFICACIA_VACINA \
(double) (ENTRE_FAIXA( \
parametros[DESL_3_TRA_H + 58], \
parametros[DESL_3_TRA_H + 59], \
(randPerc)))

#endif
