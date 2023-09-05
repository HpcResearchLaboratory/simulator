#ifndef __MONTE_CARLO__
#define __MONTE_CARLO__

#include <chrono>
#include <ctime>
#include <iomanip>
#include <iostream>
#include <string>

class Parametros;
class Ambiente;
class Saidas;

using std::cout;
using std::endl;
using std::put_time;
using std::localtime;
using std::time_t;
using std::string;
using std::to_string;

using namespace std::chrono;

class MonteCarlo {

  public:

  string entradaMC, saidaMC;
  int saidaSubciclo;
  Parametros *parametros; Ambiente *ambiente; Saidas *saidas;

  MonteCarlo(string entradaMC, string saidaMC, int saidaSubciclo);
  ~MonteCarlo();

  private:

  void iniciar();
  void exibirData();

};

#endif
