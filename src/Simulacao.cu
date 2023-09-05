#include "Simulacao.h"

#include "Fontes/Seeds.h"
#include "Fontes/Parametros.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Uteis/RandPerc.h"
#include "Fontes/Saidas.h"
#include "Fontes/Macros/MacrosSO.h"
#include "Fontes/Macros/MacrosGerais.h"
#include "Fontes/Macros/2_CON_H.h"
#include "Fontes/Macros/3_TRA_H.h"
#include "Fontes/Macros/4_CON_H.h"
#include "Fontes/Macros/3_TRA_M.h"
#include "Fontes/Macros/4_CON_M.h"
#include "Fontes/Macros/5_GER_M.h"

#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Mosquitos/Movimentacao.h"
#include "Fontes/Mosquitos/Contato.h"
#include "Fontes/Mosquitos/Transicao.h"
#include "Fontes/Mosquitos/Controle.h"
#include "Fontes/Mosquitos/Geracao.h"
#include "Fontes/Mosquitos/Insercao.h"
#include "Fontes/Mosquitos/Saidas.h"

#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Humanos/Movimentacao.h"
#include "Fontes/Humanos/Contato.h"
#include "Fontes/Humanos/Transicao.h"
#include "Fontes/Humanos/Controle.h"
#include "Fontes/Humanos/Insercao.h"
#include "Fontes/Humanos/Saidas.h"

#include <chrono>

using std::chrono::high_resolution_clock;
using std::chrono::duration_cast;
using std::chrono::microseconds;

/*
  Construtor da classe Simulacao.

  A variável "idSim" indica o id numérico da simulação individual.
  "saidaSim" indica o caminho para a pasta de saída da simulação.
  "saidas", "parametros" e "ambiente" armazenam as saídas, os parâmetros e o
  ambiente de simulação, respectivamente.

  Este método é responsável por criar a pasta de saída dos arquivos resultantes
  da simulação, inicializar as populações de humanos e mosquitos, inicializar
  as seeds utilizadas à geração de números aleatórios, exibir em tela o
  consumo de memória total da simulação, iniciar a execução da simulação
  individual, copiar os resultados da simulação da GPU para a mémoria
  principal e salvar as saídas espaciais da simulação. Note que somente as
  saídas espaciais são salvas para a simulação individual. As saídas
  populacionais são tipo Monte Carlo e são salvas pela classe MonteCarlo.
*/
Simulacao::Simulacao(
  int idSim, string saidaSim, Saidas *saidas,
  Parametros *parametros, Ambiente *ambiente,
  int saidaSubciclo
) {
  this->idSim = idSim;
  this->saidaSim = saidaSim;
  this->saidas = saidas;
  this->parametros = parametros;
  this->ambiente = ambiente;
  this->saidaSubciclo = saidaSubciclo;

  ciclo = 0;
  periodo = MANHA;
  subciclo = 0;
  idLira = -1;

  // As pastas de saída bistring serão:
  // "Entradas/MonteCarlo_{idMC}/Simulacao_{idSim}/Mosquitos/".
  // "Entradas/MonteCarlo_{idMC}/Simulacao_{idSim}/Humanos/".
  saidaM = saidaSim + string("Mosquitos") + SEP;
  saidaH = saidaSim + string("Humanos") + SEP;

  // O arquivo de saída para oviposição será:
  // "Entradas/MonteCarlo_{idMC}/Simulacao_{idSim}/Oviposicao.csv".
  arquivoSaidaOviposicao = saidaSim + string("Oviposicao.csv");

  // Criação da pasta de saída da simulação individual.
  system((CRIAR_PASTA + saidaSim).c_str());

  // Criação das pastas de saída bitstring.
  system((CRIAR_PASTA + saidaM).c_str());
  system((CRIAR_PASTA + saidaH).c_str());

  // Criação dos agentes humanos e mosquitos.
  humanos = new Humanos(parametros, ambiente);
  mosquitos = new Mosquitos(parametros, ambiente);

  // Inicialização das seeds.
  seeds = new Seeds(
                {mosquitos->maxMosquitos,
                humanos->nHumanos, ambiente->sizePos}
              );

  // Exibição em tela do consumo de memória total da simulação individual.
  if (idSim == 0) exibirConsumoMemoria();

  // Inicialização da execução da simulação índividual.
  iniciar();

  // Cópia das saídas da simulação que estão em GPU para a CPU.
  saidas->toCPU();
  // Escrita dos arquivos de saída espaciais da simulação individual.
  saidas->salvarEspaciais(saidaSim);
}

/*
  Destrutor da classe Simulacao.

  São desalocados as classes que armazenam os agentes humanos e mosquitos e as
  seeds utilizadas durante a simulação.
*/
Simulacao::~Simulacao() {
  delete(humanos); delete(mosquitos); delete(seeds);
}

