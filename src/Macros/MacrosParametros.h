#ifndef __MACROS_PARAMETROS__
#define __MACROS_PARAMETROS__

/*
  Quantidades de parâmetros presentes nos arquivos de entrada
*/
#define N_0_SIM   4   // "Entradas/MonteCarlo_{i}/Simulacao/0-SIM.csv".
#define N_0_INI_H 196 // "Entradas/MonteCarlo_{i}/Humanos/0-INI.csv".
#define N_1_MOV_H 7   // "Entradas/MonteCarlo_{i}/Humanos/1-MOV.csv".
#define N_2_CON_H 20  // "Entradas/MonteCarlo_{i}/Humanos/2-CON.csv".
#define N_3_TRA_H 30  // "Entradas/MonteCarlo_{i}/Humanos/3-TRA.csv".
#define N_4_CON_H 1   // "Entradas/MonteCarlo_{i}/Humanos/4-CON.csv".
#define N_5_INS_H 10  // "Entradas/MonteCarlo_{i}/Humanos/5-INS.csv".
#define N_0_INI_M 17  // "Entradas/MonteCarlo_{i}/Mosquitos/0-INI.csv".
#define N_1_MOV_M 13  // "Entradas/MonteCarlo_{i}/Mosquitos/1-MOV.csv".
#define N_2_CON_M 12  // "Entradas/MonteCarlo_{i}/Mosquitos/2-CON.csv".
#define N_3_TRA_M 29  // "Entradas/MonteCarlo_{i}/Mosquitos/3-TRA.csv".
#define N_4_CON_M 29  // "Entradas/MonteCarlo_{i}/Mosquitos/4-CON.csv".
#define N_5_GER_M 11  // "Entradas/MonteCarlo_{i}/Mosquitos/5-GER.csv".

/*
  Deslocamentos utilizados para acessar os parâmetros de um determinado arquivo
*/
#define DESL_0_SIM   0   // 0 (Valor inicial)
#define DESL_0_INI_H 8   // DESL_0_SIM   + N_0_SIM   * 2
#define DESL_1_MOV_H 400 // DESL_0_INI_H + N_0_INI_H * 2
#define DESL_2_CON_H 414 // DESL_1_MOV_H + N_1_MOV_H * 2
#define DESL_3_TRA_H 454 // DESL_2_CON_H + N_2_CON_H * 2
#define DESL_4_CON_H 514 // DESL_3_TRA_H + N_3_TRA_H * 2
#define DESL_5_INS_H 516 // DESL_4_CON_H + N_4_CON_H * 2
#define DESL_0_INI_M 536 // DESL_5_INS_H + N_5_INS_H * 2
#define DESL_1_MOV_M 570 // DESL_0_INI_M + N_0_INI_M * 2
#define DESL_2_CON_M 596 // DESL_1_MOV_M + N_1_MOV_M * 2
#define DESL_3_TRA_M 620 // DESL_2_CON_M + N_2_CON_M * 2
#define DESL_4_CON_M 678 // DESL_3_TRA_M + N_3_TRA_M * 2
#define DESL_5_GER_M 736 // DESL_4_CON_M + N_4_CON_M * 2
#define N_PAR        758 // DESL_5_GER_M + N_5_GER_M * 2 (Tamanho do vetor)

/*
  ENTRE_FAIXA:  Macro empregada para gerar um número dentro do
                intervalo ["min", "max") utilizando o percentual "per".
  randPerc:     Macro utilizada para a geração de números aleatórios em GPU.
                "dist" é o gerador empregado e "seed" o número utilizado como
                seed. Esta macro é utilizada somente para funções que executam
                em GPU. Para gerar números aleatórios em CPU é utilizada a
                classe "RandPerc".
*/
#define ENTRE_FAIXA(min, max, per) ((min) + ((max) - (min)) * (per))
#define randPerc dist(seed)

// Valor máximo que pode ser assumido pela variável do tipo UINT32
#define MAX_UINT32 (unsigned)4294967295U

#endif
