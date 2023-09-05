#include "Ambiente.h"
#include "Fontes/Macros/MacrosGerais.h"
#include "Fontes/Macros/MacrosSO.h"
#include "Fontes/Uteis/RandPerc.h"

using std::cerr;
using std::endl;
using std::fstream;
using std::ifstream;
using std::make_tuple;
using std::numeric_limits;
using std::string;
using std::streamsize;
using thrust::raw_pointer_cast;
using std::tie;

/*
  Construtor da classe Ambiente.

  O caminho para a pasta de entrada contendo os arquivos da simulação
  Monte Carlo é passado como argumento ao método, por meio do parâmetro
  "entradaMC". O valor desta váriavel segue o padrão "Entradas/MonteCarlo_{1}/",
  em que "{1}" designa o id numérico da simulação Monte Carlo.

  Este método realiza a leitura dos arquivos contidos na pasta "Ambiente",
  especificamente os arquivos "0-AMB.csv", "1-MOV.csv", "2-CON.csv",
  "DistribuicaoHumanos.csv" e "DistribuicaoMosquitos.csv". Os métodos
  "lerVetoresAmbientais", "lerVetoresMovimentacao", "lerVetoresControles",
  "lerArquivoDistribuicaoHumanos" e "lerArquivoDistribuicaoMosquitos" realizam
  a leitura dos respectivos dados às respectivas variáveis.

  Após a leitura dos arquivos os dados obtidos são copiados à GPU pelo
  método "toGPU".
*/
Ambiente::Ambiente(string entradaMC) {
  this->entradaMC = entradaMC;
  lerVetoresAmbientais();
  lerVetoresMovimentacao();
  lerVetoresControles();
  lerVetoresClimaticos();
  lerArquivoDistribuicaoHumanos();
  lerArquivoDistribuicaoMosquitos();
  toGPU();
}

/*
  Método responsável pela obtenção do consumo de memória da classe Ambiente.
*/
int Ambiente::getMemoriaGPU() {
  int totMem = 0;
  totMem += (sizeNLotes * sizeof(int));
  totMem += (sizeIndQuadras * sizeof(int));
  totMem += (sizeIndViz * sizeof(int));
  totMem += (sizeViz * sizeof(Vizinhanca));
  totMem += (sizeIndPos * sizeof(int));
  totMem += (sizePos * sizeof(Posicao));
  totMem += (sizeIndPosReg * sizeof(int));
  totMem += (sizeIndFron * sizeof(int));
  totMem += (sizeFron * sizeof(Fronteira));
  totMem += (sizeIndEsq * sizeof(int));
  totMem += (sizeEsq * sizeof(Esquina));
  totMem += (sizeIndCEsq * sizeof(int));
  totMem += (sizeCEsq * sizeof(Esquina));
  totMem += (sizeIndRotas * sizeof(int));
  totMem += (sizeRotas * sizeof(int));
  totMem += (sizeIndTraj * sizeof(int));
  totMem += (sizeIndPeri * sizeof(int));
  totMem += (sizePeri * sizeof(int));
  totMem += (sizeindTrajFE * sizeof(int));
  totMem += (sizeQuadVac * sizeof(int));
  totMem += (sizeFEVac * sizeof(int));
  totMem += (sizePerVac * sizeof(int));
  totMem += (sizeCicVac * sizeof(int));
  totMem += (sizeContr * sizeof(Controle));
  totMem += (sizeIndContrPontos * sizeof(int));
  totMem += (sizeContrPontos * sizeof(Posicao));
  totMem += (sizeIndRaios * sizeof(int));
  totMem += (sizeRaios * sizeof(Posicao));
  totMem += (sizeConBio * sizeof(int));
  totMem += (sizeConAmb * sizeof(int));
  totMem += (sizePontEst * sizeof(int));
  totMem += (sizeDistHumanos * sizeof(Caso));
  totMem += (sizeDistMosquitos * sizeof(PopMosquitos));
  totMem += (sizeComp * sizeof(double));
  totMem += (sizeVacs * sizeof(Vacinado));
  totMem += (sizeCli * sizeof(Climatico));
  totMem += (sizeCasos * sizeof(int));
  totMem += (sizeIndFocos * sizeof(int));
  totMem += (sizeFocos * sizeof(int)); // focos
  totMem += (sizeFocos * sizeof(int)); // capFocos
  totMem += (sizeContrLira * sizeof(int));
  return totMem;
}

/*
  Destrutor da classe Ambiente.

  Neste método são desalocados da memória principal e da GPU
  os dados da classe Ambiente.
*/
Ambiente::~Ambiente() {
  delete[](nLotes); delete[](indQuadras); delete[](indViz); delete[](viz);
  delete[](indPos); delete[](pos); delete[](indPosReg);
  delete[](indFron); delete[](fron);
  delete[](indEsq); delete[](esq); delete[](indCEsq); delete[](cEsq);
  delete[](indRotas); delete[](rotas); delete[](indTraj);
  delete[](indPeri); delete[](peri); delete[](indTrajFE);
  delete[](quadVac); delete[](fEVac); delete[](perVac); delete[](cicVac);
  delete[](contr); delete[](conBio); delete[](indContrPontos);
  delete[](contrPontos); delete[](indRaios); delete[](raios);
  delete[](conAmb); delete[](pontEst); delete[](distHumanos);
  delete[](distMosquitos); delete[](comp); delete[](vacs); delete[](cli);
  delete[](casos); delete[](indFocos); delete[](focos); delete[](capFocos);
  delete[](contrLira);

  delete(nLotesDev); delete(indQuadrasDev);
  delete(indVizDev); delete(vizDev); delete(indPosDev);
  delete(posDev); delete(indPosRegDev);
  delete(indFronDev); delete(fronDev);
  delete(indEsqDev); delete(esqDev); delete(indCEsqDev);
  delete(cEsqDev); delete(indRotasDev); delete(rotasDev);
  delete(indTrajDev); delete(indPeriDev);
  delete(periDev); delete(indTrajFEDev); delete(quadVacDev);
  delete(indContrPontosDev); delete(contrPontosDev);
  delete(indRaiosDev); delete(raiosDev);
  delete(fEVacDev); delete(perVacDev); delete(cicVacDev); delete(contrDev);
  delete(conBioDev); delete(conAmbDev); delete(pontEstDev);
  delete(distHumanosDev); delete(distMosquitosDev); delete(compDev);
  delete(vacsDev); delete(cliDev); delete(casosDev);
  delete(indFocosDev); delete(focosDev); delete(capFocosDev);
  delete(contrLiraDev);
}

