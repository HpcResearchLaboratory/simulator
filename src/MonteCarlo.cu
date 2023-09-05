#include "MonteCarlo.h"
#include "Fontes/Macros/MacrosSO.h"
#include "Fontes/Parametros.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Saidas.h"
#include "Fontes/Simulacao.h"

/*
  Classe que armazena todos os dados relacionados à uma simulação tipo 
  Monte Carlo. Simulações tipo Monte Carlo são obtidas a partir do cálculo da 
  média dos resultados obtidos por meio da execução de simulações individuais. 
  As saídas populacionais são geradas para as simulações tipo Monte Carlo 
  calculando-se a média, ciclo a ciclo, das quantidades de agentes pertencentes 
  à cada subpopulação de interesse. Não são geradas saídas espaciais tipo 
  Monte Carlo.

  Os argumentos do construtor, "entradaMC" e "saidaMC", armazenam o caminho para
  as pasta de entrada e saída desta simulação Monte Carlo. A pasta de entrada é 
  utilizada na leitura de parâmetros e dados de inicialização da simulação. A 
  pasta de saída é utilizada à escrita de arquivos de saída contendo os 
  resultados da simulação. 

  Este método realiza a criação da pasta de saída da simulação Monte Carlo, 
  leitura dos parâmetros de simulação e da estrutura do ambiente, alocação 
  da classe responsável pela geração dos arquivos de saída da simulação e 
  inicialização da execução da simulação. Adicionalmente são exibidos em tela 
  as datas de início e final da execução da simulação, assim como o tempo 
  dispendido. 
*/
MonteCarlo::MonteCarlo(string entradaMC, string saidaMC, int saidaSubciclo) {
  this->entradaMC = entradaMC;
  this->saidaMC = saidaMC;
  this->saidaSubciclo = saidaSubciclo;

  // Criação da pasta de saída. 
  system((CRIAR_PASTA + saidaMC).c_str());

  // Leitura dos parâmetros e do ambiente de simulação e alocação das saídas. 
  parametros = new Parametros(entradaMC);
  ambiente = new Ambiente(entradaMC);
  saidas = new Saidas(ambiente, parametros, saidaMC);

  // Mostra e coleta a data e hora do início da execução da simulação. 
  exibirData();
  auto t1 = high_resolution_clock::now();

  // Inicia a execução da simulação tipo Monte Carlo. 
  iniciar();

  // Mostra e coleta a data e hora do final da execução da simulação.   
  auto t2 = high_resolution_clock::now();
  exibirData();

  // Exibe em tela o tempo dispendido na execução da simulação tipo Monte Carlo. 
  cout << duration_cast<duration<double>>(t2 - t1).count() << "s" << endl;
}

/*
  Destrutor da classe MonteCarlo.

  São desalocadas as estruturas que armazenam os parâmetros, o ambiente e as 
  saídas da simulação tipo Monte Carlo. 
*/
MonteCarlo::~MonteCarlo() {
  delete(parametros); delete(ambiente); delete(saidas);
}

/*
  Método responsável pela inicialização da execução da simulação Monte Carlo. 

  A variável "saidaSim" armazena o caminho para a pasta de saída da simulação 
  individual, que pertence à uma simulação tipo Monte Carlo. 
  
  O parâmetro "parametros->nSims" define a quantidade de simulações individuais 
  que serão executadas e utilizadas para compor uma simulação tipo Monte Carlo. 

  O método "saidas->limparEspaciais" é utilizado para limpar as saídas espaciais 
  entre a execução de simulações individuais. Sem este método, as saídas 
  espaciais acumulam de uma execução para outra, gerando resultados incorretos. 

  O método "saidas->salvarPopulacoes" é responsável por salvar os resultados 
  da simulação nos respectivos arquivos de saída. 
*/
void MonteCarlo::iniciar() {
  string saidaSim;
  for (int idSim = 0; idSim < parametros->nSims; ++idSim) {
    // A pasta da saída da simulação individual será 
    // "Entradas/MonteCarlo_{idMC}/Simulacao_{idSim}/". 
    saidaSim = saidaMC;
    saidaSim += string("Simulacao_");
    saidaSim += to_string(idSim);
    saidaSim += SEP;

    // Inicia a execução da simulação individual. 
    Simulacao(idSim, saidaSim, saidas, parametros, ambiente, saidaSubciclo);

    // Limpa saídas espaciais. 
    saidas->limparEspaciais();
  }
  // Salva saídas populacionais da simulação tipo Monte Carlo. 
  saidas->salvarPopulacoes();
}

/*
  Método responsável por obter e formatar a data atual à exibição em tela. 
*/
void MonteCarlo::exibirData() {
  time_t data = system_clock::to_time_t(system_clock::now());
  cout << put_time(localtime(&data), "%d/%m/%Y %H:%M:%S") << endl;
}
