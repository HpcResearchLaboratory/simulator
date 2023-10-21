#ifndef __AMBIENTE__
#define __AMBIENTE__

#include <fstream>
#include <iostream>
#include <limits>
#include <string>
#include <tuple>

#include <thrust/device_vector.h>

using std::cerr;
using std::endl;
using std::fstream;
using std::ifstream;
using std::numeric_limits;
using std::streamsize;
using std::string;

template <class T> using DVector = thrust::device_vector<T>;

using thrust::raw_pointer_cast;

/*
  Estrutura utilizada para armazenar uma posição do ambiente.
*/
struct Posicao {

  int x, y, lote, quadra;
};

/*
  Estrutura utilizada para armazenar uma vizinhança do ambiente.
*/
struct Vizinhanca {

  int xOrigem, yOrigem, xDestino, yDestino, loteDestino, quadraDestino;
};

/*
  Estrutura utilizada para armazenar um registro lido do arquivo
  "Ambiente/DistribuicaoHumanos.csv", em que:

  "q": localidade do humano;
  "l": quadra do humano;
  "x": latitude do humano;
  "y": longitude do humano;
  "s": sexo do humano;
  "fe": faixa etária do humano;
  "sd": saude Dengue do humano;
  "st": sorotipo atual do humano;
  "cic": ciclo de entrada do humano na simulação;
*/
struct Caso {

  int q, l, x, y, s, fe, sd, st, cic;
};

/*
  Estrutura utilizada para armazenar um registro lido do arquivo
  "Ambiente/DistribuicaoMosquitos.csv", em que:

  "q": localidade em que a população de mosquitos serão inseridos;
  "quant": quantidade de mosquitos da população;
  "s": sexo dos mosquitos da população;
  "fs": fase dos mosquitos da população;
  "st": sorotipo dos mosquitos infectados da população;
  "cic": ciclo de entrada da população de mosquitos no simulação;
  "pmin": percentual mínimo de infectados na população;
  "pmax": percentual máximo de infectados na população;
*/
struct PopMosquitos {

  int q, quant, s, fs, st, cic;
  double pmin, pmax;
};

/*
  Estrutura utilizada para armazenar uma fronteira do ambiente.

  Como a quadra e a localidade de origem são utilizados como índices ao acesso à
  estrutura, eles não são armazenados para evitar redundância de dados.
*/
struct Fronteira {

  int xDestino, yDestino, loteDestino;
};

/*
  Estrutura utilizada para armazenar uma esquina do ambiente.

  O atributo "lote" refere-se ao id da rua que esta posição de esquina pertence.
*/
struct Esquina {

  int x, y, lote;
};

/*
  Estrutura utilizada para armazenar um registro relativo aos controles
  populacionais sobre os agentes mosquitos.
*/
struct Controle {

  char tipoControle;
  int quadra, ciclo;
  double taxaMinMecanico, taxaMaxMecanico, taxaMinQuimico, taxaMaxQuimico,
      efeRes;
};

/*
  Estrutura utilizada para armazenar um registro relativo aos humanos vacinados.
*/
struct Vacinado {

  int ciclo, quadra, lote, x, y, sexo, faixaEtaria, doses;
  bool processado;
};

struct Climatico {

  double txMinNaoAlados, txMaxNaoAlados, txMinAlados, txMaxAlados;
};

/*
  Classe que armazena todos os dados relacionados ao ambiente de simulação.
*/
class Ambiente {

public:
  string entradaMC;
  streamsize sMax = numeric_limits<streamsize>::max();
  fstream arquivo;

  // Dados em CPU.

  // Quadras, Lotes e indexação
  int nQuadras;
  int *nLotes;
  int sizeNLotes;
  int *indQuadras;
  int sizeIndQuadras;

  // Posições
  Posicao *pos;
  int *indPos, sizeIndPos, sizePos, *indPosReg, sizeIndPosReg;

  // Vizinhanças
  Vizinhanca *viz;
  int *indViz, sizeIndViz, sizeViz;

  // Fronteiras
  int *indFron, sizeIndFron, sizeFron, *indEsq, sizeIndEsq;
  Fronteira *fron;

  // Esquinas
  int sizeEsq, *indCEsq, sizeIndCEsq, sizeCEsq;
  Esquina *esq, *cEsq;

  // Rotas, Trajetos e Períodos
  int nRotas, *indRotas, sizeIndRotas, *rotas, sizeRotas;
  int nTraj, *indTraj, sizeIndTraj, *indPeri, sizeIndPeri;
  int *peri, sizePeri, *indTrajFE, sizeindTrajFE;

  // Vacinação
  int sizeQuadVac, *quadVac, sizeFEVac, *fEVac;
  int sizePerVac, *perVac, sizeCicVac, *cicVac;