/*
  Método responsável pela cópia dos dados da classe Ambiente para a GPU.

  Primeiramente são instanciadas classes "DVector", que armazenam seus
  dados na memória da GPU. No construtor desta classe são passados dois
  ponteiros, que indicam o início e final dos dados em CPU que devem ser
  copiados para a GPU.

  Por fim são obtidos ponteiros diretos aos dados armazenados pelas classes
  "DVector" por meio da função "raw_pointer_cast", com o objetivo de facilitar
  o acesso aos dados.
*/
void Ambiente::toGPU() {
  nLotesDev = new DVector<int>(nLotes, nLotes + sizeNLotes);
  indQuadrasDev = new DVector<int>(indQuadras, indQuadras + sizeIndQuadras);
  indVizDev = new DVector<int>(indViz, indViz + sizeIndViz);
  vizDev = new DVector<Vizinhanca>(viz, viz + sizeViz);
  indPosDev = new DVector<int>(indPos, indPos + sizeIndPos);
  posDev = new DVector<Posicao>(pos, pos + sizePos);
  indPosRegDev = new DVector<int>(indPosReg, indPosReg + sizeIndPosReg);
  indFronDev = new DVector<int>(indFron, indFron + sizeIndFron);
  fronDev = new DVector<Fronteira>(fron, fron + sizeFron);
  indEsqDev = new DVector<int>(indEsq, indEsq + sizeIndEsq);
  esqDev = new DVector<Esquina>(esq, esq + sizeEsq);
  indCEsqDev = new DVector<int>(indCEsq, indCEsq + sizeIndCEsq);
  cEsqDev = new DVector<Esquina>(cEsq, cEsq + sizeCEsq);
  indRotasDev = new DVector<int>(indRotas, indRotas + sizeIndRotas);
  rotasDev = new DVector<int>(rotas, rotas + sizeRotas);
  indTrajDev = new DVector<int>(indTraj, indTraj + sizeIndTraj);
  indPeriDev = new DVector<int>(indPeri, indPeri + sizeIndPeri);
  periDev = new DVector<int>(peri, peri + sizePeri);
  indTrajFEDev = new DVector<int>(indTrajFE, indTrajFE + sizeindTrajFE);
  quadVacDev = new DVector<int>(quadVac, quadVac + sizeQuadVac);
  fEVacDev = new DVector<int>(fEVac, fEVac + sizeFEVac);
  perVacDev = new DVector<int>(perVac, perVac + sizePerVac);
  cicVacDev = new DVector<int>(cicVac, cicVac + sizeCicVac);
  contrDev = new DVector<Controle>(contr, contr + sizeContr);
  indContrPontosDev = new DVector<int>(indContrPontos, indContrPontos + sizeIndContrPontos);
  contrPontosDev = new DVector<Posicao>(contrPontos, contrPontos + sizeContrPontos);
  indRaiosDev = new DVector<int>(indRaios, indRaios + sizeIndRaios);
  raiosDev = new DVector<Posicao>(raios, raios + sizeRaios);
  conBioDev = new DVector<int>(conBio, conBio + sizeConBio);
  conAmbDev = new DVector<int>(conAmb, conAmb + sizeConAmb);
  pontEstDev = new DVector<int>(pontEst, pontEst + sizePontEst);
  distHumanosDev = new DVector<Caso>(distHumanos, distHumanos + sizeDistHumanos);
  distMosquitosDev = new DVector<PopMosquitos>(distMosquitos,
                                         distMosquitos + sizeDistMosquitos);
  compDev = new DVector<double>(comp, comp + sizeComp);
  vacsDev = new DVector<Vacinado>(vacs, vacs + sizeVacs);
  cliDev = new DVector<Climatico>(cli, cli + sizeCli);
  casosDev = new DVector<int>(casos, casos + sizeCasos);
  indFocosDev = new DVector<int>(indFocos, indFocos + sizeIndFocos);
  focosDev = new DVector<int>(focos, focos + sizeFocos);
  capFocosDev = new DVector<int>(capFocos, capFocos + sizeFocos);
  contrLiraDev = new DVector<int>(contrLira, contrLira + sizeContrLira);

  PnLotesDev = raw_pointer_cast(nLotesDev->data());
  PposDev = raw_pointer_cast(posDev->data());
  PindPosRegDev = raw_pointer_cast(indPosRegDev->data());
  PindQuadrasDev = raw_pointer_cast(indQuadrasDev->data());
  PindVizDev = raw_pointer_cast(indVizDev->data());
  PvizDev = raw_pointer_cast(vizDev->data());
  PindFronDev = raw_pointer_cast(indFronDev->data());
  PfronDev = raw_pointer_cast(fronDev->data());
  PindEsqDev = raw_pointer_cast(indEsqDev->data());
  PesqDev = raw_pointer_cast(esqDev->data());
  PindCEsqDev = raw_pointer_cast(indCEsqDev->data());
  PcEsqDev = raw_pointer_cast(cEsqDev->data());
  PindRotasDev = raw_pointer_cast(indRotasDev->data());
  ProtasDev = raw_pointer_cast(rotasDev->data());
  PindPosDev = raw_pointer_cast(indPosDev->data());
  PindTrajDev = raw_pointer_cast(indTrajDev->data());
  PindPeriDev = raw_pointer_cast(indPeriDev->data());
  PperiDev = raw_pointer_cast(periDev->data());
  PindTrajFEDev = raw_pointer_cast(indTrajFEDev->data());
  PquadVacDev = raw_pointer_cast(quadVacDev->data());
  PfEVacDev = raw_pointer_cast(fEVacDev->data());
  PperVacDev = raw_pointer_cast(perVacDev->data());
  PcicVacDev = raw_pointer_cast(cicVacDev->data());
  PcontrDev = raw_pointer_cast(contrDev->data());
  PindContrPontosDev = raw_pointer_cast(indContrPontosDev->data());
  PcontrPontosDev = raw_pointer_cast(contrPontosDev->data());
  PindRaiosDev = raw_pointer_cast(indRaiosDev->data());
  PraiosDev = raw_pointer_cast(raiosDev->data());
  PconBioDev = raw_pointer_cast(conBioDev->data());
  PconAmbDev = raw_pointer_cast(conAmbDev->data());
  PpontEstDev = raw_pointer_cast(pontEstDev->data());
  PdistHumanosDev = raw_pointer_cast(distHumanosDev->data());
  PdistMosquitosDev = raw_pointer_cast(distMosquitosDev->data());
  PcompDev = raw_pointer_cast(compDev->data());
  PvacsDev = raw_pointer_cast(vacsDev->data());
  PcliDev = raw_pointer_cast(cliDev->data());
  PcasosDev = raw_pointer_cast(casosDev->data());
  PindFocosDev = raw_pointer_cast(indFocosDev->data());
  PfocosDev = raw_pointer_cast(focosDev->data());
  PcapFocosDev = raw_pointer_cast(capFocosDev->data());
  PcontrLiraDev = raw_pointer_cast(contrLiraDev->data());
}