/*
  Método responsável por executar o processo de simulação. São executados os
  operadores definidos à modelagem da Dengue na ordem especificada. O primeiro
  for é responsável por executar os ciclos de simulação. O segundo for é
  responsável pela execução dos períodos dos ciclos. O terceiro for é
  responsável por executar os subciclos correspondentes aos períodos.
  A movimentação dos humanos é realizada uma vez a cada período. A movimentação
  dos mosquitos e os contatos entre mosquitos e entre mosquitos e humanos são
  realizadas uma vez a cada subciclo. Os demais operadores são executados
  uma vez a cada ciclo.
*/
void Simulacao::iniciar() {

  // Executa movimentação, contato e transição para estabilizar a população.
  int CICLOS_SHIFT_POPULACAO = 0;
  for (ciclo = 1; ciclo < (CICLOS_SHIFT_POPULACAO + 1); ++ciclo) {
    // cout << "Inicializacao | ";
    // cout << "Ciclo " << ciclo << " / " << CICLOS_SHIFT_POPULACAO << endl;
    for (periodo = MANHA; periodo <= NOITE; ++periodo) {
      cout << "periodo: " << periodo << endl;
      movimentacaoHumanos();
      for (subciclo = 0; subciclo < parametros->nSubCiclos; ++subciclo) {
        // cout << "subciclo: " << subciclo << endl;
        movimentacaoMosquitos();
        contatoEntreMosquitos(periodo);
        contatoEntreMosquitosEHumanos(periodo);
      }
    }
    transicaoFasesMosquitos();
    transicaoEstadosMosquitos();
    transicaoEstadosHumanos();
    controleNaturalMosquitosPorIdade();
    controleNaturalMosquitosPorSelecao();
    controleNaturalHumanos();
    geracao();
  }

  ciclo = 0;

  // Execução dos ciclos de simulação.
  for (ciclo = 1; ciclo < parametros->nCiclos; ++ciclo) {
    // cout << "Ciclo " << ciclo << " / " << (parametros->nCiclos - 1) << endl;
    // calcularRt();
    calcularIdLira();
    computarSaidas();
    saidaOviposicao();
    
    // Execução dos períodos do ciclo.
    for (periodo = MANHA; periodo <= NOITE; ++periodo) {
      if (saidaSubciclo or periodo == MANHA)
        saidaBitstringHumanos();
      
      // cout << "periodo: " << periodo << endl;
      movimentacaoHumanos(); // Ok
      
      // Execução dos subciclos do período.
      for (subciclo = 0; subciclo < parametros->nSubCiclos; ++subciclo) {
        if (saidaSubciclo or (periodo == MANHA and subciclo == 0))
          saidaBitstringMosquitos();
        
        // cout << "subciclo: " << subciclo << endl;
        movimentacaoMosquitos(); // Ok

        contatoEntreMosquitos(periodo); // Ok
        contatoEntreMosquitosEHumanos(periodo); // Ok
      }
    }

    transicaoFasesMosquitos();
    transicaoEstadosMosquitos(); // Ok
    transicaoEstadosHumanos(); // Ok
    //vacinacao();

    controleNaturalMosquitosPorIdade(); // Ok
    controleNaturalMosquitosPorSelecao(); // Ok
    controleNaturalHumanos();
    //controlesMosquitos();
    //controleBiologico();
    //tratamentoAmbiental();

    geracao(); // Ok

    insercaoMosquitos(); // Ok
    insercaoHumanos(); // Ok

  }
  periodo = 0;
  subciclo = 0;
  saidaBitstringHumanos();
  saidaBitstringMosquitos();
  computarSaidas();
  saidaOviposicao();
}

