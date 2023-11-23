#ifndef __SIMULACAO__
#define __SIMULACAO__

class Seeds;
class Parametros;
class Ambiente;
class Saidas;
class Humanos;
class Mosquitos;

#include <cmath>

#include <thrust/copy.h>
#include <thrust/count.h>
#include <thrust/for_each.h>
#include <thrust/functional.h>
#include <thrust/partition.h>

using std::abs;
using std::cerr;
using std::cout;
using std::endl;
using std::ofstream;
using std::pow;
using std::string;
using std::to_string;

using thrust::copy;
using thrust::count_if;
using thrust::for_each_n;
using thrust::partition;
using thrust::plus;
using thrust::raw_pointer_cast;

/*
  Classe responsável por armazenar todos os dados associados à execução de uma
  simulação individual.
*/
class Simulacao {

  int idSim, ciclo, periodo, subciclo;
  string saidaSim;
  Seeds *seeds;
  Parametros *parametros;
  Ambiente *ambiente;
  Saidas *saidas;
  Humanos *humanos;
  Mosquitos *mosquitos;
  int idLira;
  string saidaM, saidaH, arquivoSaidaOviposicao;
  int saidaSubciclo;

public:
  Simulacao(int idSim, string saidaSim, Saidas *saidas, Parametros *parametros,
            Ambiente *ambiente, int saidaSubciclo);

  ~Simulacao();

private:
  void iniciar();
  void calcularIdLira();
  void movimentacaoHumanos();
  void movimentacaoMosquitos();
  void contatoEntreMosquitos(int periodo);
  void contatoEntreMosquitosEHumanos(int periodo);
  void transicaoFasesMosquitos();
  void transicaoEstadosMosquitos();
  void transicaoEstadosHumanos();
  void vacinacao();
  void controleNaturalMosquitosPorIdade();
  void controleNaturalMosquitosPorSelecao();
  void controleNaturalHumanos();
  void controlesMosquitos();
  void controleBiologico();
  void tratamentoAmbiental();
  void geracao();
  void insercaoMosquitos();
  void insercaoHumanos();
  void computarSaidas();
  void exibirConsumoMemoria();
  void saidaBitstringMosquitos();
  void saidaBitstringHumanos();
  void saidaOviposicao();
};

#endif
