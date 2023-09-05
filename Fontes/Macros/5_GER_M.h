#ifndef __5_GER_M__
#define __5_GER_M__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Mosquitos/5-GER.csv":

  INTERVALO_ENTRE_POSTURAS_FEMEA:    Parâmetro "GER001".
  CICLOS_GESTACAO:                   Parâmetro "GER002".
  AS21:                              Parâmetro "GER003".
  PS21:                              Parâmetro "GER004".
  H1:                                Parâmetro "GER005".
  PS31:                              Parâmetro "GER006".
  AI21:                              Parâmetro "GER007".
  PI21:                              Parâmetro "GER008".
  H2:                                Parâmetro "GER009".
  PI31:                              Parâmetro "GER010".
  LIMITE_FOCOS:                      Parâmetro "GER011".
*/

#define INTERVALO_ENTRE_POSTURAS_FEMEA \
(int)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 0], \
parametros[DESL_5_GER_M + 1], \
randPerc))

#define INTERVALO_ENTRE_POSTURAS_FEMEA_(per) \
(int)(ENTRE_FAIXA( \
parametros->parametros[DESL_5_GER_M + 0], \
parametros->parametros[DESL_5_GER_M + 1], \
per))

#define CICLOS_GESTACAO \
(int)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 2], \
parametros[DESL_5_GER_M + 3], \
randPerc))

#define CICLOS_GESTACAO_(per) \
(int)(ENTRE_FAIXA( \
parametros->parametros[DESL_5_GER_M + 2], \
parametros->parametros[DESL_5_GER_M + 3], \
per))

#define AS21 \
(int)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 4], \
parametros[DESL_5_GER_M + 5], \
randPerc))

#define AS21_(per) \
(int)(ENTRE_FAIXA( \
parametros->parametros[DESL_5_GER_M + 4], \
parametros->parametros[DESL_5_GER_M + 5], \
per))

#define AS21_MAX \
(int)(parametros[DESL_5_GER_M + 5])

#define PS21 \
(double)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 6], \
parametros[DESL_5_GER_M + 7], \
randPerc))

#define PS21_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_5_GER_M + 6], \
parametros->parametros[DESL_5_GER_M + 7], \
per))

#define H1 \
(double)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 8], \
parametros[DESL_5_GER_M + 9], \
randPerc))

#define PS31 \
(double)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 10], \
parametros[DESL_5_GER_M + 11], \
randPerc))

#define AI21 \
(int)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 12], \
parametros[DESL_5_GER_M + 13], \
randPerc))

#define AI21_MAX \
(int)(parametros[DESL_5_GER_M + 13])

#define PI21 \
(double)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 14], \
parametros[DESL_5_GER_M + 15], \
randPerc))

#define H2 \
(double)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 16], \
parametros[DESL_5_GER_M + 17], \
randPerc))

#define PI31 \
(double)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 18], \
parametros[DESL_5_GER_M + 19], \
randPerc))

#define LIMITE_FOCOS \
(int)(ENTRE_FAIXA( \
parametros[DESL_5_GER_M + 20], \
parametros[DESL_5_GER_M + 21], \
randPerc))

#endif
