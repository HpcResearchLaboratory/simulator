#ifndef __MACROS__
#define __MACROS__

// Períodos de um ciclo
#define MANHA       0
#define TARDE       1
#define NOITE       2
#define N_PERIODOS  3

// Quantidade de colunas das saídas de quantidades dos agentes
#define N_COLS_H  360 // N_SEXOS * N_IDADES * N_ESTADOS_H * (N_SOROTIPOS + 1)
#define N_COLS_MD 150 // N_SEXOS * N_FASES * N_ESTADOS_MD * (N_SOROTIPOS + 1)
#define N_COLS_MW 20  // N_SEXOS * N_FASES * N_ESTADOS_MW

// Linearização de matriz
#define VEC(i, j, nc) (((i) * (nc)) + (j))

// Lotes pertencentes à quadra com id = 0 são as ruas
#define RUA 0

// Distância euclidiana
#define DIST(x1, y1, x2, y2) \
(double)(sqrt(pow((x1) - (x2), 2.0) + pow((y1) - (y2), 2.0)))

// Estados da dengue para mosquitos e humanos (SD)
#define SUSCETIVEL    1
#define EXPOSTO       2
#define INFECTANTE    3
#define HEMORRAGICO   4
#define IMUNIZADO     5
#define RECUPERADO    6
#define N_ESTADOS_H   6
#define N_ESTADOS_MD  3
#define N_ESTADOS_MW  2

// Estados para o atributo vida do mosquito (VD)
#define VIVO  1
#define MORTO 0

// Sexos para humanos e mosquitos (S)
#define MASCULINO 0
#define FEMININO  1
#define MACHO     0
#define FEMEA     1
#define N_SEXOS   2

// Sorotipos para os humanos e mosquitos (ST)
#define SOROTIPO_1  1
#define SOROTIPO_2  2
#define SOROTIPO_3  3
#define SOROTIPO_4  4
#define N_SOROTIPOS 4

// Faixas etárias dos humanos (FE)
#define BEBE        0
#define CRIANCA     1
#define ADOLESCENTE 2
#define JOVEM       3
#define ADULTO      4
#define IDOSO       5
#define N_IDADES    6

// Tipos de movimentação dos humanos (K)
#define LOCAL     0
#define ALEATORIO 1
#define LIVRE     2
#define TRAJETO   3
#define N_MOVS    4

// Tipos de prole dos mosquitos (PR)
#define SAUDAVEL  0
#define WOLBACHIA 1
#define ESTERIL   2

// Fases dos mosquitos (FS)
#define OVO         0
#define LARVA       1
#define PUPA        2
#define ATIVA       3
#define DECADENTE   4
#define N_FASES     5

// Tipos de acasalamento dos mosquitos (TA)
#define NENHUM        0
#define ACA_SAUDAVEL  1
#define ACA_INFECTADO 2

// Tipos de influência exercidos pelo tratamento ambiental
// na movimentação dos mosquitos (TI)
#define SEM_INFLUENCIA  0
#define PARADO          1
#define ESPANTADO       2

// Alimentação do mosquito (AM)
#define ALIMENTADO      1
#define NAO_ALIMENTADO  0

#endif
