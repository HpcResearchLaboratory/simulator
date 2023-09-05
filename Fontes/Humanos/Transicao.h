#ifndef __TRANSICAO_HUMANOS__
#define __TRANSICAO_HUMANOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Ambiente;
class Parametros;
class Seeds;
class Humanos;
class Humano;
class Vacinado;

struct TransicaoEstadosHumanos {

  public:

  Humano *humanos; double *parametros; dre *seeds;

  TransicaoEstadosHumanos(
    Humanos *humanos, Parametros *parametros, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void transicaoExposto(int idHumano, urd<double> dist, dre& seed);
  __host__ __device__
  void transicaoInfectante(int idHumano, urd<double> dist, dre& seed);
  __host__ __device__
  void transicaoHemorragico(int idHumano, urd<double> dist, dre& seed);
  __host__ __device__
  void transicaoRecuperado(int idHumano, urd<double> dist, dre& seed);
  __host__ __device__
  int contarSorotipos(int sc);

};

struct CampanhaVacinacao {

  // fEVac   Faixas etárias que serão vacinadas
  // perVac  Percentuais de vacinação
  // cicVac  Ciclos de ocorrência das campanhas de vacinação
  int *fEVac, sizeFEVac, *perVac, sizePerVac, *cicVac, sizeCicVac;

  Humano *humanos; double *parametros;
  int ciclo, *quadVac, sizeQuadVac;
  int *indHumanos;
  dre *seeds;

  CampanhaVacinacao(
    Humanos *humanos, Ambiente *ambiente, Parametros *parametros,
    int ciclo, int sizeQuadVac, int sizeFEVac, int sizePerVac,
    int sizeCicVac, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  bool periodoCampanhaVacinacao();
  __host__ __device__
  bool faixaEtariaTeraVacinacao(int fe);

};

struct PosCampanhaVacinacao {

  int ciclo;
  int *perVac, sizePerVac, *cicVac, sizeCicVac;

  PosCampanhaVacinacao(
    Ambiente *ambiente, int ciclo, int sizePerVac, int sizeCicVac
  );

  __host__ __device__
  void operator()(int id);

};

struct InsercaoVacinados {

  Humano *humanos; double *parametros;
  int ciclo; Vacinado *vacs;
  int *indHumanos; dre *seeds;

  InsercaoVacinados(
    Humanos *humanos, Ambiente *ambiente, Parametros *parametros,
    int ciclo, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

};

#endif
