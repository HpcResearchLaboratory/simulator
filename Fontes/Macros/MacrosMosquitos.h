#ifndef __MACROS_MOSQUITOS__
#define __MACROS_MOSQUITOS__

/*
  Definições para a representação bitstring dos agentes mosquitos:

  Tira 1:
  -- = Sobra                                      (8 bits, 256 valores)
  S  = Sexo                                       (1 bit, 2 valores)
  SW = Saúde Wolbachia                            (1 bit, 2 valores)
  FS = Fase                                       (3 bits, 8 valores)
  IE = Idade                                      (8 bit, 256 valores)
  SD = Saúde Dengue                               (2 bits, 4 valores)
  ST = Sorotipo                                   (3 bits, 8 valores)
  VD = Vida                                       (1 bit, 2 valores)
  C  = Contador                                   (5 bits, 32 valores)

  Tira 2:
  -- = Sobra                                      (1 bit, 2 valores)
  CR = Contador de repastos realizados            (4 bits, 16 valores)
  FG = Flag de geração                            (1 bit, 2 valores)
  TI = Tipo de Influência Tratamento Ambiental    (2 bits, 4 valores)
  FM = Flag Busca Macho                           (1 bit, 2 valores)
  FP = Flag Busca Ponto Estratégico               (1 bit, 2 valores)
  FV = Flag Vôo Levy                              (1 bit, 2 valores)
  CG = Ciclos de gestação                         (5 bit, 32 valores)
  CE = Contador de ciclos entre posturas          (5 bits, 32 valores)
  PR = Tipo de prole                              (3 bits, 8 valores)
  AM = Alimentado                                 (1 bit, 2 valores)
  TA = Tipo de acasalamento                       (2 bits, 4 valores)
  CP = Contador de posturas                       (5 bits, 32 valores)

  Tira 3:
  X = Latitude                                    (19 bits, 524.288 valores)
  L = Lote                                        (13 bits, 8.192 valores)

  Tira 4:
  Y = Longitude                                   (23 bits, 8.388.608 valores)
  Q = Quadra                                      (9 bits, 512 valores)

  Atributo C:
    Macho: conta a quantidade de acasalamentos
    Fêmea: conta a quantidade de ciclos de latência e tentativas nas buscas
*/

/*
  Tamanho em bits dos campos
*/

#define TM_S  1
#define TM_SW 1
#define TM_FS 3
#define TM_IE 8
#define TM_SD 2
#define TM_ST 3
#define TM_VD 1
#define TM_C  5

#define TM_CR 4
#define TM_FG 1
#define TM_TI 2
#define TM_FM 1
#define TM_FP 1
#define TM_FV 1
#define TM_CG 5
#define TM_CE 5
#define TM_PR 3
#define TM_AM 1
#define TM_TA 2
#define TM_CP 5

#define TM_X 19
#define TM_L 13

#define TM_Y 23
#define TM_Q 9

/*
  Quantidade de bits anteriores a cada campo
*/

#define AM_S  23
#define AM_SW 22
#define AM_FS 19
#define AM_IE 11
#define AM_SD 9
#define AM_ST 6
#define AM_VD 5
#define AM_C  0

#define AM_CR 27
#define AM_FG 26
#define AM_TI 24
#define AM_FM 23
#define AM_FP 22
#define AM_FV 21
#define AM_CG 16
#define AM_CE 11
#define AM_PR 8
#define AM_AM 7
#define AM_TA 5
#define AM_CP 0

#define AM_X 13
#define AM_L 0

#define AM_Y 9
#define AM_Q 0

/*
  Máscaras Positivas
*/

#define MAM_S  (unsigned)8388608U
#define MAM_SW (unsigned)4194304U
#define MAM_FS (unsigned)3670016U
#define MAM_IE (unsigned)522240U
#define MAM_SD (unsigned)1536U
#define MAM_ST (unsigned)448U
#define MAM_VD (unsigned)32U
#define MAM_C  (unsigned)31U

#define MAM_CR (unsigned)2013265920U
#define MAM_FG (unsigned)67108864U
#define MAM_TI (unsigned)50331648U
#define MAM_FM (unsigned)8388608U
#define MAM_FP (unsigned)4194304U
#define MAM_FV (unsigned)2097152U
#define MAM_CG (unsigned)2031616U
#define MAM_CE (unsigned)63488U
#define MAM_PR (unsigned)1792U
#define MAM_AM (unsigned)128U
#define MAM_TA (unsigned)96U
#define MAM_CP (unsigned)31U

#define MAM_X (unsigned)4294959104U
#define MAM_L (unsigned)8191U

#define MAM_Y (unsigned)4294966784U
#define MAM_Q (unsigned)511U

