CXX = nvcc
CXXFLAGS = -std=c++14 -Wno-deprecated-gpu-targets
LDFLAGS = -dc -I. -c
MAKEFLAGS += -j

SOURCES = $(shell find Fontes/ -name *.cu)
OBJS = $(SOURCES:%.cu=%.o)
EXE = AEDES_Acoplado

all: $(EXE)

$(EXE): $(OBJS)
	$(CXX) $(CXXFLAGS) $(OBJS) -o $(EXE)

%.o: %.cu
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $< -o $@

Fontes/Main.o: Fontes/Main.cu \
							 Fontes/Macros/MacrosSO.h \
							 Fontes/MonteCarlo.h

Fontes/MonteCarlo.o: Fontes/MonteCarlo.cu \
										 Fontes/Macros/MacrosSO.h \
										 Fontes/Parametros.h \
										 Fontes/Ambiente.h \
										 Fontes/Saidas.h \
										 Fontes/Simulacao.h

Fontes/Parametros.o: Fontes/Parametros.cu \
										 Fontes/Macros/0_SIM.h \
										 Fontes/Macros/MacrosSO.h

Fontes/Ambiente.o: Fontes/Ambiente.cu \
									 Fontes/Macros/MacrosGerais.h \
									 Fontes/Macros/MacrosSO.h \
									 Fontes/Uteis/RandPerc.h

Fontes/Saidas.o: Fontes/Saidas.cu \
								 Fontes/Ambiente.h \
								 Fontes/Parametros.h \
								 Fontes/Macros/MacrosGerais.h

Fontes/Seeds.o: Fontes/Seeds.cu \
								Fontes/Uteis/RandPerc.h \
								Fontes/Macros/MacrosParametros.h

Fontes/Uteis/RandPerc.o: Fontes/Uteis/RandPerc.cu

Fontes/Uteis/Timer.o: Fontes/Uteis/Timer.cu

Fontes/Simulacao.o: Fontes/Simulacao.cu \
										Fontes/Seeds.h \
										Fontes/Parametros.h \
										Fontes/Ambiente.h \
										Fontes/Uteis/RandPerc.h \
										Fontes/Saidas.h \
										Fontes/Macros/MacrosSO.h \
										Fontes/Macros/MacrosGerais.h \
                    Fontes/Macros/2_CON_H.h \
                    Fontes/Macros/3_TRA_H.h \
                    Fontes/Macros/4_CON_H.h \
                    Fontes/Macros/3_TRA_M.h \
										Fontes/Macros/4_CON_M.h \
                    Fontes/Macros/5_GER_M.h \
										Fontes/Mosquitos/Mosquitos.h \
										Fontes/Mosquitos/Movimentacao.h \
										Fontes/Mosquitos/Contato.h \
										Fontes/Mosquitos/Transicao.h \
										Fontes/Mosquitos/Controle.h \
										Fontes/Mosquitos/Geracao.h \
										Fontes/Mosquitos/Insercao.h \
										Fontes/Mosquitos/Saidas.h \
										Fontes/Humanos/Humanos.h \
										Fontes/Humanos/Movimentacao.h \
										Fontes/Humanos/Contato.h \
										Fontes/Humanos/Transicao.h \
										Fontes/Humanos/Controle.h \
										Fontes/Humanos/Insercao.h \
										Fontes/Humanos/Saidas.h

Fontes/Mosquitos/Mosquitos.o: Fontes/Mosquitos/Mosquitos.cu \
															Fontes/Macros/MacrosMosquitos.h \
															Fontes/Uteis/RandPerc.h \
															Fontes/Macros/MacrosGerais.h \
															Fontes/Macros/MacrosSO.h \
															Fontes/Macros/0_SIM.h \
															Fontes/Macros/0_INI_M.h \
															Fontes/Macros/3_TRA_M.h \
															Fontes/Parametros.h \
															Fontes/Ambiente.h

Fontes/Mosquitos/Movimentacao.o: Fontes/Mosquitos/Movimentacao.cu \
																 Fontes/Ambiente.h \
																 Fontes/Parametros.h \
																 Fontes/Seeds.h \
																 Fontes/Macros/1_MOV_M.h \
																 Fontes/Mosquitos/Mosquitos.h \
																 Fontes/Macros/MacrosMosquitos.h \
																 Fontes/Humanos/Humanos.h \
																 Fontes/Macros/MacrosHumanos.h \
																 Fontes/Macros/MacrosGerais.h

Fontes/Mosquitos/Contato.o: Fontes/Mosquitos/Contato.cu \
														Fontes/Ambiente.h \
														Fontes/Parametros.h \
														Fontes/Seeds.h \
														Fontes/Macros/2_CON_M.h \
														Fontes/Mosquitos/Mosquitos.h \
														Fontes/Macros/MacrosMosquitos.h \
														Fontes/Macros/MacrosGerais.h