/*
  Método responsável pela leitura do arquivo "Ambiente/0-AMB.csv".

  Cada linha do arquivo "Ambiente/0-AMB.csv" corresponde a um vetor de dados
  específico, que é necessário à simulação (desconsiderando linhas em branco ou
  com comentários). Os dados neste arquivo são armazenados da seguinte maneira:

  Linha 1: Vetor com informações sobre localidades e quadras;
  Linha 2: Vetor com informações sobre vizinhanças;
  Linha 3: Vetor com informações sobre as posições do ambiente;
  Linha 4: Vetor com informações sobre as fronteiras do ambiente;
  Linha 5: Vetor com informações sobre as esquinas do ambiente;
  Linha 6: Vetor com informações sobre as posições de centros das esquinas.

  Os métodos "lerQuadrasLotes", "lerVizinhancas", "lerPosicoes",
  "lerFronteiras", "lerEsquinas" e "lerCentrosEsquinas" são responsáveis pela
  leitura dos dados correspondentes, na ordem que foram apresentadas
  anteriormente. Efetivamente, cada método realiza a leitura de uma linha de
  dados do arquivo.
*/
void Ambiente::lerVetoresAmbientais() {
  string entrada = entradaMC;
  entrada += string("Ambiente");
  entrada += SEP;
  entrada += string("0-AMB.csv");

  arquivo.open(entrada);

  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << entrada;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  arquivo.ignore(sMax, '\n');
  lerQuadrasLotes();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerVizinhancas();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerPosicoes();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerFronteiras();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerEsquinas();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerCentrosEsquinas();

  arquivo.close();
}

/*
  Método responsável pela leitura do arquivo "Ambiente/1-MOV.csv".

  Cada linha do arquivo "Ambiente/1-MOV.csv" corresponde a um vetor de dados
  específico, que é necessário à simulação (desconsiderando linhas em branco ou
  com comentários). Os dados neste arquivo são armazenados da seguinte maneira:

  Linha 1: Vetor com informações sobre as rotas;
  Linha 2: Vetor com informações sobre os trajetos;
  Linha 3: Vetor com informações sobre os períodos dos trajetos;
  Linha 4: Vetor com os índices dos trajetos por faixas etárias.

  Os métodos "lerRotas", "lerTrajetos", "lerPeriodos" e "lerTrajetosFaixaEtaria"
  são responsáveis pela leitura dos dados correspondentes, na ordem que foram
  apresentadas anteriormente. Efetivamente, cada método realiza a leitura de
  uma linha de dados do arquivo.
*/
void Ambiente::lerVetoresMovimentacao() {
  string entrada = entradaMC;
  entrada += string("Ambiente");
  entrada += SEP;
  entrada += string("1-MOV.csv");

  arquivo.open(entrada);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << entrada;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  arquivo.ignore(sMax, '\n');
  lerRotas();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerTrajetos();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerPeriodos();
  arquivo.ignore(sMax, '\n');

  arquivo.ignore(sMax, '\n');
  lerTrajetosFaixaEtaria();

  arquivo.close();
}

