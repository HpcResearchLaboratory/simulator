#ifndef __MACROS_HUMANOS__
#define __MACROS_HUMANOS__

/*
  Definições para a representação bitstring dos agentes humanos:

  Tira 1:
  R = Rota                                        (3 bits, 8 valores)
  T = Trajeto                                     (16 bits, 65.536 valores)
  F = Flag de movimentação                        (1 bit, 2 valores)
  M = Contador de movimentação                    (10 bits, 1.024 valores)
  K = Tipo de movimentação                        (2 bits, 4 valores)

  Tira 2:
  -- = Sobra                                      (4 bits, 16 valores)
  CR = Contador de repastos                       (3 bits, 8 valores)
  S = Sexo                                        (1 bit, 2 valores)
  FE = Faixa etária                               (3 bits, 8 valores)
  SD = Saúde Dengue                               (3 bits, 8 valores)
  ST = Sorotipo atual                             (3 bits, 8 valores)
  SC = Sorotipos contraídos                       (4 bits, 16 valores)
  A = Assintomático                               (1 bit, 2 valores)
  C = Contador de transições de estado            (8 bits, 256 valores)
  CV = Contador de vacinas                        (2 bits, 4 valores)

  Tira 3:
  X = Latitude                                    (19 bits, 524.288 valores)
  L = Lote                                        (13 bits, 8.192 valores)

  Tira 4:
  Y = Longitude                                   (23 bits, 8.388.608 valores)
  Q = Quadra                                      (9 bits, 512 valores)
*/

/*
  Tamanho em bits dos campos
*/

#define TH_R 3
#define TH_T 16
#define TH_F 1
#define TH_M 10
#define TH_K 2

#define TH_CR 3
#define TH_S  1
#define TH_FE 3
#define TH_SD 3
#define TH_ST 3
#define TH_SC 4
#define TH_A  1
#define TH_C  8
#define TH_CV 2

#define TH_X 19
#define TH_L 13

#define TH_Y 23
#define TH_Q 9

/*
  Quantidade de bits anteriores a cada campo
*/

#define AH_R 29
#define AH_T 13
#define AH_F 12
#define AH_M 2
#define AH_K 0

#define AH_CR 25
#define AH_S  24
#define AH_FE 21
#define AH_SD 18
#define AH_ST 15
#define AH_SC 11
#define AH_A  10
#define AH_C  2
#define AH_CV 0

#define AH_X 13
#define AH_L 0

#define AH_Y 9
#define AH_Q 0

/*
  Máscaras Positivas
*/

#define MAH_R (unsigned)3758096384U
#define MAH_T (unsigned)536862720U
#define MAH_F (unsigned)4096U
#define MAH_M (unsigned)4092U
#define MAH_K (unsigned)3U

#define MAH_CR (unsigned)234881024U
#define MAH_S  (unsigned)16777216U
#define MAH_FE (unsigned)14680064U
#define MAH_SD (unsigned)1835008U
#define MAH_ST (unsigned)229376U
#define MAH_SC (unsigned)30720U
#define MAH_A  (unsigned)1024U
#define MAH_C  (unsigned)1020U
#define MAH_CV (unsigned)3U

#define MAH_X (unsigned)4294959104U
#define MAH_L (unsigned)8191U

#define MAH_Y (unsigned)4294966784U
#define MAH_Q (unsigned)511U

/*
  Máscaras Negativas
*/

#define NMH_R (unsigned)536870911U
#define NMH_T (unsigned)3758104575U
#define NMH_F (unsigned)4294963199U
#define NMH_M (unsigned)4294963203U
#define NMH_K (unsigned)4294967292U

#define NMH_CR (unsigned)4060086271U
#define NMH_S  (unsigned)4278190079U
#define NMH_FE (unsigned)4280287231U
#define NMH_SD (unsigned)4293132287U
#define NMH_ST (unsigned)4294737919U
#define NMH_SC (unsigned)4294936575U
#define NMH_A  (unsigned)4294966271U
#define NMH_C  (unsigned)4294966275U
#define NMH_CV (unsigned)4294967292U

#define NMH_X (unsigned)8191U
#define NMH_L (unsigned)4294959104U

#define NMH_Y (unsigned)511U
#define NMH_Q (unsigned)4294966784U

/*
  Getters com id (acesso ao vetor)
*/

// Operação get genérica
#define GET_H(i, t, ma, a) ((humanos[(i)].t & ma) >> a)

#define GET_R_H(i) (int)(GET_H(i, t1, MAH_R, AH_R))
#define GET_T_H(i) (int)(GET_H(i, t1, MAH_T, AH_T))
#define GET_F_H(i) (int)(GET_H(i, t1, MAH_F, AH_F))
#define GET_M_H(i) (int)(GET_H(i, t1, MAH_M, AH_M))
#define GET_K_H(i) (int)(GET_H(i, t1, MAH_K, AH_K))

