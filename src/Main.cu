#include <iostream>
#include <string>

#include "Fontes/Macros/MacrosSO.h"
#include "Fontes/MonteCarlo.h"

using std::cout;
using std::endl;
using std::string;
using std::to_string;

/*
  Método responsável por apresentar uma tela de ajuda com as opções 
  disponíveis por linha de comando. Estas posições são: 

  "--help -h": mostra a tela de ajuda; 
  "--device -d": especifica a GPU para execução da simulação; 
  "--nmontecarlos -m": especifica a quantidade de simulações Monte Carlo.
  "--saidasubciclo -s": controla a saída bitstring em períodos e subciclos.
*/
void help(string exe) {
  cout << "Uso: " << exe << " <opcoes>\n"
       << "Opcoes:\n"
       << "\t--help, -h\t\tMostra esta ajuda\n"
       << "\t--device, -d ID_DEVICE\tEspecifica a GPU para execucao\n"
       << "\t--nmontecarlos, -m QUANT_MCS\tEspecifica a quantidade de simulacoes MC\n"
       << "\t--saidasubciclo, -s SAIDA_SUB\tControla a saida bitstring em periodos e subciclos\n";
}

/*
  Método inicial do programa. 

  Este método é responsável por:
  - interpretar as opções passadas por linha de comando;
  - alterar a GPU utilizada para execução;
  - excluir pasta de saída se já existente;
  - iniciar a execução das simulações Monte Carlo. 

  Valores padrão:
  - "idDevice": 0. Utilizará a primeira GPU encontrada. A id das GPUs pode 
                   ser vista com o utilitário "deviceQuery" presente no 
                   SDK do CUDA. 
  - "quantMCS": 1. Executará uma simulação Monte Carlo com os arquivos de 
                   entrada presentes na pasta "Entradas/MonteCarlo_0". 
                   Se informado um número maior que 1 serão executadas 
                   simulações utilizando os arquivos presentes nas pastas 
                   "Entradas/MonteCarlo_{1}", em que "{1}" designa o id da 
                   simulação, iniciando em "0" até "quantMCS - 1".
*/
int main(int argc, char **argv) {
  int idDevice = 0, quantMCs = 1, saidaSubciclo = 0;

  // Interpreta os argumentos passados por linha do comando, se existentes. 
  if (argc > 1) {
    for (int i = 1; i < argc; i += 2) {
      string textoOpcao(argv[i]);

      if (textoOpcao == "--help" or textoOpcao == "-h") {
        help(argv[0]);
        return 0;
      }
      if (textoOpcao == "--device" or textoOpcao == "-d") {
        idDevice = atoi(argv[i + 1]);
      } 
      if (textoOpcao == "--nmontecarlos" or textoOpcao == "-m") {
        quantMCs = atoi(argv[i + 1]);
      }
      if (textoOpcao == "--saidasubciclo" or textoOpcao == "-s") {
        saidaSubciclo = atoi(argv[i + 1]);
      }
    }
  }

  // Altera a GPU que será utilizada para execução. 
  cudaSetDevice(idDevice);

  // Exclui a pasta de saída, se já existente. 
  system((EXCLUIR_PASTA + string("Saidas")).c_str());

  string entrada, saida;
  for (int idMC = 0; idMC < quantMCs; idMC++) {
    // O caminho para a pasta de entrada será "Entradas/MonteCarlo_{idMC}/"
    entrada = string("Entradas");
    entrada += SEP;
    entrada += string("MonteCarlo_");
    entrada += to_string(idMC);
    entrada += SEP;

    // O caminho para a pasta de saída será "Saidas/MonteCarlo_{idMC}/"
    saida = string("Saidas");
    saida += SEP;
    saida += string("MonteCarlo_");
    saida += to_string(idMC);
    saida += SEP;

    // Inicia a execução da simulação tipo Monte Carlo. 
    MonteCarlo(entrada, saida, saidaSubciclo);
  }

  return 0;
}
