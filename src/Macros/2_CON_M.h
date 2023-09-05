#ifndef __2_CON_M__
#define __2_CON_M__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Mosquitos/2-CON.csv":

  BETASS22:                 Parâmetro "CON001".
  BETASS23:                 Parâmetro "CON002".
  BETAII22:                 Parâmetro "CON003".
  BETAII23:                 Parâmetro "CON004".
  BETAIS22:                 Parâmetro "CON005".
  BETAIS23:                 Parâmetro "CON006".
  BETASI22:                 Parâmetro "CON007".
  BETASI23:                 Parâmetro "CON008".
  K1:                       Parâmetro "CON009".
  K2:                       Parâmetro "CON010".
  TAXA_FECUNDIDADE_FEMEA:   Parâmetro "CON011".
  REDUCAO_CONTATO_M:        Parâmetro "CON012".
*/

#define BETASS22 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 0], \
parametros[DESL_2_CON_M + 1], \
(randPerc)))

#define BETASS23 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 2], \
parametros[DESL_2_CON_M + 3], \
(randPerc)))

#define BETAII22 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 4], \
parametros[DESL_2_CON_M + 5], \
(randPerc)))

#define BETAII23 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 6], \
parametros[DESL_2_CON_M + 7], \
(randPerc)))

#define BETAIS22 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 8], \
parametros[DESL_2_CON_M + 9], \
(randPerc)))

#define BETAIS23 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 10], \
parametros[DESL_2_CON_M + 11], \
(randPerc)))

#define BETASI22 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 12], \
parametros[DESL_2_CON_M + 13], \
(randPerc)))

#define BETASI23 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 14], \
parametros[DESL_2_CON_M + 15], \
(randPerc)))

#define K1 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 16], \
parametros[DESL_2_CON_M + 17], \
(randPerc)))

#define K2 \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 18], \
parametros[DESL_2_CON_M + 19], \
(randPerc)))

#define TAXA_FECUNDIDADE_FEMEA \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 20], \
parametros[DESL_2_CON_M + 21], \
(randPerc)))

#define REDUCAO_CONTATO_M \
(double)(ENTRE_FAIXA( \
parametros[DESL_2_CON_M + 22], \
parametros[DESL_2_CON_M + 23], \
(randPerc)))

#endif