/*
  Método responsável pela leitura do arquivo "Ambiente/2-CON.csv".

  Cada linha do arquivo "Ambiente/2-CON.csv" corresponde a um vetor de dados
  específico, que é necessário à simulação (desconsiderando linhas em branco ou
  com comentários). Os dados neste arquivo são armazenados da seguinte maneira:

  Linha 1: Vetor com informações sobre as quadras com vacinação;
  Linha 2: Vetor com informações sobre as faixas etárias vacinadas;
  Linha 3: Vetor com informações sobre os ciclos de vacinação;
  Linha 4: Vetor com informações sobre as quadras com controle biológico;
  Linha 5: Vetor com informações sobre as quadras com controle ambiental;
  Linha 6: Vetor com informações sobre os lotes com pontos estratégicos;
  Linha 7: Vetor com informações sobre complemento dos casos normalizados.
  Linha 8: Vetor com informações sobre casos por dia.
  Linhas 9 e 10: Vetores com informações sobre os controles aplicados sobre a
                população de mosquitos.
  Linha 11: Vetor com informações sobre os raios utilizados nos controles
            tipo Raio.
  Linha 12: Vetor com informações sobre os humanos vacinados.

  Os métodos "lerControle", "lerVetor", "lerContr", "lerContrPontos", "lerRaios"
  e "lerVacinados" são responsáveis pela leitura dos dados correspondentes,
  na ordem que foram apresentados anteriormente.
*/
void Ambiente::lerVetoresControles() {
  string entrada = entradaMC;
  entrada += string("Ambiente");
  entrada += SEP;
  entrada += string("2-CON.csv");

  arquivo.open(entrada);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << entrada;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  tie(sizeQuadVac, quadVac) = lerControle();
  tie(sizeFEVac, fEVac) = lerControle();

  sizePerVac = 2;
  perVac = new int[sizePerVac]();
  perVac[0] = 30; perVac[1] = 0;

  tie(sizeCicVac, cicVac) = lerControle();
  tie(sizeConBio, conBio) = lerControle();
  tie(sizeConAmb, conAmb) = lerControle();
  tie(sizePontEst, pontEst) = lerControle();

  lerFocos();
  lerContrLira();

  arquivo.ignore(sMax, '\n');
  arquivo >> sizeComp; arquivo.get();
  comp = lerVetor<double>(sizeComp);

  arquivo.ignore(sMax, '\n');
  arquivo.ignore(sMax, '\n');
  arquivo >> sizeCasos; arquivo.get();
  casos = lerVetor<int>(sizeCasos);

  lerContr();
  lerContrPontos();
  lerRaios();
  lerVacinados();

  arquivo.close();
}

/*
  Método responsável pela leitura das variáveis sizeCli e cli.
*/
void Ambiente::lerVetoresClimaticos() {
  string entrada = entradaMC;
  entrada += string("Ambiente");
  entrada += SEP;
  entrada += string("3-CLI.csv");

  arquivo.open(entrada);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << entrada;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  arquivo.ignore(sMax, '\n');
  arquivo >> sizeCli;
  arquivo.get();
  cli = new Climatico[sizeCli];
  if (sizeCli == 0) arquivo.ignore(sMax, '\n');
  for (int i = 0; i < sizeCli; ++i) {
    arquivo >> cli[i].txMinNaoAlados; arquivo.get();
    arquivo >> cli[i].txMaxNaoAlados; arquivo.get();
    arquivo >> cli[i].txMinAlados; arquivo.get();
    arquivo >> cli[i].txMaxAlados; arquivo.get();
  }

  arquivo.close();
}

/*
  Método responsável pela leitura das variáveis sizeContr e contr.
*/
void Ambiente::lerContr() {
  arquivo.ignore(sMax, '\n');
  arquivo.ignore(sMax, '\n');
  arquivo >> sizeContr;
  arquivo.get();
  contr = new Controle[sizeContr];
  for (int i = 0; i < sizeContr; ++i) {
    arquivo >> contr[i].quadra; arquivo.get();
    arquivo >> contr[i].ciclo; arquivo.get();
    arquivo >> contr[i].tipoControle; arquivo.get();
    arquivo >> contr[i].taxaMinMecanico; arquivo.get();
    arquivo >> contr[i].taxaMaxMecanico; arquivo.get();
    arquivo >> contr[i].taxaMinQuimico; arquivo.get();
    arquivo >> contr[i].taxaMaxQuimico; arquivo.get();
  }
}

/*
  Método responsável pela leitura das variáveis sizeIndContrPontos,
  indContrPontos e contrPontos.
*/
void Ambiente::lerContrPontos() {
  arquivo.ignore(sMax, '\n');
  arquivo.ignore(sMax, '\n');
  arquivo >> sizeIndContrPontos;
  arquivo.get();
  indContrPontos = new int[sizeIndContrPontos];
  for (int i = 0; i < sizeIndContrPontos; ++i) {
    arquivo >> indContrPontos[i]; arquivo.get();
  }
  sizeContrPontos = indContrPontos[sizeIndContrPontos - 1];
  contrPontos = new Posicao[sizeContrPontos];
  if (sizeContrPontos == 0) arquivo.ignore(sMax, '\n');
  for (int i = 0; i < sizeContrPontos; ++i) {
    arquivo >> contrPontos[i].x; arquivo.get();
    arquivo >> contrPontos[i].y; arquivo.get();
    arquivo >> contrPontos[i].lote; arquivo.get();
    arquivo >> contrPontos[i].quadra; arquivo.get();
  }
}

/*
  Método responsável pela leitura das variáveis sizeIndRaios, indRaios e raios.
*/
void Ambiente::lerRaios() {
  arquivo.ignore(sMax, '\n');
  arquivo.ignore(sMax, '\n');
  arquivo >> sizeIndRaios;
  arquivo.get();
  indRaios = new int[sizeIndRaios];
  for (int i = 0; i < sizeIndRaios; ++i) {
    arquivo >> indRaios[i]; arquivo.get();
  }
  sizeRaios = indRaios[sizeIndRaios - 1];
  raios = new Posicao[sizeRaios];
  if (sizeRaios == 0) arquivo.ignore(sMax, '\n');
  for (int i = 0; i < sizeRaios; ++i) {
    arquivo >> raios[i].x; arquivo.get();
    arquivo >> raios[i].y; arquivo.get();
    arquivo >> raios[i].lote; arquivo.get();
    arquivo >> raios[i].quadra; arquivo.get();
  }
}

