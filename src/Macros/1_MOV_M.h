#ifndef __1_MOV_M__
#define __1_MOV_M__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Mosquitos/1-MOV.csv":

  TAXA_MOBILIDADE_DIURNA_MOSQUITOS:    Parâmetros "MOV001" a "MOV002".
  TAXA_MOBILIDADE_NOTURNA_MOSQUITOS:   Parâmetros "MOV003" a "MOV004".
  RAIO_BUSCA_MACHO:                    Parâmetro  "MOV005".
  RAIO_BUSCA_PE:                       Parâmetro  "MOV006".
  INTERVALO_BUSCA_HUMANO:              Parâmetro  "MOV007".
  RAIO_BUSCA_HUMANO:                   Parâmetro  "MOV008".
  RAIO_VOO_LEVY_CURTO:                 Parâmetro  "MOV009".
  RAIO_VOO_LEVY_LONGO:                 Parâmetro  "MOV010".
  TENTATIVAS_BUSCA_MACHO:              Parâmetro  "MOV011".
  TENTATIVAS_BUSCA_PE:                 Parâmetro  "MOV012".
  TAXA_MOBILIDADE_MOSQUITO_PARADO:     Parâmetro  "MOV013".
*/

#define TAXA_MOBILIDADE_DIURNA_MOSQUITOS(s) \
(double) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 0 + s * 2], \
parametros[DESL_1_MOV_M + 1 + s * 2], \
(randPerc)))

#define TAXA_MOBILIDADE_NOTURNA_MOSQUITOS(s) \
(double) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 4 + s * 2], \
parametros[DESL_1_MOV_M + 5 + s * 2], \
(randPerc)))

#define RAIO_BUSCA_MACHO \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 8], \
parametros[DESL_1_MOV_M + 9], \
(randPerc)))

#define RAIO_BUSCA_PE \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 10], \
parametros[DESL_1_MOV_M + 11], \
(randPerc)))

#define INTERVALO_BUSCA_HUMANO \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 12], \
parametros[DESL_1_MOV_M + 13], \
(randPerc)))

#define RAIO_BUSCA_HUMANO \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 14], \
parametros[DESL_1_MOV_M + 15], \
(randPerc)))

#define RAIO_VOO_LEVY_CURTO \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 16], \
parametros[DESL_1_MOV_M + 17], \
(randPerc)))

#define RAIO_VOO_LEVY_LONGO \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 18], \
parametros[DESL_1_MOV_M + 19], \
(randPerc)))

#define TENTATIVAS_BUSCA_MACHO \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 20], \
parametros[DESL_1_MOV_M + 21], \
(randPerc)))

#define TENTATIVAS_BUSCA_PE \
(int) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 22], \
parametros[DESL_1_MOV_M + 23], \
(randPerc)))

#define TAXA_MOBILIDADE_MOSQUITO_PARADO \
(double) (ENTRE_FAIXA( \
parametros[DESL_1_MOV_M + 24], \
parametros[DESL_1_MOV_M + 25], \
(randPerc)))

#endif
