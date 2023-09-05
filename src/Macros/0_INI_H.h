#ifndef __0_INI_H__
#define __0_INI_H__

#include "MacrosParametros.h"

/*
  Macros para acesso aos parâmetros armazenados no arquivo
  "Entradas/MonteCarlo_{i}/Humanos/0-INI.csv":

  Não há macros para acesso aos parâmetros "INI001" a "INI128" armazenados
  no arquivo "Entradas/MonteCarlo_{i}/Humanos/0-INI.csv".
  Estes parâmetros são acessados diretamente pelos métodos
  Humanos::criarHumanos e Humanos::contarHumanos.

  PROBABILIDADE_DISTRIBUICAO_HUMANOS:     Parâmetro "INI193".
  PROBABILIDADE_HUMANO_ASSINTOMATICO:     Parâmetro "INI194".
  SOROTIPO_PREDOMINANTE:                  Parâmetro "INI195".
  PROBABILIDADE_SOROTIPO_PREDOMINANTE:    Parâmetro "INI196".
*/

#define PROBABILIDADE_DISTRIBUICAO_HUMANOS(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_0_INI_H + 384], \
parametros->parametros[DESL_0_INI_H + 385], \
per))

#define PROBABILIDADE_HUMANO_ASSINTOMATICO \
(double)(ENTRE_FAIXA( \
parametros[DESL_0_INI_H + 386], \
parametros[DESL_0_INI_H + 387], \
randPerc))

#define PROBABILIDADE_HUMANO_ASSINTOMATICO_(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_0_INI_H + 386], \
parametros->parametros[DESL_0_INI_H + 387], \
per))

#define SOROTIPO_PREDOMINANTE \
(int) (parametros->parametros[DESL_0_INI_H + 388])

#define PROBABILIDADE_SOROTIPO_PREDOMINANTE(per) \
(double)(ENTRE_FAIXA( \
parametros->parametros[DESL_0_INI_H + 390], \
parametros->parametros[DESL_0_INI_H + 391], \
per))

// (Quantidade de parâmetros acessíveis por macros neste arquivo) * 2.
#define N_PAR_0_INI_H 8

#endif