/*
  Método responsável pela leitura das variáveis sizeVacs e vacs.
*/
void Ambiente::lerVacinados() {
  arquivo.ignore(sMax, '\n');
  arquivo.ignore(sMax, '\n');
  arquivo >> sizeVacs;
  arquivo.get();
  vacs = new Vacinado[sizeVacs];
  if (sizeVacs == 0) arquivo.ignore(sMax, '\n');
  char s, fe;
  for (int i = 0; i < sizeVacs; ++i) {
    arquivo >> vacs[i].ciclo; arquivo.get();
    arquivo >> vacs[i].quadra; arquivo.get();
    arquivo >> vacs[i].lote; arquivo.get();
    arquivo >> vacs[i].x; arquivo.get();
    arquivo >> vacs[i].y; arquivo.get();
    arquivo >> s; arquivo.get();
    arquivo >> fe; arquivo.get();
    arquivo >> vacs[i].doses; arquivo.get();

    switch (s) {
      case 'M': vacs[i].sexo = MASCULINO; break;
      case 'F': vacs[i].sexo = FEMININO; break;
    }

    switch (fe) {
      case 'B': vacs[i].faixaEtaria = BEBE; break;
      case 'C': vacs[i].faixaEtaria = CRIANCA; break;
      case 'D': vacs[i].faixaEtaria = ADOLESCENTE; break;
      case 'J': vacs[i].faixaEtaria = JOVEM; break;
      case 'A': vacs[i].faixaEtaria = ADULTO; break;
      case 'I': vacs[i].faixaEtaria = IDOSO; break;
    }

    vacs[i].processado = false;
  }
}

/*
  Método responsável pela leitura de um vetor de dados com "n" elementos.
*/
template<class T>
T *Ambiente::lerVetor(int n) {
  T *vec = new T[n]();
  for (int i = 0; i < n; ++i) {
    arquivo >> vec[i];
    arquivo.get();
  }
  return vec;
}

/*
  Método responsável pela leitura de um vetor de dados relacionados ao controle.

  O método retorna o tamanho e o vetor de dados lidos do arquivo.
*/
std::tuple<int, int *> Ambiente::lerControle() {
  int size = 0;
  arquivo.ignore(sMax, '\n');
  arquivo >> size;
  arquivo.get();
  int *vec = lerVetor<int>(size);
  if (size <= 0) arquivo.ignore(sMax, '\n');
  arquivo.ignore(sMax, '\n');
  return make_tuple(size, vec);
}

/*
  Método responsável pela leitura do vetor das localidades e quadras.

  Neste método são lidos dados para três variáveis:

  "nQuadras": Esta variável armazena a quantidade de localidades presentes no
              ambiente, incluindo a quadra "0" correspondente às ruas.
  "sizeNLotes": Esta variável armazena a quantidade de quadras que cada localidade
                contém. Por exemplo, "sizeNLotes[0]" contém a quantidade de
                quadras da localidade "0", ou seja, a quantidade de ruas;
                "sizeNLotes[10]" contém a quantidade de quadras da localidade "10".
  "indQuadras": Esta variável armazena os índices para as localidades. É bastante
                utilizada para indexar as outras estruturas do ambiente.
                Cada localidade conta com dois valores, que correspondem aos índices
                iniciais e finais. Desta forma, o id numérico da localidade é
                multiplicado por 2 quando do uso desta estrutura. Por exemplo,
                "indQuadras[2 * 10]" armazena o índice inicial para os dados
                correspondentes à localidade "10". "indQuadras[2 * 5 + 1]"
                armazena o índice final para os dados correspondentes
                à localidade "5".
*/
void Ambiente::lerQuadrasLotes() {
  arquivo >> nQuadras;
  arquivo.get();

  sizeNLotes = nQuadras;
  nLotes = lerVetor<int>(sizeNLotes);

  sizeIndQuadras = nQuadras * 2;
  indQuadras = lerVetor<int>(sizeIndQuadras);
}

/*
  Método responsável pela leitura do vetor das vizinhanças.

  Neste método são lidos dados para duas variáveis:

  "indViz": Esta variável armazena os índices para as vizinhanças. Este índice
            é utilizado para indexar a variável "viz" empregando ids de
            localidade e quadra. Desta forma, é possível obter as vizinhanças de
            uma particular quadra de uma determinada localidade. Para indexar
            esta variável é utilizada a variável "indQuadras". Por exemplo,
            "indViz[indQuadras[2 * 10] + 5]" armazena o índice inicial
            para os dados correspondentes às vizinhanças da quadra "5"
            da localidade "10". "indViz[indQuadras[2 * 7] + 3 + 1]" armazena o
            índice final para os dados correspondentes às vizinhanças
            da quadra "3" da localidade "7".
  "viz": Esta variável armazena todas as vizinhanças presentes no
         ambiente. É indexada pela variável "indViz". Por exemplo,
         "viz[indViz[indQuadras[2 * 10] + 5]]" armazena a primeira
         vizinhança da quadra "5" da localidade "10".
         "viz[indViz[indQuadras[2 * 10] + 5] + 1]" armazena a segunda
         vizinhança da quadra "5" da localidade "10".

*/
void Ambiente::lerVizinhancas() {
  sizeIndViz = indQuadras[nQuadras * 2 - 1] + 1;
  indViz = lerVetor<int>(sizeIndViz);

  sizeViz = indViz[indQuadras[nQuadras * 2 - 1]];

  viz = new Vizinhanca[sizeViz];
  for (int i = 0; i < sizeViz; ++i) {
    arquivo >> viz[i].xOrigem; arquivo.get();
    arquivo >> viz[i].yOrigem; arquivo.get();
    arquivo >> viz[i].xDestino; arquivo.get();
    arquivo >> viz[i].yDestino; arquivo.get();
    arquivo >> viz[i].loteDestino; arquivo.get();
    arquivo >> viz[i].quadraDestino; arquivo.get();
  }
}

