#ifndef __3_TRA_M__
#define __3_TRA_M__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Mosquitos/3-TRA.csv":

  IDADE_MOSQUITOS_NAO_ALADOS:     Parâmetros "TRA001" a "TRA003".
  IDADE_MOSQUITOS_ATIVOS:         Parâmetros "TRA004" a "TRA007".
  IDADE_MOSQUITOS_DECADENTES:     Parâmetros "TRA008" a "TRA011".
  CS_OVOS:                        Parâmetro  "TRA012".
  CI_OVOS:                        Parâmetro  "TRA013".
  BS_OVOS:                        Parâmetro  "TRA014".
  BI_OVOS:                        Parâmetro  "TRA015".
  CS_LARVAS:                      Parâmetro  "TRA016".
  CI_LARVAS:                      Parâmetro  "TRA017".
  BS_LARVAS:                      Parâmetro  "TRA018".
  BI_LARVAS:                      Parâmetro  "TRA019".
  CS_PUPAS:                       Parâmetro  "TRA020".
  CI_PUPAS:                       Parâmetro  "TRA021".
  BS_PUPAS:                       Parâmetro  "TRA022".
  BI_PUPAS:                       Parâmetro  "TRA023".
  CS_ATIVOS:                      Parâmetro  "TRA024".
  CI_ATIVOS:                      Parâmetro  "TRA025".
  BS_ATIVOS:                      Parâmetro  "TRA026".
  BI_ATIVOS:                      Parâmetro  "TRA027".
  CICLOS_LATENCIA_MOSQUITOS:      Parâmetro  "TRA028".
  IDADE_MAX_MOSQUITOS_DENGUE:     Parâmetro  "TRA029".
*/

#define IDADE_MOSQUITOS_NAO_ALADOS(fs) \
(int)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 0 + fs * 2], \
parametros[DESL_3_TRA_M + 1 + fs * 2], \
(randPerc)))

#define IDADE_MOSQUITOS_NAO_ALADOS_(fs, per) \
(int)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 0 + fs * 2], \
parametros->parametros[DESL_3_TRA_M + 1 + fs * 2], \
per))

#define IDADE_MOSQUITOS_ATIVOS(s, sw) \
(int)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 6 + s * 2 * 2 + sw * 2], \
parametros[DESL_3_TRA_M + 7 + s * 2 * 2 + sw * 2], \
(randPerc)))

#define IDADE_MOSQUITOS_ATIVOS_(s, sw, per)\
(int)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 6 + s * 2 * 2 + sw * 2], \
parametros->parametros[DESL_3_TRA_M + 7 + s * 2 * 2 + sw * 2], \
per))

#define IDADE_MOSQUITOS_DECADENTES(s, sw) \
(int)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 14 + s * 2 * 2 + sw * 2], \
parametros[DESL_3_TRA_M + 15 + s * 2 * 2 + sw * 2], \
(randPerc)))

#define IDADE_MOSQUITOS_DECADENTES_(s, sw, per) \
(int)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 14 + s * 2 * 2 + sw * 2], \
parametros->parametros[DESL_3_TRA_M + 15 + s * 2 * 2 + sw * 2], \
per))

#define IDADE_MAX_MOSQUITOS_NAO_ALADOS(fs) \
(int)(parametros[DESL_3_TRA_M + 1 + fs * 2])

#define IDADE_MAX_MOSQUITOS_ATIVOS(s, sw) \
(int)(parametros[DESL_3_TRA_M + 7 + s * 2 * 2 + sw * 2])

#define IDADE_MAX_MOSQUITOS_DECADENTES(s, sw) \
(int)(parametros[DESL_3_TRA_M + 15 + s * 2 * 2 + sw * 2])

#define CS_OVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 22], \
parametros[DESL_3_TRA_M + 23], \
randPerc))

#define CI_OVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 24], \
parametros[DESL_3_TRA_M + 25], \
randPerc))

#define BS_OVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 26], \
parametros[DESL_3_TRA_M + 27], \
randPerc))

#define BS_OVOS_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 26], \
parametros->parametros[DESL_3_TRA_M + 27], \
per))

#define BI_OVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 28], \
parametros[DESL_3_TRA_M + 29], \
randPerc))

#define CS_LARVAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 30], \
parametros[DESL_3_TRA_M + 31], \
randPerc))

#define CI_LARVAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 32], \
parametros[DESL_3_TRA_M + 33], \
randPerc))

#define BS_LARVAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 34], \
parametros[DESL_3_TRA_M + 35], \
randPerc))

#define BS_LARVAS_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 34], \
parametros->parametros[DESL_3_TRA_M + 35], \
per))

#define BI_LARVAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 36], \
parametros[DESL_3_TRA_M + 37], \
randPerc))

#define CS_PUPAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 38], \
parametros[DESL_3_TRA_M + 39], \
randPerc))

#define CI_PUPAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 40], \
parametros[DESL_3_TRA_M + 41], \
randPerc))

#define BS_PUPAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 42], \
parametros[DESL_3_TRA_M + 43], \
randPerc))

#define BS_PUPAS_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 42], \
parametros->parametros[DESL_3_TRA_M + 43], \
per))

#define BI_PUPAS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 44], \
parametros[DESL_3_TRA_M + 45], \
randPerc))

#define CS_ATIVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 46], \
parametros[DESL_3_TRA_M + 47], \
randPerc))

#define CI_ATIVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 48], \
parametros[DESL_3_TRA_M + 49], \
randPerc))

#define BS_ATIVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 50], \
parametros[DESL_3_TRA_M + 51], \
randPerc))

#define BS_ATIVOS_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 50], \
parametros->parametros[DESL_3_TRA_M + 51], \
per))

#define BI_ATIVOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 52], \
parametros[DESL_3_TRA_M + 53], \
randPerc))

#define CICLOS_LATENCIA_MOSQUITOS \
(int)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 54], \
parametros[DESL_3_TRA_M + 55], \
randPerc))

#define CICLOS_LATENCIA_MOSQUITOS_(per) \
(int)(ENTRE_FAIXA( \
parametros->parametros[DESL_3_TRA_M + 54], \
parametros->parametros[DESL_3_TRA_M + 55], \
per))

#define IDADE_MAX_MOSQUITOS_DENGUE \
(int)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 56], \
parametros[DESL_3_TRA_M + 57], \
randPerc))

#define TAXA_SOBREVIVENCIA(fs, s, sw) \
(double)(ENTRE_FAIXA( \
parametros[DESL_3_TRA_M + 22 + 8 * fs + 4 * s + 2 * sw], \
parametros[DESL_3_TRA_M + 23 + 8 * fs + 4 * s + 2 * sw], \
randPerc))

#endif