/*
void Simulacao::calcularRt() {
  RandPerc rand;

  // Parâmetros para humanos
  double beta_h = TAXA_INFECCAO_MOSQUITO_(rand());
  int S = count_if(
    humanos->humanosDev->begin(),
    humanos->humanosDev->end(),
    HumanoSuscetivel()
  );
  int N = humanos->nHumanos - count_if(
    humanos->humanosDev->begin(),
    humanos->humanosDev->end(),
    EstaMortoHumano()
  );
  double gamma_h = (PERIODO_EXPOSTO_HUMANO_(CRIANCA, rand()) +
                    PERIODO_EXPOSTO_HUMANO_(JOVEM, rand()) +
                    PERIODO_EXPOSTO_HUMANO_(ADULTO, rand()) +
                    PERIODO_EXPOSTO_HUMANO_(IDOSO, rand())) / 4.0;
  double mi_h = TAXA_MORTE_NATURAL_(rand());
  double sigma_h = 1.0 / ((PERIODO_RECUPERADO_HUMANO_(CRIANCA, rand()) +
                           PERIODO_RECUPERADO_HUMANO_(JOVEM, rand()) +
                           PERIODO_RECUPERADO_HUMANO_(ADULTO, rand()) +
                           PERIODO_RECUPERADO_HUMANO_(IDOSO, rand())) / 4.0);

  // Parâmetros para mosquitos
  double beta_m = (TAXA_INFECCAO_HUMANO_SUSCETIVEL_(CRIANCA, rand()) +
                   TAXA_INFECCAO_HUMANO_SUSCETIVEL_(JOVEM, rand()) +
                   TAXA_INFECCAO_HUMANO_SUSCETIVEL_(ADULTO, rand()) +
                   TAXA_INFECCAO_HUMANO_SUSCETIVEL_(IDOSO, rand())) / 4.0;
  int m1 = count_if(
    mosquitos->mosquitosDev->begin(),
    mosquitos->mosquitosDev->end(),
    MosquitoFemeaSuscetivelAlado()
  );
  int m = count_if(
    mosquitos->mosquitosDev->begin(),
    mosquitos->mosquitosDev->end(),
    MosquitoFemeaAlado()
  );
  double gamma_m = 1.0 / (CICLOS_LATENCIA_MOSQUITOS_(rand()));
  double mi_f = BS_ATIVOS_(rand()) *
                TAXA_ELIM_CONTROLE_NATURAL_SELECAO_(ATIVA, FEMEA, SAUDAVEL, rand()) *
                ENTRE_FAIXA(ambiente->cli[ciclo].txMinAlados, ambiente->cli[ciclo].txMaxAlados, rand());
  double fi = AS21_(rand()) / (double) (INTERVALO_ENTRE_POSTURAS_FEMEA_(rand()) +
                                        CICLOS_GESTACAO_(rand()));

  // I(t) e I(t + 1)
  double casos_t = ambiente->casos[ciclo - 1];
  double casos_t_add1 = ambiente->casos[ciclo];

  // Cálculo do ref
  if (casos_t != 0) {
    ref = casos_t_add1 / casos_t;
  }

  // Variáveis para o cálculo de q0 e m_star
  double sigma_p = BS_PUPAS_(rand());
  double sigma_l = BS_LARVAS_(rand());
  double mi_p = 1.0 - sigma_p;
  double mi_l = 1.0 - sigma_l;
  //double C = (ambiente->indPosReg[3] - ambiente->indPosReg[2]) * ENTRE_FAIXA(20, 30, rand());
  double C = 74 * ENTRE_FAIXA(20, 30, rand());
  double qf = (1.0 - PS21_(rand())) * BS_OVOS_(rand());

  // Cálculo do Q0
  double a = (sigma_l / (sigma_l + mi_l));
  double b = (sigma_p / (sigma_p + mi_p));
  double c = (qf * fi / mi_f);
  double q0 = (sigma_l * sigma_p * qf * fi) / ((sigma_l + mi_l) * (sigma_p + mi_p) * mi_f);
  double m_star = (sigma_p * sigma_l * C * (1 - 1 / q0)) / (mi_f * (sigma_p + mi_p));

  beta_h = (ref * m * pow(N, 2.0) * (gamma_m + mi_f) * (gamma_h + mi_h) * (sigma_h + mi_h) * mi_f) /
           (pow(fi, 2.0) * gamma_h * gamma_m * S * m1 * m_star);
  beta_h /= beta_m;

  std::cout << ref << "\t" << q0 << "\t" << beta_h << std::endl;
}
*/

/*
  Método responsável por calcular o LIRAa atual de acordo com o ciclo,
  determinando assim os multiplicadores aplicados no controle de ovos.
*/
void Simulacao::calcularIdLira() {
  double frac = (double) ciclo / parametros->nCiclos;
  idLira = (int) (frac * ambiente->nLira);
}

/*
  Método responsável pela movimentação dos agentes humanos.

  O método "for_each_n" é responsável pela aplicação do operador
  "MovimentacaoHumanos" sobre toda a população de agentes humanos. Como a
  biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.

  O método "humanos->atualizacaoIndices" é responsável pela atualização dos
  índices da estrutura que armazena os agentes humanos. Este índice agiliza
  a obtenção dos humanos que estão em uma determinada localidade. Por exemplo,
  "indHumanos[10]" armazena a primeira posição da região de dados que contém os
  agentes posicionados na localidade "10". A atualização dos índices é necessária
  pois a movimentação pode alterar a localidade em que os humanos estão posicionados.
*/
void Simulacao::movimentacaoHumanos() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, humanos->nHumanos,
    MovimentacaoHumanos(humanos, ambiente, parametros, seeds)
  );
  humanos->atualizacaoIndices();
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "movimentacaoHumanos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela movimentação dos agentes mosquitos.

  O método "for_each_n" é responsável pela aplicação do operador
  "MovimentacaoMosquitos" sobre toda a população de agentes mosquitos. Como a
  biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.

  O método "mosquitos->atualizacaoIndices" é responsável pela atualização dos
  índices da estrutura que armazena os agentes mosquitos. Este índice agiliza
  a obtenção dos mosquitos que estão em uma determinada localidade. Por exemplo,
  "indMosquitos[10]" armazena a primeira posição da região de dados que contém
  os agentes posicionados na localidade "10". A atualização dos índices é necessária
  pois a movimentação pode alterar a localidade em que os mosquitos estão
  posicionados.
*/
void Simulacao::movimentacaoMosquitos() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, mosquitos->nMosquitos,
    MovimentacaoMosquitos(
      mosquitos, humanos, ambiente,
      parametros, periodo, ambiente->sizePontEst, seeds
    )
  );
  mosquitos->atualizacaoIndices();
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "movimentacaoMosquitos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pelo contato entre agentes mosquitos, em que ocorrem
  os acasalamentos.

  O método "for_each_n" é responsável pela aplicação do operador
  "ContatoMosquitos" sobre todo o ambiente de simulação. Como a biblioteca
  Thrust é utilizada, a aplicação desta operação pode ocorrer paralelamente
  sobre os dados, dependendo das flags utilizadas durante a compilação realizada.
