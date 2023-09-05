#ifndef __0_INI_M__
#define __0_INI_M__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Mosquitos/0-INI.csv":

  QUANTIDADE_MOSQUITOS_SAUDAVEIS:         Parâmetros "INI001" a "INI006".
  QUANTIDADE_MOSQUITOS_WOLBACHIA:         Parâmetros "INI007" a "INI012".
  QUANTIDADE_MOSQUITOS_DENGUE:            Parâmetros "INI013" a "INI016".
  PROBABILIDADE_DISTRIBUICAO_MOSQUITOS:   Parâmetro  "INI017".
*/

#define QUANTIDADE_MOSQUITOS_SAUDAVEIS(s, fs) \
(int)(parametros->parametros[DESL_0_INI_M + 0 + s * 3 * 2 + fs * 2])

#define QUANTIDADE_MOSQUITOS_WOLBACHIA(s, fs) \
(int)(parametros->parametros[DESL_0_INI_M + 12 + s * 3 * 2 + fs * 2])

#define QUANTIDADE_MOSQUITOS_DENGUE(st) \
(int)(parametros->parametros[DESL_0_INI_M + 24 + (st - 1) * 2])

#define PROBABILIDADE_DISTRIBUICAO_MOSQUITOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_0_INI_M + 32], \
parametros[DESL_0_INI_M + 33], \
randPerc))

#define PROBABILIDADE_DISTRIBUICAO_MOSQUITOS_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_0_INI_M + 32], \
parametros->parametros[DESL_0_INI_M + 33], \
per))

#endif