/*
  Método responsável pela leitura do vetor de posições do ambiente.

  Neste método são lidos dados para três variáveis:

  "indPos": Esta variável armazena os índices para as posições. É utilizada para
            indexar a variável "pos" empregando ids de localidade e quadra. Desta
            forma é possível obter todas as posições de uma particular quadra de
            uma determinada localidade. Por exemplo,
            "indPos[indQuadras[2 * 10] + 5]" armazena o índice da primeira
            posição da quadra "5" da localidade "10".
            "indPos[indQuadras[2 * 10] + 5] + 9" armazena o índice da décima
            posição da quadra "5" da localidade "10".
  "pos": Esta variável armazena todas as posições presentes no ambiente. É
         indexada pela variável "indPos". Por exemplo,
         "pos[indPos[indQuadras[2 * 10] + 5]]" armazena a primeira posição
         da quadra "5" da localidade "10".
         "pos[indPos[indQuadras[2 * 10] + 5] + 9]" armazena a décima posição
         da quadra "5" da localidade "10".
  "indPosReg": Esta variável armazena os índices por regiões para as posições.
               Este índice é utilizado para obter todas as posições de uma
               determinada região. Atualmente são consideradas três regiões:
               Ruas: Índices armazenados de "indPosReg[0]" a "indPosReg[1]";
               Rurais: Índices armazenados de "indPosReg[1]" a "indPosReg[2]";
               Quadras: Índices armazenados de "indPosReg[2]" a "indPosReg[3]".
               Por exemplo, "indPosReg[0]" contém o índice para a primeira
               posição de rua. "indPosReg[0] + 1" contém o índice para a segunda
               posição de rua.
*/
void Ambiente::lerPosicoes() {
  sizeIndPos = indQuadras[nQuadras * 2 - 1] + 1;
  indPos = lerVetor<int>(sizeIndPos);

  sizePos = indPos[indQuadras[nQuadras * 2 - 1]];

  pos = new Posicao[sizePos];
  for (int i = 0; i < sizePos; ++i) {
    arquivo >> pos[i].x; arquivo.get();
    arquivo >> pos[i].y; arquivo.get();
    arquivo >> pos[i].lote; arquivo.get();
    arquivo >> pos[i].quadra; arquivo.get();
  }

  sizeIndPosReg = 4;
  indPosReg = lerVetor<int>(sizeIndPosReg);
}

/*
  Método responsável pela leitura do vetor de fronteiras do ambiente.

  Neste método são lidos dados para duas variáveis:

  "indFron": Esta variável armazena os índices para as fronteiras. É utilizada
             para indexar a variável "fron" empregando ids de localidade e quadra.
             Desta forma é possível obter todas as posições de fronteira de uma
             particular quadra de uma determinada localidade. Por exemplo,
             "indFron[indQuadras[2 * 10] + 5]" contém o índice da primeira
             posição de fronteira da quadra "5" da localidade "10".
             "indFron[indQuadras[2 * 7] + 3]" contém o índice da primeira
             posição de fronteira da quadra "3" da localidade "7".
  "fron": Esta variável armazena todas as fronteiras do ambiente. É indexada
          pela variável "indFron". Por exemplo,
          "fron[indFron[indQuadras[2 * 10] + 5]]" armazena a primeira posição
          de fronteira da quadra "5" da localidade "10".
          "fron[indFron[indQuadras[2 * 4] + 6]]" armazena a primeira posição
          de fronteira da quadra "6" da localidade "4".
*/
void Ambiente::lerFronteiras() {
  sizeIndFron = indQuadras[nQuadras * 2 - 1] + 1;
  indFron = lerVetor<int>(sizeIndFron);

  sizeFron = indFron[indQuadras[nQuadras * 2 - 1]];

  fron = new Fronteira[sizeFron];
  for (int i = 0; i < sizeFron; ++i) {
    arquivo >> fron[i].xDestino; arquivo.get();
    arquivo >> fron[i].yDestino; arquivo.get();
    arquivo >> fron[i].loteDestino; arquivo.get();
  }
}

/*
  Método responsável pela leitura do vetor de esquinas do ambiente.

  Neste método são lidos dados para duas variáveis:

  "indEsq": Esta variável armazena os índices para as esquinas. É utilizada
            para indexar a variável "esq" empregando ids de ruas.
            Desta forma é possível obter todas as posições de esquina de uma
            particular rua. Por exemplo, "indEsq[5]" contém o índice da primeira
            posição de esquina da rua "5". "indEsq[7]" contém o índice da
            primeira posição de esquina da rua "7".
  "esq": Esta variável armazena todas as posições de esquina do ambiente.
         É indexada pela variável "indEsq". Por exemplo,
         "esq[indEsq[5]]" armazena a primeira posição de esquina da rua "5".
         "esq[indEsq[7]]" armazena a primeira posição de esquina da rua "7".
*/
void Ambiente::lerEsquinas() {
  sizeIndEsq = nLotes[0] + 1;
  indEsq = lerVetor<int>(sizeIndEsq);

  sizeEsq = indEsq[nLotes[0]];

  esq = new Esquina[sizeEsq];
  for (int i = 0; i < sizeEsq; ++i) {
    arquivo >> esq[i].x; arquivo.get();
    arquivo >> esq[i].y; arquivo.get();
    arquivo >> esq[i].lote; arquivo.get();
  }
}

/*
  Método responsável pela leitura do vetor de posições de centro de esquinas
  do ambiente.

  Neste método são lidos dados para duas variáveis:

  "indCEsq": Esta variável armazena os índices para as posições de centro de
             esquinas. É utilizada para indexar a variável "cEsq" empregando
             ids de ruas. Desta forma é possível obter todas as posições de
             centro de esquina de uma particular rua. Por exemplo, "indCEsq[5]"
             contém o índice da primeira posição de centro de esquina da rua
             "5". "indCEsq[7]" contém o índice da primeira posição de centro de
             esquina da rua "7".
  "cEsq": Esta variável armazena todas as posições de centro de esquina do
          ambiente. É indexada pela variável "indCEsq". Por exemplo,
          "cEsq[indCEsq[5]]" armazena a primeira posição de centro de esquina
          da rua "5". "cEsq[indCEsq[7]]" armazena a primeira posição de centro
          de esquina da rua "7".
*/
void Ambiente::lerCentrosEsquinas() {
  sizeIndCEsq = nLotes[0] + 1;
  indCEsq = lerVetor<int>(sizeIndCEsq);

  sizeCEsq = indCEsq[nLotes[0]];

  cEsq = new Esquina[sizeCEsq];
  for (int i = 0; i < sizeCEsq; ++i) {
    arquivo >> cEsq[i].x; arquivo.get();
    arquivo >> cEsq[i].y; arquivo.get();
    arquivo >> cEsq[i].lote; arquivo.get();
  }
}