  // Controles artificiais
  int sizeConBio, *conBio;
  int sizeContr;
  Controle *contr;
  int sizeConAmb, *conAmb, sizePontEst, *pontEst;
  int sizeIndContrPontos, *indContrPontos;
  int sizeContrPontos;
  Posicao *contrPontos;
  int sizeIndRaios, *indRaios;
  int sizeRaios;
  Posicao *raios;

  // Distribuição de humanos assintomáticos
  int sizeDistHumanos, sizeDistMosquitos;
  Caso *distHumanos;

  // Distribuição de mosquitos
  PopMosquitos *distMosquitos;

  // Complemento
  int sizeComp;
  double *comp;

  // Inserção de vacinados
  int sizeVacs;
  Vacinado *vacs;

  // Vetor climático
  int sizeCli;
  Climatico *cli;

  // Casos observados
  int sizeCasos, *casos;

  // Focos
  int *focos, *indFocos, *capFocos, sizeFocos, sizeIndFocos;

  // Controle Dinâmico
  int nLira, sizeContrLira, *contrLira;

  // LIRAa
  int *cicloLIRAa;

  // Dados em GPU.
  DVector<int> *nLotesDev, *indQuadrasDev, *indVizDev;
  DVector<Vizinhanca> *vizDev;
  DVector<int> *indPosDev, *indPosRegDev, *indFronDev;
  DVector<Fronteira> *fronDev;
  DVector<Posicao> *posDev;
  DVector<int> *indEsqDev, *indCEsqDev;
  DVector<Esquina> *esqDev, *cEsqDev;
  DVector<int> *indRotasDev, *rotasDev, *indTrajDev;
  DVector<int> *indPeriDev, *periDev, *indTrajFEDev;
  DVector<int> *quadVacDev, *fEVacDev, *perVacDev, *cicVacDev;
  DVector<int> *conBioDev, *conAmbDev, *pontEstDev;
  DVector<Controle> *contrDev;
  DVector<int> *indContrPontosDev;
  DVector<Posicao> *contrPontosDev;
  DVector<int> *indRaiosDev;
  DVector<Posicao> *raiosDev;
  DVector<Caso> *distHumanosDev;
  DVector<PopMosquitos> *distMosquitosDev;
  DVector<double> *compDev;
  DVector<Vacinado> *vacsDev;
  DVector<Climatico> *cliDev;
  DVector<int> *casosDev;
  DVector<int> *indFocosDev, *focosDev, *capFocosDev;
  DVector<int> *contrLiraDev;

  DVector<int> *cicloLIRAaDev;

  // Ponteiros em CPU para os dados em GPU.
  int *PnLotesDev, *PindPosRegDev, *PindQuadrasDev, *PindVizDev;
  Posicao *PposDev;
  int *PindFronDev, *PindEsqDev;
  Fronteira *PfronDev;
  Vizinhanca *PvizDev;
  int *PindCEsqDev, *PindRotasDev;
  Esquina *PesqDev, *PcEsqDev;
  int *ProtasDev, *PindPosDev, *PindTrajDev;
  int *PindPeriDev, *PperiDev, *PindTrajFEDev;
  int *PquadVacDev, *PfEVacDev, *PperVacDev, *PcicVacDev;
  int *PconBioDev, *PconAmbDev, *PpontEstDev;
  Controle *PcontrDev;
  int *PindContrPontosDev;
  Posicao *PcontrPontosDev;
  int *PindRaiosDev;
  Posicao *PraiosDev;
  Caso *PdistHumanosDev;
  PopMosquitos *PdistMosquitosDev;
  double *PcompDev;
  Vacinado *PvacsDev;
  Climatico *PcliDev;
  int *PcasosDev;
  int *PindFocosDev;
  int *PcapFocosDev;
  int *PfocosDev;
  int *PcontrLiraDev;

  int *PcicloLIRAaDev;

  Ambiente(string entradaMC);
  int getMemoriaGPU();
  ~Ambiente();

private:
  void toGPU();
  void lerVetoresAmbientais();
  void lerVetoresMovimentacao();
  void lerVetoresControles();
  void lerVetoresClimaticos();
  void lerContr();
  void lerContrPontos();
  void lerRaios();
  void lerVacinados();
  template <class T> T *lerVetor(int n);
  std::tuple<int, int *> lerControle();
  void lerQuadrasLotes();
  void lerVizinhancas();
  void lerPosicoes();
  void lerFronteiras();
  void lerEsquinas();
  void lerCentrosEsquinas();
  void lerRotas();
  void lerTrajetos();
  void lerPeriodos();
  void lerTrajetosFaixaEtaria();
  void lerArquivoDistribuicaoHumanos();
  void lerArquivoDistribuicaoMosquitos();
  void lerFocos();
  void lerContrLira();

  void lerCiclosLIRAa();
};

#endif