Fontes/Mosquitos/Transicao.o: Fontes/Mosquitos/Transicao.cu \
															Fontes/Ambiente.h \
															Fontes/Parametros.h \
															Fontes/Seeds.h \
															Fontes/Macros/3_TRA_M.h \
															Fontes/Mosquitos/Mosquitos.h \
															Fontes/Macros/MacrosMosquitos.h \
															Fontes/Macros/MacrosGerais.h

Fontes/Mosquitos/Controle.o: Fontes/Mosquitos/Controle.cu \
														 Fontes/Ambiente.h \
														 Fontes/Parametros.h \
														 Fontes/Seeds.h \
														 Fontes/Macros/3_TRA_M.h \
														 Fontes/Macros/4_CON_M.h \
														 Fontes/Mosquitos/Mosquitos.h \
														 Fontes/Macros/MacrosMosquitos.h \
														 Fontes/Macros/MacrosGerais.h

Fontes/Mosquitos/Geracao.o: Fontes/Mosquitos/Geracao.cu \
														Fontes/Parametros.h \
														Fontes/Macros/1_MOV_M.h \
														Fontes/Macros/5_GER_M.h \
														Fontes/Mosquitos/Mosquitos.h \
														Fontes/Macros/MacrosMosquitos.h \
														Fontes/Macros/MacrosGerais.h \
														Fontes/Seeds.h

Fontes/Mosquitos/Insercao.o: Fontes/Mosquitos/Insercao.cu \
													   Fontes/Ambiente.h \
												     Fontes/Parametros.h \
														 Fontes/Seeds.h \
													   Fontes/Mosquitos/Mosquitos.h \
													   Fontes/Macros/MacrosMosquitos.h \
                             Fontes/Macros/0_INI_M.h \
													   Fontes/Macros/3_TRA_M.h \
													   Fontes/Macros/MacrosGerais.h

Fontes/Mosquitos/Saidas.o: Fontes/Mosquitos/Saidas.cu \
													 Fontes/Ambiente.h \
													 Fontes/Saidas.h \
													 Fontes/Mosquitos/Mosquitos.h \
													 Fontes/Macros/MacrosMosquitos.h \
													 Fontes/Macros/MacrosGerais.h

Fontes/Humanos/Humanos.o: Fontes/Humanos/Humanos.cu \
													Fontes/Macros/MacrosHumanos.h \
													Fontes/Uteis/RandPerc.h \
													Fontes/Macros/MacrosGerais.h \
													Fontes/Macros/MacrosSO.h \
													Fontes/Macros/0_INI_H.h \
													Fontes/Parametros.h \
													Fontes/Ambiente.h

Fontes/Humanos/Movimentacao.o: Fontes/Humanos/Movimentacao.cu \
															 Fontes/Ambiente.h \
															 Fontes/Parametros.h \
															 Fontes/Seeds.h \
															 Fontes/Humanos/Humanos.h \
															 Fontes/Macros/MacrosHumanos.h \
															 Fontes/Macros/1_MOV_H.h \
															 Fontes/Macros/MacrosGerais.h

Fontes/Humanos/Contato.o: Fontes/Humanos/Contato.cu \
													Fontes/Ambiente.h \
													Fontes/Parametros.h \
													Fontes/Seeds.h \
													Fontes/Mosquitos/Mosquitos.h \
													Fontes/Macros/MacrosMosquitos.h \
													Fontes/Humanos/Humanos.h \
													Fontes/Macros/MacrosHumanos.h \
													Fontes/Macros/0_INI_H.h \
													Fontes/Macros/2_CON_H.h \
													Fontes/Macros/MacrosGerais.h

Fontes/Humanos/Transicao.o: Fontes/Humanos/Transicao.cu \
														Fontes/Ambiente.h \
														Fontes/Parametros.h \
														Fontes/Seeds.h \
														Fontes/Humanos/Humanos.h \
														Fontes/Macros/MacrosHumanos.h \
														Fontes/Macros/3_TRA_H.h \
														Fontes/Macros/MacrosGerais.h

Fontes/Humanos/Controle.o: Fontes/Humanos/Controle.cu \
													 Fontes/Parametros.h \
													 Fontes/Seeds.h \
													 Fontes/Humanos/Humanos.h \
													 Fontes/Macros/MacrosHumanos.h \
													 Fontes/Macros/4_CON_H.h \
													 Fontes/Macros/MacrosGerais.h

Fontes/Humanos/Insercao.o: Fontes/Humanos/Insercao.cu \
													 Fontes/Ambiente.h \
												   Fontes/Parametros.h \
													 Fontes/Seeds.h \
													 Fontes/Humanos/Humanos.h \
													 Fontes/Macros/MacrosHumanos.h \
													 Fontes/Macros/5_INS_H.h \
													 Fontes/Macros/MacrosGerais.h

Fontes/Humanos/Saidas.o: Fontes/Humanos/Saidas.cu \
												 Fontes/Ambiente.h \
												 Fontes/Saidas.h \
												 Fontes/Humanos/Humanos.h \
												 Fontes/Macros/MacrosHumanos.h \
												 Fontes/Macros/MacrosGerais.h