/*
  Máscaras Negativas
*/

#define NMM_S  (unsigned)4286578687U
#define NMM_SW (unsigned)4290772991U
#define NMM_FS (unsigned)4291297279U
#define NMM_IE (unsigned)4294445055U
#define NMM_SD (unsigned)4294965759U
#define NMM_ST (unsigned)4294966847U
#define NMM_VD (unsigned)4294967263U
#define NMM_C  (unsigned)4294967264U

#define NMM_CR (unsigned)2281701375U
#define NMM_FG (unsigned)4227858431U
#define NMM_TI (unsigned)4244635647U
#define NMM_FM (unsigned)4286578687U
#define NMM_FP (unsigned)4290772991U
#define NMM_FV (unsigned)4292870143U
#define NMM_CG (unsigned)4292935679U
#define NMM_CE (unsigned)4294903807U
#define NMM_PR (unsigned)4294965503U
#define NMM_AM (unsigned)4294967167U
#define NMM_TA (unsigned)4294967199U
#define NMM_CP (unsigned)4294967264U

#define NMM_X (unsigned)8191U
#define NMM_L (unsigned)4294959104U

#define NMM_Y (unsigned)511U
#define NMM_Q (unsigned)4294966784U

/*
  Getters com id (acesso ao vetor)
*/

// Operação get genérica
#define GET_M(i, t, ma, a) ((mosquitos[(i)].t & ma) >> a)

#define GET_S_M(i)  (int)(GET_M(i, t1, MAM_S,  AM_S))
#define GET_SW_M(i) (int)(GET_M(i, t1, MAM_SW, AM_SW))
#define GET_FS_M(i) (int)(GET_M(i, t1, MAM_FS, AM_FS))
#define GET_IE_M(i) (int)(GET_M(i, t1, MAM_IE, AM_IE))
#define GET_SD_M(i) (int)(GET_M(i, t1, MAM_SD, AM_SD))
#define GET_ST_M(i) (int)(GET_M(i, t1, MAM_ST, AM_ST))
#define GET_VD_M(i) (int)(GET_M(i, t1, MAM_VD, AM_VD))
#define GET_C_M(i)  (int)(GET_M(i, t1, MAM_C,  AM_C))

#define GET_CR_M(i) (int)(GET_M(i, t2, MAM_CR, AM_CR))
#define GET_FG_M(i) (int)(GET_M(i, t2, MAM_FG, AM_FG))
#define GET_TI_M(i) (int)(GET_M(i, t2, MAM_TI, AM_TI))
#define GET_FM_M(i) (int)(GET_M(i, t2, MAM_FM, AM_FM))
#define GET_FP_M(i) (int)(GET_M(i, t2, MAM_FP, AM_FP))
#define GET_FV_M(i) (int)(GET_M(i, t2, MAM_FV, AM_FV))
#define GET_CG_M(i) (int)(GET_M(i, t2, MAM_CG, AM_CG))
#define GET_CE_M(i) (int)(GET_M(i, t2, MAM_CE, AM_CE))
#define GET_PR_M(i) (int)(GET_M(i, t2, MAM_PR, AM_PR))
#define GET_AM_M(i) (int)(GET_M(i, t2, MAM_AM, AM_AM))
#define GET_TA_M(i) (int)(GET_M(i, t2, MAM_TA, AM_TA))
#define GET_CP_M(i) (int)(GET_M(i, t2, MAM_CP, AM_CP))

#define GET_X_M(i) (int)(GET_M(i, t3, MAM_X, AM_X))
#define GET_L_M(i) (int)(GET_M(i, t3, MAM_L, AM_L))

#define GET_Y_M(i) (int)(GET_M(i, t4, MAM_Y, AM_Y))
#define GET_Q_M(i) (int)(GET_M(i, t4, MAM_Q, AM_Q))

/*
  Getters sem id (acesso ao objeto)
*/

// Operação get genérica
#define GET_M_(t, ma, a) ((mosquito.t & ma) >> a)

#define GET_S_M_  (int)(GET_M_(t1, MAM_S,  AM_S))
#define GET_SW_M_ (int)(GET_M_(t1, MAM_SW, AM_SW))
#define GET_FS_M_ (int)(GET_M_(t1, MAM_FS, AM_FS))
#define GET_IE_M_ (int)(GET_M_(t1, MAM_IE, AM_IE))
#define GET_SD_M_ (int)(GET_M_(t1, MAM_SD, AM_SD))
#define GET_ST_M_ (int)(GET_M_(t1, MAM_ST, AM_ST))
#define GET_VD_M_ (int)(GET_M_(t1, MAM_VD, AM_VD))
#define GET_C_M_  (int)(GET_M_(t1, MAM_C,  AM_C))

