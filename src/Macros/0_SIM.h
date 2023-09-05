#ifndef __0_SIM__
#define __0_SIM__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Simulacao/0-SIM.csv":

  QUANTIDADE_SIMULACOES:          Parâmetro "SIM001".
  QUANTIDADE_CICLOS:              Parâmetro "SIM002".
  QUANTIDADE_SUBCICLOS:           Parâmetro "SIM003".
  PROPORCAO_MAXIMO_MOSQUITOS:     Parâmetro "SIM004".
*/

#define QUANTIDADE_SIMULACOES (int)(parametros[DESL_0_SIM + 0])

#define QUANTIDADE_CICLOS (int)(parametros[DESL_0_SIM + 2])

#define QUANTIDADE_SUBCICLOS (int)(parametros[DESL_0_SIM + 4])

#define PROPORCAO_MAXIMO_MOSQUITOS \
(double) (parametros->parametros[DESL_0_SIM + 6])

#endif
