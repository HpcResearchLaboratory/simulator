#ifndef __5_INS_H__
#define __5_INS_H__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Humanos/5-INS.csv":

  CICLO_ENTRADA_HUMANOS_S:    Parâmetro "INS001".
  QUANTIDADE_HUMANOS_S:       Parâmetro "INS002".
  CICLO_ENTRADA_HUMANOS_I1:   Parâmetro "INS003".
  QUANTIDADE_HUMANOS_I1:      Parâmetro "INS004".
  CICLO_ENTRADA_HUMANOS_I2:   Parâmetro "INS005".
  QUANTIDADE_HUMANOS_I2:      Parâmetro "INS006".
  CICLO_ENTRADA_HUMANOS_I3:   Parâmetro "INS007".
  QUANTIDADE_HUMANOS_I3:      Parâmetro "INS008".
  CICLO_ENTRADA_HUMANOS_I4:   Parâmetro "INS009".
  QUANTIDADE_HUMANOS_I4:      Parâmetro "INS010".
*/

#define CICLO_ENTRADA_HUMANOS_S \
(int) (parametros[DESL_5_INS_H + 0])

#define QUANTIDADE_HUMANOS_S \
(int) (parametros[DESL_5_INS_H + 2])

#define CICLO_ENTRADA_HUMANOS_I1 \
(int) (parametros[DESL_5_INS_H + 4])

#define QUANTIDADE_HUMANOS_I1 \
(int) (parametros[DESL_5_INS_H + 6])

#define CICLO_ENTRADA_HUMANOS_I2 \
(int) (parametros[DESL_5_INS_H + 8])

#define QUANTIDADE_HUMANOS_I2 \
(int) (parametros[DESL_5_INS_H + 10])

#define CICLO_ENTRADA_HUMANOS_I3 \
(int) (parametros[DESL_5_INS_H + 12])

#define QUANTIDADE_HUMANOS_I3 \
(int) (parametros[DESL_5_INS_H + 14])

#define CICLO_ENTRADA_HUMANOS_I4 \
(int) (parametros[DESL_5_INS_H + 16])

#define QUANTIDADE_HUMANOS_I4 \
(int) (parametros[DESL_5_INS_H + 18])

#endif
