#ifndef __4_CON_M__
#define __4_CON_M__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Mosquitos/4-CON.csv":

  FREQ_CONTROLE_NATURAL_SELECAO:                        Parâmetro  "CON001".
  TAXA_ELIM_CONTROLE_NATURAL_SELECAO:                   Parâmetros "CON002" a "CON017".
  FREQ_CONTROLE_BIOLOGICO:                              Parâmetro  "CON018".
  QUANT_MACHOS_ATIVOS_CONTROLE_BIOLOGICO:               Parâmetro  "CON019".
  QUANT_FEMEAS_ATIVAS_CONTROLE_BIOLOGICO:               Parâmetro  "CON020".
  FREQ_TRATAMENTO_AMBIENTAL:                            Parâmetro  "CON021".
  FRACAO_TRATAMENTO_AMBIENTAL:                          Parâmetro  "CON022".
  TAXA_TIPO_INFLUENCIA_TRATAMENTO_AMBIENTAL:            Parâmetro  "CON023".
  PROB_EFICACIA_LARVICIDA:                              Parâmetro  "CON024".
  TAXA_CONTROLE_OVOS_EM_FOCOS:                          Parâmetros "CON025" a "CON029".
*/

#define FREQ_CONTROLE_NATURAL_SELECAO \
(int)(parametros[DESL_4_CON_M + 0])

#define TAXA_ELIM_CONTROLE_NATURAL_SELECAO(fs, s, sw) \
(double)(ENTRE_FAIXA( \
parametros[DESL_4_CON_M + 2 + fs * 4 * 2 + s * 2 * 2 + sw * 2], \
parametros[DESL_4_CON_M + 3 + fs * 4 * 2 + s * 2 * 2 + sw * 2], \
randPerc))

#define TAXA_ELIM_CONTROLE_NATURAL_SELECAO_(fs, s, sw, per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_4_CON_M + 2 + fs * 4 * 2 + s * 2 * 2 + sw * 2], \
parametros->parametros[DESL_4_CON_M + 3 + fs * 4 * 2 + s * 2 * 2 + sw * 2], \
per))

#define FREQ_CONTROLE_BIOLOGICO \
(int)(parametros[DESL_4_CON_M + 34])

#define QUANT_MACHOS_ATIVOS_CONTROLE_BIOLOGICO \
(int)(parametros[DESL_4_CON_M + 36])

#define QUANT_FEMEAS_ATIVAS_CONTROLE_BIOLOGICO \
(int)(parametros[DESL_4_CON_M + 38])

#define FREQ_TRATAMENTO_AMBIENTAL \
(int)(parametros[DESL_4_CON_M + 40])

#define FRACAO_TRATAMENTO_AMBIENTAL \
(double)(ENTRE_FAIXA( \
parametros[DESL_4_CON_M + 42], \
parametros[DESL_4_CON_M + 43], \
randPerc))

#define TAXA_TIPO_INFLUENCIA_TRATAMENTO_AMBIENTAL \
(double)(ENTRE_FAIXA( \
parametros[DESL_4_CON_M + 44], \
parametros[DESL_4_CON_M + 45], \
randPerc))

#define DECAIMENTO_CONTROLES_QUIMICOS \
(double)(ENTRE_FAIXA( \
parametros[DESL_4_CON_M + 46], \
parametros[DESL_4_CON_M + 47], \
randPerc))

#define TAXA_CONTROLE_OVOS_EM_FOCOS(nivel) \
(double)(ENTRE_FAIXA( \
parametros[DESL_4_CON_M + 52 + 2 * nivel], \
parametros[DESL_4_CON_M + 53 + 2 * nivel], \
randPerc))

#endif