#define GET_CR_M_ (int)(GET_M_(t2, MAM_CR, AM_CR))
#define GET_FG_M_ (int)(GET_M_(t2, MAM_FG, AM_FG))
#define GET_TI_M_ (int)(GET_M_(t2, MAM_TI, AM_TI))
#define GET_FM_M_ (int)(GET_M_(t2, MAM_FM, AM_FM))
#define GET_FP_M_ (int)(GET_M_(t2, MAM_FP, AM_FP))
#define GET_FV_M_ (int)(GET_M_(t2, MAM_FV, AM_FV))
#define GET_CG_M_ (int)(GET_M_(t2, MAM_CG, AM_CG))
#define GET_CE_M_ (int)(GET_M_(t2, MAM_CE, AM_CE))
#define GET_PR_M_ (int)(GET_M_(t2, MAM_PR, AM_PR))
#define GET_AM_M_ (int)(GET_M_(t2, MAM_AM, AM_AM))
#define GET_TA_M_ (int)(GET_M_(t2, MAM_TA, AM_TA))
#define GET_CP_M_ (int)(GET_M_(t2, MAM_CP, AM_CP))

#define GET_X_M_ (int)(GET_M_(t3, MAM_X, AM_X))
#define GET_L_M_ (int)(GET_M_(t3, MAM_L, AM_L))

#define GET_Y_M_ (int)(GET_M_(t4, MAM_Y, AM_Y))
#define GET_Q_M_ (int)(GET_M_(t4, MAM_Q, AM_Q))

/*
  Setters
*/

// Operação set genérica
#define SET_M(i, t, novo, nm, a) (mosquitos[(i)].t = \
((mosquitos[(i)].t & nm) | (((unsigned)(novo)) << a)))

#define SET_S_M(i, novo)  (SET_M(i, t1, novo, NMM_S, AM_S))
#define SET_SW_M(i, novo) (SET_M(i, t1, novo, NMM_SW, AM_SW))
#define SET_FS_M(i, novo) (SET_M(i, t1, novo, NMM_FS, AM_FS))
#define SET_IE_M(i, novo) (SET_M(i, t1, novo, NMM_IE, AM_IE))
#define SET_SD_M(i, novo) (SET_M(i, t1, novo, NMM_SD, AM_SD))
#define SET_ST_M(i, novo) (SET_M(i, t1, novo, NMM_ST, AM_ST))
#define SET_VD_M(i, novo) (SET_M(i, t1, novo, NMM_VD, AM_VD))
#define SET_C_M(i, novo)  (SET_M(i, t1, novo, NMM_C, AM_C))

#define SET_CR_M(i, novo) (SET_M(i, t2, novo, NMM_CR, AM_CR))
#define SET_FG_M(i, novo) (SET_M(i, t2, novo, NMM_FG, AM_FG))
#define SET_TI_M(i, novo) (SET_M(i, t2, novo, NMM_TI, AM_TI))
#define SET_FM_M(i, novo) (SET_M(i, t2, novo, NMM_FM, AM_FM))
#define SET_FP_M(i, novo) (SET_M(i, t2, novo, NMM_FP, AM_FP))
#define SET_FV_M(i, novo) (SET_M(i, t2, novo, NMM_FV, AM_FV))
#define SET_CG_M(i, novo) (SET_M(i, t2, novo, NMM_CG, AM_CG))
#define SET_CE_M(i, novo) (SET_M(i, t2, novo, NMM_CE, AM_CE))
#define SET_PR_M(i, novo) (SET_M(i, t2, novo, NMM_PR, AM_PR))
#define SET_AM_M(i, novo) (SET_M(i, t2, novo, NMM_AM, AM_AM))
#define SET_TA_M(i, novo) (SET_M(i, t2, novo, NMM_TA, AM_TA))
#define SET_CP_M(i, novo) (SET_M(i, t2, novo, NMM_CP, AM_CP))

#define SET_X_M(i, novo) (SET_M(i, t3, novo, NMM_X, AM_X))
#define SET_L_M(i, novo) (SET_M(i, t3, novo, NMM_L, AM_L))

#define SET_Y_M(i, novo) (SET_M(i, t4, novo, NMM_Y, AM_Y))
#define SET_Q_M(i, novo) (SET_M(i, t4, novo, NMM_Q, AM_Q))

/*
  Getter e setter para o identificador individual
*/
#define GET_ID_M(i) (mosquitos[(i)].id)
#define GET_ID_M_() (mosquito.id)
#define SET_ID_M(i, novo) (mosquitos[(i)].id = novo)

#endif
