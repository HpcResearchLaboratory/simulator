#include "Parametros.h"
#include "src/Macros/0_SIM.h"
#include "src/Macros/MacrosSO.h"

/*
  Construtor da classe Parâmetros, que armazena todos os parâmetros da simulação.

  A variável "entradaMC" armazena o caminho para a pasta de entrada contendo os 
  arquivos de configuração da simulação. 

  O método "lerParametros" é responsável por realizar a leitura dos arquivos 
  de configuração e armazenar os parâmetros em estruturas de dados. 

  O método "toGPU" realiza a cópia dos parâmetros lidos para a GPU. 
*/
Parametros::Parametros(string entradaMC) {
  this->entradaMC = entradaMC;

  lerParametros();

  nSims = QUANTIDADE_SIMULACOES;
  nCiclos = QUANTIDADE_CICLOS + 1;
  nSubCiclos = QUANTIDADE_SUBCICLOS;

  toGPU();
}

/*
  Método responsável pela obtenção do consumo de memória da classe Parametros. 
*/
int Parametros::getMemoriaGPU() {
  return (nParametros * sizeof(double));
}

/*
  Destrutor da classe Parametros. 

  São desalocados o vetor de parâmetros da memória principal e da GPU. 
*/
Parametros::~Parametros() {
  delete[](parametros);
  delete(parametrosDev); 
}

/*
  Método responsável pela cópia dos dados da classe Parametros para a GPU. 
*/
void Parametros::toGPU() {
  parametrosDev = new DVector<double>(parametros, parametros + nParametros);

  PparametrosDev = raw_pointer_cast(parametrosDev->data());
}

/*
  Método responsável pela leitura de um arquivo de configuração da simulação. 
  Como todos os arquivos de entrada, contidos nas pastas 
  "Entradas/MonteCarlo_{1}/Humanos", "Entradas/MonteCarlo_{1}/Mosquitos" e 
  "Entradas/MonteCarlo_{1}/Simulacao" têm a mesma estrutura, somente um método 
  é necessário. 

  Ignorando a linha de cabeçalho, cada linha do arquivo consiste em um 
  parâmetro de simulação. Cada linha contém quatro atributos:

  "Codigo": Código único do parâmetro. Não é lido nem armazenado pela classe.
  "Min": Valor mínimo que o parâmetro pode assumir. 
  "Max": Valor máximo que o parâmetro pode assumir. 
  "Descricao": Descrição textual do parâmetro. Não é lido nem armazenado pela 
  classe e possui a única finalidade de auxiliar na alteração de parâmetros 
  diretamente pelos arquivos de configuração. 
*/
void Parametros::lerArquivo(
  string pasta, string nomeArquivo, int& i, int nPar
) {
  string entrada = entradaMC;
  entrada += pasta;
  entrada += SEP;
  entrada += nomeArquivo;
  
  fstream arquivo(entrada);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << entrada;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  arquivo.ignore(sMax, '\n');
  for (int j = 0; j < nPar; ++j) {
    arquivo.ignore(7, EOF);
    arquivo >> parametros[i];
    arquivo.get();
    i += 1;

    arquivo >> parametros[i];
    arquivo.get();
    i += 1;

    arquivo.ignore(sMax, '\n');
  }
  arquivo.close();
}

/*
  Método responsável pela leitura de todos os arquivos de parâmetros. 

  São lidos os arquivos contidos nas pastas "Entradas/MonteCarlo_{1}/Humanos", 
  "Entradas/MonteCarlo_{1}/Mosquitos" e "Entradas/MonteCarlo_{1}/Simulacao" 
  por meio das chamadas ao método "lerArquivo". Os arquivos lidos são: 
  "Entradas/MonteCarlo_{1}/Simulacao/0-SIM.csv";
  "Entradas/MonteCarlo_{1}/Humanos/0-INI.csv";
  "Entradas/MonteCarlo_{1}/Humanos/1-MOV.csv";
  "Entradas/MonteCarlo_{1}/Humanos/2-CON.csv";
  "Entradas/MonteCarlo_{1}/Humanos/3-TRA.csv";
  "Entradas/MonteCarlo_{1}/Humanos/4-CON.csv";
  "Entradas/MonteCarlo_{1}/Humanos/5-INS.csv";
  "Entradas/MonteCarlo_{1}/Mosquitos/0-INI.csv";
  "Entradas/MonteCarlo_{1}/Mosquitos/1-MOV.csv";
  "Entradas/MonteCarlo_{1}/Mosquitos/2-CON.csv";
  "Entradas/MonteCarlo_{1}/Mosquitos/3-TRA.csv";
  "Entradas/MonteCarlo_{1}/Mosquitos/4-CON.csv";
  "Entradas/MonteCarlo_{1}/Mosquitos/5-GER.csv".

  Todos os parâmetros são armazenados em um único vetor, facilitando a cópia 
  dos dados para a GPU e a manutenção de macros para acesso. 
*/
void Parametros::lerParametros() {
  nParametros = N_PAR;
  parametros = new double[nParametros]();

  int i = 0;
  lerArquivo("Simulacao", "0-SIM.csv", i, N_0_SIM);
  lerArquivo("Humanos", "0-INI.csv", i, N_0_INI_H);
  lerArquivo("Humanos", "1-MOV.csv", i, N_1_MOV_H);
  lerArquivo("Humanos", "2-CON.csv", i, N_2_CON_H);
  lerArquivo("Humanos", "3-TRA.csv", i, N_3_TRA_H);
  lerArquivo("Humanos" ,"4-CON.csv", i, N_4_CON_H);
  lerArquivo("Humanos", "5-INS.csv", i, N_5_INS_H);
  lerArquivo("Mosquitos", "0-INI.csv", i, N_0_INI_M);
  lerArquivo("Mosquitos", "1-MOV.csv", i, N_1_MOV_M);
  lerArquivo("Mosquitos", "2-CON.csv", i, N_2_CON_M);
  lerArquivo("Mosquitos", "3-TRA.csv", i, N_3_TRA_M);
  lerArquivo("Mosquitos", "4-CON.csv", i, N_4_CON_M);
  lerArquivo("Mosquitos", "5-GER.csv", i, N_5_GER_M);
}
