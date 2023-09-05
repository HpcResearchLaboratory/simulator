#include "Saidas.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Saidas.h"
#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Paralelizado para diferentes combinações de sexo, saúde e faixa etária.

  Responsável pelo armazenamento e geração das saídas populacionais totais 
  para os agentes humanos, armazenadas no arquivo
  "Saidas/MonteCarlo_{1}/Quantidades_Humanos_Total.csv".
*/
ContPopTH::ContPopTH(Humanos *humanos, Saidas *saidas, int ciclo) {
  this->humanos = humanos->PhumanosDev;
  this->nHumanos = humanos-> nHumanos;
  this->popT = saidas->PpopTHDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopTH.
*/
__host__ __device__
void ContPopTH::operator()(int id) {
  for (int i = 0; i < nHumanos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_SD_H(i) == MORTO) continue;

    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // faixa etária, saúde e sorotipo. 
    int desl = (GET_S_H(i) * N_IDADES * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += (GET_FE_H(i) * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += ((GET_SD_H(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_H(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popT[VEC(ciclo, desl, N_COLS_H)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, saúde e faixa etária.

  Responsável pelo armazenamento e geração das saídas populacionais totais 
  por localidade para os agentes humanos, armazenadas no arquivo
  "Saidas/MonteCarlo_{1}/Quantidades_Humanos_Quadra-{2}.csv", em que "{2}" é um 
  id numérico para uma localidade.
*/
ContPopQH::ContPopQH(Humanos *humanos, Saidas *saidas, int ciclo) {
  this->humanos = humanos->PhumanosDev;
  this->nHumanos = humanos-> nHumanos;
  this->indPopQ = saidas->PindPopQHDev;
  this->popQ = saidas->PpopQHDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopQH.
*/
__host__ __device__
void ContPopQH::operator()(int id) {
  for (int i = 0; i < nHumanos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_SD_H(i) == MORTO) continue;

    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // faixa etária, saúde e sorotipo. 
    int desl = (GET_S_H(i) * N_IDADES * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += (GET_FE_H(i) * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += ((GET_SD_H(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_H(i);
    int q = GET_Q_H(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popQ[indPopQ[q] + VEC(ciclo, desl, N_COLS_H)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, saúde e faixa etária.

  Responsável pelo armazenamento e geração das saídas espaciais para os 
  agentes humanos, armazenadas no arquivo
  "Saidas/MonteCarlo_{1}/Simulacao_{2}/Espacial_Humanos.csv", 
  em que "{2}" é um id numérico para uma simulação individual.
*/
ContEspacialH::ContEspacialH(
  Humanos *humanos, Saidas *saidas, Ambiente *ambiente,
  int nCiclos, int ciclo
) {
  this->humanos = humanos->PhumanosDev;
  this->indHumanos = humanos->PindHumanosDev;
  this->espacial = saidas->PespacialHDev;
  this->ciclo = ciclo;
  this->nCiclos = nCiclos;
  this->pos = ambiente->PposDev;
}

/*
  Operador () da classe ContEspacialH.
*/
__host__ __device__
void ContEspacialH::operator()(int id) {
  int x = pos[id].x, y = pos[id].y;
  int l = pos[id].lote, q = pos[id].quadra;
  int d = VEC(id, ciclo, nCiclos), e;

  for (int i = indHumanos[q]; i < indHumanos[q + 1]; ++i) {
    // Somente agentes vivos nesta posição são representados na saída. 
    if (GET_SD_H(i) == MORTO or GET_L_H(i) != l or
        GET_X_H(i) != x or GET_Y_H(i) != y) continue;

    // Os ícones 3*** são utilizados para representar os agentes. 
    e = 3000;
    e += (N_IDADES - GET_FE_H(i)) * 10;
    // Define a ordem de representação para os estados. 
    switch (GET_SD_H(i)) {
      case IMUNIZADO: e += 5;
        break;
      case INFECTANTE: 
      case HEMORRAGICO: e += 4;
        break;
      case SUSCETIVEL: e += 3;
        break;
      case EXPOSTO: e += 2;
        break;
      case RECUPERADO: e += 1;
        break;
    }
    // Prioridades faixas etárias: Crianças > Jovens > Adultos > Idosos. 
    if (e % 10 > espacial[d] % 10) {
      espacial[d] = e;
    }
  }
}

/*
  Paralelizado para diferentes combinações de sexo, saúde e faixa etária.

  Responsável pelo armazenamento e geração das saídas populacionais totais 
  não acumuladas para os agentes humanos, armazenadas no arquivo
  "Saidas/MonteCarlo_{1}/Quantidades_Humanos_Total.csv".
*/
ContPopNovoTH::ContPopNovoTH(Humanos *humanos, Saidas *saidas, int ciclo) {
  this->humanos = humanos->PhumanosDev;
  this->nHumanos = humanos-> nHumanos;
  this->popNovoT = saidas->PpopNovoTHDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopNovoTH.
*/
__host__ __device__
void ContPopNovoTH::operator()(int id) {
  for (int i = 0; i < nHumanos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_SD_H(i) == MORTO) continue;
    // Somente agentes que mudaram de estado há um ciclo são contabilizados. 
    if (GET_C_H(i) != 1) continue;

    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // faixa etária, saúde e sorotipo. 
    int desl = (GET_S_H(i) * N_IDADES * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += (GET_FE_H(i) * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += ((GET_SD_H(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_H(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popNovoT[VEC(ciclo, desl, N_COLS_H)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, saúde e faixa etária.

  Responsável pelo armazenamento e geração das saídas populacionais totais não
  acumuladas por localidade para os agentes humanos, armazenadas no arquivo
  "Saidas/MonteCarlo_{1}/Quantidades_Humanos_Quadra-{2}.csv", em que "{2}" é um 
  id numérico para uma localidade.
*/
ContPopNovoQH::ContPopNovoQH(Humanos *humanos, Saidas *saidas, int ciclo) {
  this->humanos = humanos->PhumanosDev;
  this->nHumanos = humanos-> nHumanos;
  this->indPopQ = saidas->PindPopQHDev;
  this->popQ = saidas->PpopNovoQHDev;
  this->ciclo = ciclo;
}

/*
  Operador () da classe ContPopNovoQH.
*/
__host__ __device__
void ContPopNovoQH::operator()(int id) {
  for (int i = 0; i < nHumanos; ++i) {
    // Agentes mortos não são contabilizados. 
    if (GET_SD_H(i) == MORTO) continue;
    // Somente agentes que mudaram de estado há um ciclo são contabilizados. 
    if (GET_C_H(i) != 1) continue;

    // O id da coluna em que o agente será contabilizado depende de seu sexo, 
    // faixa etária, saúde e sorotipo. 
    int desl = (GET_S_H(i) * N_IDADES * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += (GET_FE_H(i) * N_ESTADOS_H * (N_SOROTIPOS + 1));
    desl += ((GET_SD_H(i) - 1) * (N_SOROTIPOS + 1));
    desl += GET_ST_H(i);
    int q = GET_Q_H(i);

    // Somente contabiliza o agente em uma coluna da saída. 
    if (desl == id) popQ[indPopQ[q] + VEC(ciclo, desl, N_COLS_H)]++;
  }
}

/*
  Paralelizado para diferentes combinações de sexo, saúde e faixa etária.

  Responsável pelo armazenamento e geração das saídas espaciais não acumuladas
  para os agentes humano, armazenadas no arquivo
  "Saidas/MonteCarlo_{1}/Simulacao_{2}/Espacial_Humanos.csv", 
  em que "{2}" é um id numérico para uma simulação individual.
*/
ContEspacialNovoH::ContEspacialNovoH(
  Humanos *humanos, Saidas *saidas, Ambiente *ambiente,
  int nCiclos, int ciclo
) {
  this->humanos = humanos->PhumanosDev;
  this->indHumanos = humanos->PindHumanosDev;
  this->espacial = saidas->PespacialNovoHDev;
  this->ciclo = ciclo;
  this->nCiclos = nCiclos;
  this->pos = ambiente->PposDev;
}

/*
  Operador () da classe ContEspacialNovoH.
*/
__host__ __device__
void ContEspacialNovoH::operator()(int id) {
  int x = pos[id].x, y = pos[id].y;
  int l = pos[id].lote, q = pos[id].quadra;
  int d = VEC(id, ciclo, nCiclos), e;

  for (int i = indHumanos[q]; i < indHumanos[q + 1]; ++i) {
    // Somente agentes vivos, que mudaram de estado há um ciclo e que estão 
    // nesta posição são representados na saída. 
    if (GET_SD_H(i) == MORTO or GET_L_H(i) != l or
        GET_X_H(i) != x or GET_Y_H(i) != y or GET_C_H(i) != 1) continue;

    // Os ícones 3*** são utilizados para representar os agentes. 
    e = 3000;
    e += (N_IDADES - GET_FE_H(i)) * 10;
    // Define a ordem de representação para os estados. 
    switch (GET_SD_H(i)) {
      case IMUNIZADO: e += 5;
        break;
      case INFECTANTE: 
      case HEMORRAGICO: e += 4;
        break;
      case SUSCETIVEL: e += 3;
        break;
      case EXPOSTO: e += 2;
        break;
      case RECUPERADO: e += 1;
        break;
    }
    // Prioridades faixas etárias: Crianças > Jovens > Adultos > Idosos. 
    if (e % 10 > espacial[d] % 10) {
      espacial[d] = e;
    }
  }
}