#define GET_CR_H(i) (int)(GET_H(i, t2, MAH_CR, AH_CR))
#define GET_S_H(i)  (int)(GET_H(i, t2, MAH_S, AH_S))
#define GET_FE_H(i) (int)(GET_H(i, t2, MAH_FE, AH_FE))
#define GET_SD_H(i) (int)(GET_H(i, t2, MAH_SD, AH_SD))
#define GET_ST_H(i) (int)(GET_H(i, t2, MAH_ST, AH_ST))
#define GET_SC_H(i) (int)(GET_H(i, t2, MAH_SC, AH_SC))
#define GET_A_H(i)  (int)(GET_H(i, t2, MAH_A, AH_A))
#define GET_C_H(i)  (int)(GET_H(i, t2, MAH_C, AH_C))
#define GET_CV_H(i) (int)(GET_H(i, t2, MAH_CV, AH_CV))

#define GET_X_H(i) (int)(GET_H(i, t3, MAH_X, AH_X))
#define GET_L_H(i) (int)(GET_H(i, t3, MAH_L, AH_L))

#define GET_Y_H(i) (int)(GET_H(i, t4, MAH_Y, AH_Y))
#define GET_Q_H(i) (int)(GET_H(i, t4, MAH_Q, AH_Q))

/*
  Getters sem id (acesso ao objeto)
*/

// Operação get genérica
#define GET_H_(t, ma, a) ((humano.t & ma) >> a)

#define GET_R_H_ (int)(GET_H_(t1, MAH_R, AH_R))
#define GET_T_H_ (int)(GET_H_(t1, MAH_T, AH_T))
#define GET_F_H_ (int)(GET_H_(t1, MAH_F, AH_F))
#define GET_M_H_ (int)(GET_H_(t1, MAH_M, AH_M))
#define GET_K_H_ (int)(GET_H_(t1, MAH_K, AH_K))

#define GET_CR_H_ (int)(GET_H_(t2, MAH_CR, AH_CR))
#define GET_S_H_  (int)(GET_H_(t2, MAH_S, AH_S))
#define GET_FE_H_ (int)(GET_H_(t2, MAH_FE, AH_FE))
#define GET_SD_H_ (int)(GET_H_(t2, MAH_SD, AH_SD))
#define GET_ST_H_ (int)(GET_H_(t2, MAH_ST, AH_ST))
#define GET_SC_H_ (int)(GET_H_(t2, MAH_SC, AH_SC))
#define GET_A_H_  (int)(GET_H_(t2, MAH_A, AH_A))
#define GET_C_H_  (int)(GET_H_(t2, MAH_C, AH_C))
#define GET_CV_H_ (int)(GET_H_(t2, MAH_CV, AH_CV))

#define GET_X_H_ (int)(GET_H_(t3, MAH_X, AH_X))
#define GET_L_H_ (int)(GET_H_(t3, MAH_L, AH_L))

#define GET_Y_H_ (int)(GET_H_(t4, MAH_Y, AH_Y))
#define GET_Q_H_ (int)(GET_H_(t4, MAH_Q, AH_Q))

/*
  Setters
*/

// Operação set genérica
#define SET_H(i, t, novo, nm, a) (humanos[(i)].t = \
((humanos[(i)].t & nm) | (((unsigned)(novo)) << a)))

#define SET_R_H(i, novo) (SET_H(i, t1, novo, NMH_R, AH_R))
#define SET_T_H(i, novo) (SET_H(i, t1, novo, NMH_T, AH_T))
#define SET_F_H(i, novo) (SET_H(i, t1, novo, NMH_F, AH_F))
#define SET_M_H(i, novo) (SET_H(i, t1, novo, NMH_M, AH_M))
#define SET_K_H(i, novo) (SET_H(i, t1, novo, NMH_K, AH_K))

#define SET_CR_H(i, novo) (SET_H(i, t2, novo, NMH_CR, AH_CR))
#define SET_S_H(i, novo)  (SET_H(i, t2, novo, NMH_S, AH_S))
#define SET_FE_H(i, novo) (SET_H(i, t2, novo, NMH_FE, AH_FE))
#define SET_SD_H(i, novo) (SET_H(i, t2, novo, NMH_SD, AH_SD))
#define SET_ST_H(i, novo) (SET_H(i, t2, novo, NMH_ST, AH_ST))
#define SET_SC_H(i, novo) (SET_H(i, t2, novo, NMH_SC, AH_SC))
#define SET_A_H(i, novo)  (SET_H(i, t2, novo, NMH_A, AH_A))
#define SET_C_H(i, novo)  (SET_H(i, t2, novo, NMH_C, AH_C))
#define SET_CV_H(i, novo) (SET_H(i, t2, novo, NMH_CV, AH_CV))

#define SET_X_H(i, novo) (SET_H(i, t3, novo, NMH_X, AH_X))
#define SET_L_H(i, novo) (SET_H(i, t3, novo, NMH_L, AH_L))

#define SET_Y_H(i, novo) (SET_H(i, t4, novo, NMH_Y, AH_Y))
#define SET_Q_H(i, novo) (SET_H(i, t4, novo, NMH_Q, AH_Q))

/*
  Getter e setter para o identificador individual
*/

#define GET_ID_H(i) (humanos[(i)].id)
#define GET_ID_H_() (humano.id)
#define SET_ID_H(i, novo) (humanos[(i)].id = novo)

#endif