*/
void Simulacao::contatoEntreMosquitos(int periodo) {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, ambiente->sizePos,
    ContatoMosquitos(mosquitos, ambiente, parametros, periodo, seeds)
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "contatoEntreMosquitos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pelo contato entre agentes mosquitos e humanos, em que
  ocorrem a transmissão da doença de agentes infectados para agentes suscetíveis.

  O método "for_each_n" é responsável pela aplicação do operador
  "ContatoHumanos" sobre todo o ambiente de simulação. Como a biblioteca
  Thrust é utilizada, a aplicação desta operação pode ocorrer paralelamente
  sobre os dados, dependendo das flags utilizadas durante a compilação realizada.
*/
void Simulacao::contatoEntreMosquitosEHumanos(int periodo) {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, ambiente->sizePos,
    ContatoHumanos(mosquitos, humanos, ambiente, parametros, ciclo,
                   periodo, seeds)
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "contatoEntreMosquitosEHumanos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela transição de fases dos agentes mosquitos.

  O método "for_each_n" é responsável pela aplicação do operador
  "TransicaoFasesMosquitos" sobre todo o ambiente de simulação.
  Como a biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.
*/
void Simulacao::transicaoFasesMosquitos() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, ambiente->sizePos,
    TransicaoFasesMosquitos(ambiente, mosquitos, parametros, seeds)
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "transicaoFasesMosquitos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela transição de estados dos agentes mosquitos, em que
  ocorre a evolução da doença dos agentes infectados.

  O método "for_each_n" é responsável pela aplicação do operador
  "TransicaoEstadosMosquitos" sobre toda a população de agentes mosquitos.
  Como a biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.
*/
void Simulacao::transicaoEstadosMosquitos() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, mosquitos->nMosquitos,
    TransicaoEstadosMosquitos(mosquitos, parametros, seeds)
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "transicaoEstadosMosquitos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela transição de estados dos agentes humanos, em que
  ocorre a evolução da doença dos agentes infectados.

  O método "for_each_n" é responsável pela aplicação do operador
  "TransicaoEstadosHumanos" sobre toda a população de agentes humanos. Como a
  biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.
*/
void Simulacao::transicaoEstadosHumanos() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, humanos->nHumanos,
    TransicaoEstadosHumanos(humanos, parametros, seeds)
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "transicaoEstadosHumanos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela vacinação dos agentes humanos.

  A primeira chamada ao método "for_each_n" é responsável pela aplicação do
  operador "CampanhaVacinacao" sobre todas as localidades que em serão aplicadas
  campanhas de vacinação.

  A segunda chamada ao método "for_each_n" é responsável pela aplicação do
  operador "PosCampanhaVacinacao", que realiza a atualização da campanha de
  vacinação ao longo do tempo.

  A terceira chamado ao método "for_each_n" é responsável pela aplicação do
  operador "InsercaoVacinados", que realiza a inserção de humanos vacinados
  no ambiente. Efetivamente novos humanos não são inseridos, ocorre somente a
  troca de estados de humanos já existentes na simulação.

  Como a biblioteca Thrust é utilizada, a aplicação destas operações podem
  ocorrer paralelamente sobre os dados, dependendo das flags utilizadas durante
  a compilação realizada.
*/
void Simulacao::vacinacao() {
  for_each_n(
    seeds->idx, ambiente->sizeQuadVac,
    CampanhaVacinacao(
      humanos, ambiente, parametros, ciclo,
      ambiente->sizeQuadVac, ambiente->sizeFEVac,
      ambiente->sizePerVac, ambiente->sizeCicVac, seeds
    )
  );
  for_each_n(
    seeds->idx, 1,
    PosCampanhaVacinacao(
      ambiente, ciclo, ambiente->sizePerVac, ambiente->sizeCicVac
    )
  );

  for_each_n(
    seeds->idx, ambiente->sizeVacs,
    InsercaoVacinados(
      humanos, ambiente, parametros, ciclo, seeds
    )
  );
}

/*
  Método responsável pela execução do controle natural por idade sobre a
  população de mosquitos.

  O método "for_each_n" é responsável pela aplicação do operador
  "ControleNaturalMosquitosPorIdade" sobre toda a população de agentes mosquitos.
  Como a biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.
*/
void Simulacao::controleNaturalMosquitosPorIdade() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, mosquitos->nMosquitos,
    ControleNaturalMosquitosPorIdade(mosquitos, parametros, seeds)
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "controleNaturalMosquitosPorIdade(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela execução do controle natural por seleção sobre a
  população de mosquitos.

  O método "for_each_n" é responsável pela aplicação do operador
  "ControleNaturalMosquitosPorSelecao" sobre todo o ambiente de simulação. Como
  a biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.
*/
void Simulacao::controleNaturalMosquitosPorSelecao() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, ambiente->sizePos,
    ControleNaturalMosquitosPorSelecao(
      mosquitos, ambiente, parametros, ciclo, idLira, seeds
    )
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "controleNaturalMosquitosPorSelecao(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela execução do controle natural sobre a população de
  humanos.

  O método "for_each_n" é responsável pela aplicação do operador
  "ControleNaturalHumanos" sobre toda a população de agentes humanos. Como
  a biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.
*/
void Simulacao::controleNaturalHumanos() {
  // auto start = high_resolution_clock::now();
  for_each_n(
    seeds->idx, humanos->nHumanos,
    ControleNaturalHumanos(humanos, parametros, seeds)
  );
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "controleNaturalHumanos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela execução dos controles sobre a população de mosquitos
  no ambiente de simulação.

  O operador "PreControlesMosquitos" é responsável por verificar se ocorrerá a
  aplicação dos controles neste ciclo de simulação. Em caso afirmativo,
  os percentuais dos efeitos residuais são alterados para o valor máximo,
  indicando que os controles químicos têm eficiência inicial máxima de acordo
  com a taxa definida nos arquivos de configuração dos controles.

  A segunda chamada ao método "for_each_n" é responsável pela aplicação do
  operador "ControlesQuimicos" sobre todo o ambiente de simulação. Este operador
  executa os controles tipo Raio, Bloqueio, Tratamento e Pontos Estratégicos.
  Como a biblioteca Thrust é utilizada, a aplicação desta operação pode ocorrer
  paralelamente sobre os dados, dependendo das flags utilizadas durante a
  compilação realizada.

  Por fim, o operador "PosControlesMosquitos" é responsável por decrementar os
  percentuais dos efeitos residuais de acordo com os parâmetros especificados
  para o particular controle, indicando que os efeitos dos controles químicos
  aplicados decrescem ao longo do tempo.
*/
void Simulacao::controlesMosquitos() {
  for (int idContr = 0; idContr < ambiente->sizeContr and
       ambiente->contr[idContr].ciclo <= ciclo; ++idContr) {
    for_each_n(
      seeds->idx, 1,
      PreControlesMosquitos(
        ambiente, parametros, ciclo, idContr, seeds
      )
    );

    for_each_n(
      seeds->idx, ambiente->sizePos,
      ControlesMosquitos(
        mosquitos, ambiente, parametros, ciclo,
        idContr, ambiente->sizePontEst, seeds
      )
    );

    for_each_n(
      seeds->idx, 1,
      PosControlesMosquitos(
        ambiente, parametros, idContr, seeds
      )
    );
  }
}

/*
  Método responsável pela execução do controle biológico durante a simulação,
  que realiza a inserção de agentes mosquitos infectados com Wolbachia no
  ambiente.

  Inicialmente é obtida a quantidade total de agentes mosquitos que serão
  inseridos no ambiente. Esta quantidade depende dos parâmetros definidos nos
  arquivos de configuração.

  Em seguida são inseridos os agentes mosquitos. Os novos agentes são inseridos,
  se possível, em posições do vetor de agentes mosquitos que contenham agentes
  mortos, com o objetivo de otimizar o uso de memória e evitar realocações
  desnecessárias. O vetor de mosquitos somente é realocado se a quantidade de
  agentes que serão inseridos é maior que a quantidade de agentes mortos.
  Antes da inserção o vetor de agentes é particionado, movendo os agentes
  mortos para o início do vetor, facilitando desta forma a inserção dos novos
  agentes. For fim são atualizados os índices para os mosquitos, pois as
  quantidades de agentes nas localidades foram alterados.

  O método "for_each_n" é responsável pela aplicação do operador
  "ControleBiologico" sobre todas as localidades onde serão inseridos agentes
  mosquitos infectados com Wolbachia. Como a biblioteca Thrust é utilizada,
  a aplicação desta operação pode ocorrer paralelamente sobre os dados,
  dependendo das flags utilizadas durante a compilação realizada.
*/
void Simulacao::controleBiologico() {
  int n = transform_reduce(
            seeds->idx, seeds->idx + ambiente->sizeConBio,
            PreControleBiologico(parametros, ciclo),
            0, plus<int>()
          );
  if (n > 0) {
    int m = count_if(
              mosquitos->mosquitosDev->begin(),
              mosquitos->mosquitosDev->end(),
              EstaMortoMosquito()
            );

    if (n > m) {
      if (mosquitos->alocarMosquitos and
          (mosquitos->nMosquitos + (n - m)) > mosquitos->maxMosquitos) {
        cout << "Quantidade maxima de mosquitos alcancada ";
        cout << "no ciclo " << ciclo << endl;
        mosquitos->alocarMosquitos = false;
      }
      if (mosquitos->alocarMosquitos) {
        mosquitos->nMosquitos += (n - m);
        mosquitos->mosquitosDev->resize(mosquitos->nMosquitos, Mosquito());
        mosquitos->PmosquitosDev =
          raw_pointer_cast(mosquitos->mosquitosDev->data());
      }
    }

    partition(
      mosquitos->mosquitosDev->begin(),
      mosquitos->mosquitosDev->end(),
      EstaMortoMosquito()
    );

    for_each_n(
      seeds->idx, ambiente->sizeConBio,
      ControleBiologico(
        mosquitos, ambiente, parametros, ciclo, mosquitos->alocarMosquitos,
        seeds
      )
    );

    mosquitos->atualizacaoIndices();
  }
}

/*
  Método responsável pela execução do tratamento ambiental sobre o ambiente de
  simulação.

  O método "for_each_n" é responsável pela aplicação do operador
  "TratamentoAmbiental" sobre todas as quadras em que serão executadas o
  tratamento ambiental. Como a biblioteca Thrust é utilizada, a aplicação desta
  operação pode ocorrer paralelamente sobre os dados, dependendo das flags
  utilizadas durante a compilação realizada.
*/
void Simulacao::tratamentoAmbiental() {
  for_each_n(
    seeds->idx, ambiente->sizeConAmb,
    TratamentoAmbiental(
      mosquitos, ambiente, parametros, ciclo, ambiente->sizeConAmb, seeds
    )
  );
}

/*
  Método responsável pela execução da geração durante a simulação, que realiza
  a inserção de agentes mosquitos ovos resultantes dos contatos entre agentes
  mosquitos alados.

  Inicialmente é obtida a quantidade total de agentes mosquitos ovos que serão
  inseridos. Esta quantidade depende dos parâmetros definidos nos arquivos de
  configuração e dos contatos realizados entre agentes mosquitos neste ciclo.

  Em seguida são inseridos os agentes mosquitos. Os novos agentes são inseridos,
  se possível, em posições do vetor de agentes mosquitos que contenham agentes
  mortos, com o objetivo de otimizar o uso de memória e evitar realocações
  desnecessárias. O vetor de mosquitos somente é realocado se a quantidade de
  agentes que serão inseridos é maior que a quantidade de agentes mortos.
  Antes da inserção o vetor de agentes é particionado, movendo os agentes
  mortos para o início do vetor, facilitando desta forma a inserção dos novos
  agentes. For fim são atualizados os índices para os mosquitos, pois as
  quantidades de agentes nas localidades foram alterados.

  O método "for_each_n" é responsável pela aplicação do operador
  "Geracao" para a inserção dos novos agentes mosquitos ovos.
*/
void Simulacao::geracao() {
  // auto start = high_resolution_clock::now();
  int n = transform_reduce(
            seeds->idx, seeds->idx + mosquitos->nMosquitos,
            PreGeracao(ambiente, mosquitos, parametros, seeds),
            0, plus<int>()
          );
  if (n > 0) {
    int m = count_if(
              mosquitos->mosquitosDev->begin(),
              mosquitos->mosquitosDev->end(),
              EstaMortoMosquito()
            );

    if (n > m) {
      if (mosquitos->alocarMosquitos and
          (mosquitos->nMosquitos + (n - m)) > mosquitos->maxMosquitos) {
        cout << "Quantidade maxima de mosquitos alcancada ";
        cout << "no ciclo " << ciclo << endl;
        mosquitos->alocarMosquitos = false;
      }
      if (mosquitos->alocarMosquitos) {
        mosquitos->nMosquitos += (n - m);
        mosquitos->mosquitosDev->resize(mosquitos->nMosquitos, Mosquito());
        mosquitos->PmosquitosDev =
          raw_pointer_cast(mosquitos->mosquitosDev->data());
      }
    }

    partition(
      mosquitos->mosquitosDev->begin(),
      mosquitos->mosquitosDev->end(),
      EstaMortoMosquito()
    );

    for_each_n(
      seeds->idx, 1,
      Geracao(
        ambiente, mosquitos, parametros, seeds
      )
    );

    mosquitos->atualizacaoIndices();
  }
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "geracao(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela execução da inserção de agentes mosquitos no ambiente
  durante a simulação.

  Inicialmente é obtida a quantidade total de agentes mosquitos que serão
  inseridos. Esta quantidade depende dos parâmetros definidos nos arquivos de
  configuração, principalmente do arquivo "DistribuicaoMosquitos.csv".

  Em seguida são inseridos os agentes mosquitos. Os novos agentes são inseridos,
  se possível, em posições do vetor de agentes mosquitos que contenham agentes
  mortos, com o objetivo de otimizar o uso de memória e evitar realocações
  desnecessárias. O vetor de mosquitos somente é realocado se a quantidade de
  agentes que serão inseridos é maior que a quantidade de agentes mortos.
  Antes da inserção o vetor de agentes é particionado, movendo os agentes
  mortos para o início do vetor, facilitando desta forma a inserção dos novos
  agentes. For fim são atualizados os índices para os mosquitos, pois as
  quantidades de agentes nas localidades foram alterados.

  O método "for_each_n" é responsável pela aplicação do operador
  "InsercaoMosquitos" para a inserção dos novos agentes mosquitos.
*/
void Simulacao::insercaoMosquitos() {
  // auto start = high_resolution_clock::now();
  int n = transform_reduce(
            seeds->idx, seeds->idx + 1,
            PreInsercaoMosquitos(ciclo, ambiente), 0, plus<int>()
          );
  if (n > 0) {
    int m = count_if(
              mosquitos->mosquitosDev->begin(),
              mosquitos->mosquitosDev->end(),
              EstaMortoMosquito()
            );

    if (n > m) {
      mosquitos->nMosquitos += (n - m);
      mosquitos->mosquitosDev->resize(mosquitos->nMosquitos, Mosquito());
      mosquitos->PmosquitosDev =
                            raw_pointer_cast(mosquitos->mosquitosDev->data());
    }

    partition(
      mosquitos->mosquitosDev->begin(),
      mosquitos->mosquitosDev->end(),
      EstaMortoMosquito()
    );

    for_each_n(
      seeds->idx, 1,
      InsercaoMosquitos(mosquitos, ambiente, parametros, ciclo,
                        ambiente->sizePontEst, seeds)
    );

    mosquitos->atualizacaoIndices();
  }
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "insercaoMosquitos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pela execução da inserção de agentes humanos no ambiente
  durante a simulação.

  Inicialmente é obtida a quantidade total de agentes humanos que serão
  inseridos. Esta quantidade depende dos parâmetros definidos nos arquivos de
  configuração, principalmente do arquivo "DistribuicaoHumanos.csv".

  Em seguida são inseridos os agentes humanos. Os novos agentes são inseridos,
  se possível, em posições do vetor de agentes humanos que contenham agentes
  mortos, com o objetivo de otimizar o uso de memória e evitar realocações
  desnecessárias. O vetor de humanos somente é realocado se a quantidade de
  agentes que serão inseridos é maior que a quantidade de agentes mortos.
  Antes da inserção o vetor de agentes é particionado, movendo os agentes
  mortos para o início do vetor, facilitando desta forma a inserção dos novos
  agentes. For fim são atualizados os índices para os humanos, pois as
  quantidades de agentes nas localidades foram alterados.

  O método "for_each_n" é responsável pela aplicação do operador
  "InsercaoHumanos" para a inserção dos novos agentes humanos.
*/
void Simulacao::insercaoHumanos() {
  // auto start = high_resolution_clock::now();
  int n = transform_reduce(
            seeds->idx, seeds->idx + 1,
            PreInsercaoHumanos(parametros, ciclo, ambiente),
            0, plus<int>()
          );
  if (n > 0) {
    int m = count_if(
              humanos->humanosDev->begin(),
              humanos->humanosDev->end(),
              EstaMortoHumano()
            );

    if (n > m) {
      humanos->nHumanos += (n - m);
      humanos->humanosDev->resize(humanos->nHumanos, Humano());
      humanos->PhumanosDev = raw_pointer_cast(humanos->humanosDev->data());
    }

    partition(
      humanos->humanosDev->begin(),
      humanos->humanosDev->end(),
      EstaMortoHumano()
    );

    for_each_n(
      seeds->idx, 1,
      InsercaoHumanos(humanos, ambiente, parametros, ciclo, seeds)
    );

    humanos->atualizacaoIndices();
  }
  // auto stop = high_resolution_clock::now();
  // auto duration = duration_cast<microseconds>(stop - start);
  // cout << "insercaoHumanos(): ";
  // cout << duration.count() << " microsecs" << endl;
}

/*
  Método responsável pelo processamento das saídas resultantes do ciclo de
  simulação. As saídas populacionais são geradas paralelamente para cada
  subpopulação computada. Já as saídas espaciais são geradas paralelamente para
  cada posição do ambiente. As chamadas aos métodos "for_each_n" são responsáveis
  pela aplicação dos operadores sobre os dados.
*/
void Simulacao::computarSaidas() {
  for_each_n(
    seeds->idx, N_COLS_H,
    ContPopTH(humanos, saidas, ciclo - 1)
  );
  for_each_n(
    seeds->idx, N_COLS_H,
    ContPopQH(humanos, saidas, ciclo - 1)
  );
  for_each_n(
    seeds->idx, N_COLS_H,
    ContPopNovoQH(humanos, saidas, ciclo - 1)
  );
  for_each_n(
    seeds->idx, ambiente->sizePos,
    ContEspacialH(
      humanos, saidas, ambiente, parametros->nCiclos, ciclo - 1
    )
  );
  for_each_n(
    seeds->idx, ambiente->sizePos,
    ContEspacialNovoH(
      humanos, saidas, ambiente, parametros->nCiclos, ciclo - 1
    )
  );
  for_each_n(
    seeds->idx, N_COLS_H,
    ContPopNovoTH(humanos, saidas, ciclo - 1)
  );
  for_each_n(
    seeds->idx, N_COLS_H,
    ContPopNovoQH(humanos, saidas, ciclo - 1)
  );

  for_each_n(
    seeds->idx, N_COLS_MD,
    ContPopTMD(mosquitos, saidas, ciclo - 1)
  );
  for_each_n(
    seeds->idx, N_COLS_MD,
    ContPopQMD(mosquitos, saidas, ciclo - 1)
  );
  for_each_n(
    seeds->idx, ambiente->sizePos,
    ContEspacialMD(
      mosquitos, saidas, ambiente, parametros->nCiclos, ciclo - 1
    )
  );
  for_each_n(
    seeds->idx, N_COLS_MD,
    ContPopNovoTMD(mosquitos, saidas, ciclo - 1)
  );

  for_each_n(
    seeds->idx, N_COLS_MW,
    ContPopTMW(mosquitos, saidas, ciclo - 1)
  );
  for_each_n(
    seeds->idx, N_COLS_MW,
    ContPopQMW(mosquitos, saidas, ciclo - 1)
  );
}

/*
  Método responsável pela exibição em tela do consumo de memória total em GPU
  para todas as estruturas de dados presentes na simulação. São utilizados os
  métodos "getMemoriaGPU" das distintas classes com dados relevantes à simulação.
  Como os métodos retornam a quantidade de mémoria em bytes, este valor é
  convertido para MB para facilitar a leitura. São considerados os dados das
  classes "Seeds", "Humanos", "Mosquitos", "Saidas", "Parametros" e "Ambiente".
*/
void Simulacao::exibirConsumoMemoria() {
  double totMem = 0;
  totMem += seeds->getMemoriaGPU();
  totMem += humanos->getMemoriaGPU();
  totMem += mosquitos->getMemoriaGPU();
  totMem += saidas->getMemoriaGPU();
  totMem += parametros->getMemoriaGPU();
  totMem += ambiente->getMemoriaGPU();
  cout << (totMem / (1 << 20)) << "MB" << endl;
}

/*
   Método responsável por gerar as saídas de bitstring
   para agentes do tipo mosquito.
*/
void Simulacao::saidaBitstringMosquitos() {
  // Calcula o total de mosquitos e copia os bitstrings da GPU para a CPU
  int nMosquitos = mosquitos->nMosquitos;
  Mosquito *vetorMosquitos = new Mosquito[nMosquitos]();
  copy_n(mosquitos->mosquitosDev->begin(), nMosquitos, vetorMosquitos);

  string nomeArquivo = string("mosquitos_");
  nomeArquivo += to_string(ciclo - 1);
  if (saidaSubciclo) {
    nomeArquivo += string("-");
    nomeArquivo += to_string(periodo);
    nomeArquivo += string("-");
    nomeArquivo += to_string(subciclo);
  }
  nomeArquivo += string(".csv");

  // Abre o arquivo de saída para mosquitos
  string saida = saidaM + nomeArquivo;
  ofstream arquivo(saida);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << saida;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  // cout << "Salvando arquivo " << saida << endl;

  // Escreve os valores dos bitstrings no arquivo de saída
  arquivo << "ID;T1;T2;T3;T4" << endl;
  for (int i = 0; i < nMosquitos; ++i) {
    arquivo << vetorMosquitos[i].id << ";";
    arquivo << vetorMosquitos[i].t1 << ";";
    arquivo << vetorMosquitos[i].t2 << ";";
    arquivo << vetorMosquitos[i].t3 << ";";
    arquivo << vetorMosquitos[i].t4 << endl;
  }
  arquivo.close();

  // Libera a memória alocada para o vetor de mosquitos na CPU
  delete[](vetorMosquitos);
}

/*
   Método responsável por gerar as saídas de bitstring
   para agentes do tipo humano.
*/
void Simulacao::saidaBitstringHumanos() {
  // Calcula o total de humanos e copia os bitstrings da GPU para a CPU
  int nHumanos = humanos->nHumanos;
  Humano *vetorHumanos = new Humano[nHumanos]();
  copy_n(humanos->humanosDev->begin(), nHumanos, vetorHumanos);

  string nomeArquivo = string("humanos_");
  nomeArquivo += to_string(ciclo - 1);
  if (saidaSubciclo) {
    nomeArquivo += string("-");
    nomeArquivo += to_string(periodo);
  }
  nomeArquivo += string(".csv");

  // Abre o arquivo de saída para humanos
  string saida = saidaH + nomeArquivo;
  ofstream arquivo(saida);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << saida;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  // cout << "Salvando arquivo " << saida << endl;

  // Escreve os valores dos bitstrings no arquivo de saída
  arquivo << "ID;T1;T2;T3;T4" << endl;
  for (int i = 0; i < nHumanos; ++i) {
    arquivo << vetorHumanos[i].id << ";";
    arquivo << vetorHumanos[i].t1 << ";";
    arquivo << vetorHumanos[i].t2 << ";";
    arquivo << vetorHumanos[i].t3 << ";";
    arquivo << vetorHumanos[i].t4 << endl;
  }
  arquivo.close();

  // Libera a memória alocada para o vetor de humanos na CPU.
  delete[](vetorHumanos);
}

/*
  Método responsável por gerar as saídas de distribuição
  espacial da densidade de ovos.
*/
void Simulacao::saidaOviposicao() {
  int nFocos = ambiente->sizeFocos;
  int *capFocos = new int[nFocos]();
  copy_n(ambiente->capFocosDev->begin(), ambiente->sizeFocos, capFocos);

  ofstream arquivo(arquivoSaidaOviposicao, ofstream::app);
  if (not arquivo.is_open()) {
    cerr << "Arquivo: ";
    cerr << arquivoSaidaOviposicao;
    cerr << " nao foi aberto!" << endl;
    exit(1);
  }

  // cout << "Escrevendo no arquivo " << arquivoSaidaOviposicao << endl;

  arquivo << (ciclo - 1);
  for (int i = 0; i < ambiente->sizeFocos; i++) {
    arquivo << ";" << capFocos[i];
  }
  arquivo << endl;
  arquivo.close();

  delete[](capFocos);
}