/*
  Método responsável pela leitura do vetor de rotas.

  Neste método são lidos dados para duas variáveis:

  "nRotas": Esta variável armazena a quantidade total de rotas, para todos os
            trajetos.
  "indRotas": Esta variável armazena os índices das rotas. É utilizada para
              indexar a variável "rotas" empregando um id de trajeto. Desta
              forma é possível obter todas as rotas pertencentes à um
              determinado trajeto. Por exemplo, "indRotas[indTraj[10]]" contém
              o índice para o ínicio dos dados da primeira rota do trajeto "10".
              "indRotas[indTraj[10] + 4]" contém o índice para o ínicio dos
              dados da quinta rota do trajeto "10".
  "rotas":  Esta variável armazena todas as rotas de todos os trajetos. É
            indexada pela variável "indRotas". Por exemplo, considerando o
            trajeto "10" e a rota "3" deste trajeto:

            "lote origem": Armazenado em rotas[indRotas[indTraj[10] + 3] + 0];
            "quadra origem": Armazenado em rotas[indRotas[indTraj[10] + 3] + 1];
            "lote destino": Armazenado em rotas[indRotas[indTraj[10] + 3] + 2];
            "quadra destino": Armazenado em rotas[indRotas[indTraj[10] + 3] + 3];
            "ruas": Armazenadas a partir de rotas[indRotas[indTraj[10] + 3] + 4].
                    Por exemplo, se esta rota contiver três ruas, então o id da
                    primeira rua estará armazenado em
                    rotas[indRotas[indTraj[10] + 3] + 4], da segunda em
                    rotas[indRotas[indTraj[10] + 3] + 5] e da terceira em
                    rotas[indRotas[indTraj[10] + 3] + 6].
*/
void Ambiente::lerRotas() {
  arquivo >> nRotas;
  arquivo.get();

  sizeIndRotas = nRotas + 1;
  indRotas = lerVetor<int>(sizeIndRotas);

  sizeRotas = indRotas[nRotas];
  rotas = lerVetor<int>(sizeRotas);
}

/*
  Método responsável pela leitura do vetor de trajetos.

  Neste método são lidos dados para duas variáveis:

  "nTraj": Esta variável armazena a quantidade total de trajetos.
  "indTraj": Esta variável armazena os índices para os trajetos. É utilizada
             para indexar a variável "indRotas" empregando um id de trajeto.
             Desta forma é possível obter todas as rotas pertencentes à um
             determinado trajeto. Não há um vetor de trajetos pois os índices
             são utilizados à sua representação. Por exemplo, as rotas
             pertencentes ao trajeto "10" estão nos índices indicados em
             "indTraj[10]" a "indTraj[11]".
*/
void Ambiente::lerTrajetos() {
  arquivo >> nTraj;
  arquivo.get();

  sizeIndTraj = nTraj + 1;
  indTraj = lerVetor<int>(sizeIndTraj);
}

/*
  Método responsável pela leitura do vetor de períodos.

  Neste método são lidos dados para duas variáveis:

  "indPeri": Esta variável armazena os índices para os períodos dos trajetos.
             É utilizada para indexar a variável "peri" empregando ids de rota
             e trajeto. Desta forma é possível obter todos os períodos de
             permanência pertencentes as rotas dos trajetos. Por exemplo,
             "indPeri[10]" armazena o índice inicial dos períodos do trajeto
             "10".
  "peri": Esta variável armazena os períodos das rotas dos trajetos. É indexada
          pela variável "indPeri". Por exemplo, "peri[indPeri[3] + 5]" armazena
          o período de permanência para a rota "5" do trajeto "3".
*/
void Ambiente::lerPeriodos() {
  sizeIndPeri = nTraj + 1;
  indPeri = lerVetor<int>(sizeIndPeri);

  sizePeri = indPeri[nTraj];
  peri = lerVetor<int>(sizePeri);
}

/*
  Método responsável pela leitura do vetor de índices de trajetos por faixas
  etárias.

  Neste método são lidos dados para a variável "indTrajFE". Esta variável
  armazena os índices dos trajetos por faixas etárias, sendo utilizada à
  obtenção de todos os trajetos pertencentes à uma particular faixa etária.
  Por exemplo:

  Trajetos para crianças: índice inicial armazenado em "indTrajFE[0]";
  Trajetos para jovens: índice inicial armazenado em "indTrajFE[1]";
  Trajetos para adultos: índice inicial armazenado em "indTrajFE[2]";
  Trajetos para idosos: índice inicial armazenado em "indTrajFE[3]".
*/
void Ambiente::lerTrajetosFaixaEtaria() {
  sizeindTrajFE = N_IDADES + 1;
  indTrajFE = lerVetor<int>(sizeindTrajFE);
}

