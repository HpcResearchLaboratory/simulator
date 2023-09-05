#include "Saidas.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Saidas.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Paralelizado para diferentes combinações de sexo, fase e saúde.
  
  Responsável pelo armazenamento e geração das saídas populacionais totais 
  para os agentes mosquitos, visão Dengue. A variável "popT" armazena os resultados 
  gerados pelo método "operator()". Esta classe é responsável pela geração dos 
  resultados armazenados no arquivo 
  "Saidas/MonteCarlo_{1}/Quantidades_Mosquitos_Dengue_Total.csv". 
*/
ContPopTMD::ContPopTMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->nMosquitos = mosquitos->nMosquitos;
  this->popT = saidas->PpopTMDDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopTMD.
*/
__host__ __device__
void ContPopTMD::operator()(int id) {
  for (int i = 0; i < nMosquitos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_VD_M(i) == MORTO) continue;
    
    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // fase, saúde Dengue e sorotipo. 
    int desl = (GET_S_M(i) * N_FASES * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += (GET_FS_M(i) * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += ((GET_SD_M(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_M(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popT[VEC(ciclo, desl, N_COLS_MD)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, fase e saúde.
  
  Responsável pelo armazenamento e geração das saídas populacionais por 
  quadras para os agentes mosquitos, visão Dengue. A variável "popQ" armazena os 
  resultados gerados pelo método "operator()". A variável "indPopQ" armazena os 
  índices utilizados para indexar "popQ" por meio dos ids das quadras. Esta 
  classes é responsável pela geração dos resultados armazenados nos arquivos 
  "Saidas/MonteCarlo_{1}/Quantidades_Mosquitos_Dengue_Quadra-{2}.csv", em que 
  "{2}" é um id numérico para uma quadra. 
*/
ContPopQMD::ContPopQMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->nMosquitos = mosquitos->nMosquitos;
  this->indPopQ = saidas->PindPopQMDDev;
  this->popQ = saidas->PpopQMDDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopQMD.
*/
__host__ __device__
void ContPopQMD::operator()(int id) {
  for (int i = 0; i < nMosquitos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_VD_M(i) == MORTO) continue;
    
    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // fase, saúde Dengue e sorotipo. 
    int desl = (GET_S_M(i) * N_FASES * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += (GET_FS_M(i) * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += ((GET_SD_M(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_M(i);
    int q = GET_Q_M(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popQ[indPopQ[q] + VEC(ciclo, desl, N_COLS_MD)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, fase e saúde.
  
  Responsável pelo armazenamento e geração das saídas espaciais para os 
  agentes mosquitos, visão Dengue. A variável "espacial" armazena os resultados 
  gerados pelo método "operator()". Esta classe é responsável pela geração dos 
  resultados armazenados no arquivo 
  "Saidas/MonteCarlo_{1}/Simulacao_{2}/Espacial_Mosquitos_Dengue.csv", em que 
  "{2}" é um id numérico para uma simulação individual. 
*/
ContEspacialMD::ContEspacialMD(
  Mosquitos *mosquitos, Saidas *saidas, Ambiente *ambiente,
  int nCiclos, int ciclo
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->espacial = saidas->PespacialMDDev;
  this->ciclo = ciclo;
  this->nCiclos = nCiclos;
  this->pos = ambiente->PposDev;
}

/*
  Operador () da classe ContEspacialMD.
*/
__host__ __device__
void ContEspacialMD::operator()(int id) {
  int x = pos[id].x, y = pos[id].y;
  int l = pos[id].lote, q = pos[id].quadra;
  int d = VEC(id, ciclo, nCiclos), e = 0, sd = 0, fs = 0;

  for (int i = indMosquitos[q]; i < indMosquitos[q + 1]; ++i) {
    // Somente agentes vivos nesta posição são representados na saída. 
    if (GET_VD_M(i) == MORTO or GET_L_M(i) != l or
        GET_X_M(i) != x or GET_Y_M(i) != y) continue;
  
    // Os ícones 4*** são utilizados para representar os agentes. 
    e = 4000;
    if (GET_FS_M(i) == ATIVA or GET_FS_M(i) == DECADENTE) {
      // Define a ordem de representação para os estados da Dengue. 
      switch (GET_SD_M(i)) {
        case INFECTANTE: sd = max(30, sd);
          break;
        case SUSCETIVEL: sd = max(20, sd);
          break;
        case EXPOSTO: sd = max(10, sd);
          break;
      }
    } else {
      // Se contém um ovo o final do identificador do ícone é 1. 
      fs = 1;
    }
  }
  espacial[d] = e + sd + fs;
}

/*
  Paralelizado para diferentes combinações de sexo, fase e saúde.
  
  Responsável pelo armazenamento e geração das saídas populacionais totais 
  para os agentes mosquitos, visão Wolbachia. A variável "popT" armazena os 
  resultados gerados pelo método "operator()". Esta classe é responsável pela 
  geração dos resultados armazenados no arquivo 
  "Saidas/MonteCarlo_{1}/Quantidades_Mosquitos_Wolbachia_Total.csv". 
*/
ContPopTMW::ContPopTMW(Mosquitos *mosquitos, Saidas *saidas, int ciclo) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->nMosquitos = mosquitos->nMosquitos;
  this->popT = saidas->PpopTMWDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopTMW.
*/
__host__ __device__
void ContPopTMW::operator()(int id) {
  for (int i = 0; i < nMosquitos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_VD_M(i) == MORTO) continue;
    
    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // fase e saúde Wolbachia. 
    int desl = (GET_S_M(i) * N_FASES * N_ESTADOS_MW);
    desl += (GET_FS_M(i) * N_ESTADOS_MW);
    desl += GET_SW_M(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popT[VEC(ciclo, desl, N_COLS_MW)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, fase e saúde.
  
  Responsável pelo armazenamento e geração das saídas populacionais por 
  quadras para os agentes mosquitos, visão Wolbachia. A variável "popQ" armazena 
  os resultados gerados pelo método "operator()". A variável "indPopQ" armazena 
  os índices utilizados para indexar "popQ" por meio dos ids das quadras. Esta 
  classe é responsável pela geração dos resultados armazenados nos arquivos 
  "Saidas/MonteCarlo_{1}/Quantidades_Mosquitos_Wolbachia_Quadra-{2}.csv", em que 
  "{2}" é um id numérico para uma quadra. 
*/
ContPopQMW::ContPopQMW(Mosquitos *mosquitos, Saidas *saidas, int ciclo) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->nMosquitos = mosquitos->nMosquitos;
  this->indPopQ = saidas->PindPopQMWDev;
  this->popQ = saidas->PpopQMWDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopQMW.
*/
__host__ __device__
void ContPopQMW::operator()(int id) {
  for (int i = 0; i < nMosquitos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_VD_M(i) == MORTO) continue;
    
    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // fase e saúde Wolbachia. 
    int desl = (GET_S_M(i) * N_FASES * N_ESTADOS_MW);
    desl += (GET_FS_M(i) * N_ESTADOS_MW);
    desl += GET_SW_M(i);
    int q = GET_Q_M(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popQ[indPopQ[q] + VEC(ciclo, desl, N_COLS_MW)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, fase e saúde.
  
  Responsável pelo armazenamento e geração das saídas populacionais não 
  acumuladas totais para os agentes mosquitos, visão Dengue. A variável "popNovoT" 
  armazena os resultados gerados pelo método "operator()". Esta classe é 
  responsável pela geração dos resultados armazenados no arquivo 
  "Saidas/MonteCarlo_{1}/Quantidades_Mosquitos_Dengue_Novo_Total.csv". 
*/
ContPopNovoTMD::ContPopNovoTMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->nMosquitos = mosquitos->nMosquitos;
  this->popNovoT = saidas->PpopNovoTMDDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopNovoTMD.
*/
__host__ __device__
void ContPopNovoTMD::operator()(int id) {
  for (int i = 0; i < nMosquitos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_VD_M(i) == MORTO) continue;
    // Agentes machos não são contabilizados.
    if (GET_S_M(i) == MACHO) continue;
    // Fêmeas não acasaladas não são contabilizadas.
    if (GET_TA_M(i) == NENHUM) continue;
    // Somente agentes infectados são contabilizados.
    if (GET_SD_M(i) != INFECTANTE) continue;
    // Somente agentes com o contador = 0 são contabilizados. 
    if (GET_C_M(i) != 0) continue;

    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // fase, saúde Dengue e sorotipo. 
    int desl = (GET_S_M(i) * N_FASES * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += (GET_FS_M(i) * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += ((GET_SD_M(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_M(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popNovoT[VEC(ciclo, desl, N_COLS_MD)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, fase e saúde.
  
  Responsável pelo armazenamento e geração das saídas populacionais não 
  acumuladas por quadras para os agentes mosquitos, visão Dengue. A variável 
  "popQ" armazena os resultados gerados pelo método "operator()". Esta classe 
  é responsável pela geração dos resultados armazenados nos arquivos 
  "Saidas/MonteCarlo_{1}/Quantidades_Mosquitos_Dengue_Novo_Quadra-{2}.csv", em 
  que "{2}" é um id numérico para uma quadra. 
*/
ContPopNovoQMD::ContPopNovoQMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->nMosquitos = mosquitos->nMosquitos;
  this->indPopQ = saidas->PindPopQMDDev;
  this->popQ = saidas->PpopNovoQMDDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopNovoQMD.
*/
__host__ __device__
void ContPopNovoQMD::operator()(int id) {
  for (int i = 0; i < nMosquitos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_VD_M(i) == MORTO) continue;
    // Somente agentes que mudaram de estado há um ciclo são contabilizados. 
    if (GET_C_M(i) != 1) continue;
    
    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // fase, saúde Dengue e sorotipo. 
    int desl = (GET_S_M(i) * N_FASES * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += (GET_FS_M(i) * N_ESTADOS_MD * (N_SOROTIPOS + 1));
    desl += ((GET_SD_M(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_M(i);
    int q = GET_Q_M(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popQ[indPopQ[q] + VEC(ciclo, desl, N_COLS_MD)]++;
  }
}