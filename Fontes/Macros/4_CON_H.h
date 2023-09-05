#ifndef __4_CON_H__
#define __4_CON_H__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Humanos/4-CON.csv":

  TAXA_MORTE_NATURAL:     Parâmetro "CON001".
*/

#define TAXA_MORTE_NATURAL \
(double) (ENTRE_FAIXA( \
parametros[DESL_4_CON_H + 0], \
parametros[DESL_4_CON_H + 1], \
(randPerc)))

#define TAXA_MORTE_NATURAL_(per) \
(double) (ENTRE_FAIXA( \
parametros->parametros[DESL_4_CON_H + 0], \
parametros->parametros[DESL_4_CON_H + 1], \
(per)))

#endif