/*
  Método responsável pela leitura do arquivo "Ambiente/DistribuicaoHumanos.csv".

  Primeiramente é lido a quantidade de registros presentes no arquivo. Em
  seguida são lidos os registros. Cada registro descreve um caso de infecção de
  humano que será inserido na simulação, sendo composto pelos atributos:

  "quadra": id da localidade da posição inicial do humano;
  "lote": id da quadra da posição inicial do humano;
  "latitude": latitude inicial do humano;
  "longitude": longitude inicial do humano;
  "sexo": sexo do humano (M ou F);
  "faixa etária": faixa etária do humano (C, J, A ou I);
  "saúde Dengue": saúde do humano (S ou I);
  "sorotipo atual": sorotipo do humano (1, 2, 3, 4 ou 0 se ausente);
  "ciclo": ciclo de entrada do humano na simulação.

  Atualmente a posição do humano que é lida do arquivo não é utilizada. Ela é
  substituída por uma posição qualquer do ambiente que é escolhida
  aleatoriamente. Com esta alteração objetivou-se alcançar uma melhor
  distribuição espacial dos casos de Dengue inseridos, evitando a formação de
  clusters de infecção. Para remover este comportamento basta comentar o trecho
  de código indicado abaixo.
*/
void Ambiente::lerArquivoDistribuicaoHumanos() {
  string entrada = entradaMC;
  entrada += string("Ambiente");
  entrada += SEP;
  entrada += string("DistribuicaoHumanos.csv");

  ifstream arquivo;
  arquivo.open(entrada);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << entrada;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  arquivo >> sizeDistHumanos;
  arquivo.get();
  arquivo.ignore(sMax, '\n');

  distHumanos = new Caso[sizeDistHumanos]();

  int q = 0, l = 0, x = 0, y = 0, s = 0, fe = 0, sd = 0, st = 0, cic = 0;
  char s1, fe1, sd1;

  for (int i = 0; i < sizeDistHumanos; ++i) {
    arquivo >> q; arquivo.get();
    arquivo >> l; arquivo.get();
    arquivo >> x; arquivo.get();
    arquivo >> y; arquivo.get();
    arquivo >> s1; arquivo.get();
    arquivo >> fe1; arquivo.get();
    arquivo >> sd1; arquivo.get();
    arquivo >> st; arquivo.get();
    arquivo >> cic; arquivo.get();

    switch (s1) {
      case 'M': s = MASCULINO; break;
      case 'F': s = FEMININO; break;
    }

    switch (fe1) {
      case 'B': fe = BEBE; break;
      case 'C': fe = CRIANCA; break;
      case 'D': fe = ADOLESCENTE; break;
      case 'J': fe = JOVEM; break;
      case 'A': fe = ADULTO; break;
      case 'I': fe = IDOSO; break;
    }

    switch (sd1) {
      case 'S': sd = SUSCETIVEL; break;
      case 'I': sd = INFECTANTE; break;
    }

    // Trecho de código responsável pela escolha aleatória de uma posição
    // do ambiente.
    RandPerc rand;
    int p = sizePos * rand();
    x = pos[p].x, y = pos[p].y;
    l = pos[p].lote, q = pos[p].quadra;

    distHumanos[i].q = q;
    distHumanos[i].l = l;
    distHumanos[i].x = x;
    distHumanos[i].y = y;
    distHumanos[i].s = s;
    distHumanos[i].fe = fe;
    distHumanos[i].sd = sd;
    distHumanos[i].st = st;
    distHumanos[i].cic = cic;
  }

  arquivo.close();
}

/*
  Método responsável pela leitura do arquivo
  "Ambiente/DistribuicaoMosquitos.csv".

  Primeiramente é lido a quantidade de registros presentes no arquivo. Em
  seguida são lidos os registros. Cada registro descreve uma população de
  mosquitos que será inserida durante a simulação, sendo composto pelos
  atributos:

  "quadra": quadra onde esta população de mosquitos será inserida;
  "quantidade total": quantidade de mosquitos desta população;
  "sexo": sexo dos mosquitos desta população (M ou F);
  "fase": fase dos mosquitos (O: ovo ou A: ativa);
  "percentual mínimo infectados": percentual mínimo de mosquitos infectados com
                                  Dengue nesta população;
  "percentual máximo infectados": percentual máximo de mosquitos infectados com
                                  Dengue nesta população;
  "sorotipo": sorotipo dos mosquitos infectados com Dengue;
  "ciclo": ciclo de entrada desta população de mosquitos na simulação.
*/
void Ambiente::lerArquivoDistribuicaoMosquitos() {
  string entrada = entradaMC;
  entrada += string("Ambiente");
  entrada += SEP;
  entrada += string("DistribuicaoMosquitos.csv");

  ifstream arquivo;
  arquivo.open(entrada);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << entrada;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  arquivo >> sizeDistMosquitos;
  arquivo.get();
  arquivo.ignore(sMax, '\n');

  distMosquitos = new PopMosquitos[sizeDistMosquitos];

  int q = 0, quant = 0, s = 0, fs = 0, st = 0, cic = 0;
  double pmin = 0, pmax = 0;
  char s1, fs1;

  for (int i = 0; i < sizeDistMosquitos; ++i) {
    arquivo >> q; arquivo.get();
    arquivo >> quant; arquivo.get();
    arquivo >> s1; arquivo.get();
    arquivo >> fs1; arquivo.get();
    arquivo >> pmin; arquivo.get();
    arquivo >> pmax; arquivo.get();
    arquivo >> st; arquivo.get();
    arquivo >> cic; arquivo.get();

    switch (s1) {
      case 'M': s = MACHO; break;
      case 'F': s = FEMEA; break;
    }

    switch (fs1) {
      case 'O': fs = OVO; break;
      case 'A': fs = ATIVA; break;
    }

    distMosquitos[i].q = q;
    distMosquitos[i].quant = quant;
    distMosquitos[i].s = s;
    distMosquitos[i].fs = fs;
    distMosquitos[i].pmin = pmin;
    distMosquitos[i].pmax = pmax;
    distMosquitos[i].st = st;
    distMosquitos[i].cic = cic;
  }

  arquivo.close();
}

/*
  Método responsável pela leitura do vetor de posições de foco do ambiente.
*/
void Ambiente::lerFocos() {
  arquivo.ignore(sMax, '\n');
  sizeIndFocos = indQuadras[sizeIndQuadras - 1] + 1;
  indFocos = lerVetor<int>(sizeIndFocos);
  sizeFocos = indFocos[sizeIndFocos - 1];
  focos = lerVetor<int>(sizeFocos);
  arquivo.ignore(sMax, '\n');
  // Inicializa o vetor capFocos
  capFocos = new int[sizeFocos]();
  for (int i = 0; i < sizeFocos; i++) capFocos[i] = 0;
}

/*
  Método responsável pela leitura do vetor de controle dinâmico a partir do LIRAa.
*/
void Ambiente::lerContrLira() {
  arquivo.ignore(sMax, '\n');
  arquivo >> nLira; arquivo.get();
  sizeContrLira = nLira * nQuadras;
  contrLira = lerVetor<int>(sizeContrLira);
  arquivo.ignore(sMax, '\n');
}
