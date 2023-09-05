#ifndef __MOVIMENTACAO_MOSQUITOS__
#define __MOVIMENTACAO_MOSQUITOS__

#include <thrust/random.h>
#include <thrust/tuple.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

using thrust::tuple;
using thrust::get;

class Ambiente;
class Parametros;
class Seeds;
class Mosquitos;
class Humanos;
class Mosquito;
class Humano;
class Posicao;
class Vizinhanca;
class Fronteira;
class Esquina;

struct MovimentacaoMosquitos {

  Mosquito *mosquitos; Humano *humanos; double *parametros;
  int *indQuadras, *indViz, *indFron;
  Fronteira *fron; Vizinhanca *viz;
  int *indPos, *indEsq; Posicao *pos; Esquina *esq, *cEsq;
  int *indCEsq, *indRotas, *rotas, *indTraj;
  int *indPeri, *peri, *pontEst, sizePontEst, periodo;
  int *indMosquitos, *indHumanos;
  int *indFocos, *focos, *capFocos;
  dre *seeds;

  MovimentacaoMosquitos(
    Mosquitos *mosquitos, Humanos *humanos, Ambiente *ambiente,
    Parametros *parametros, int periodo, int sizePontEst, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void movimentacaoDiurna(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoAleatoria(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoLocal(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoFemea(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoFemeaNaoAcasalada(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoFemeaAcasalada(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoAleatoriaVooLevy(
    double percVooLevy, int id, dre& seed, urd<double>& dist
  );

  __host__ __device__
  bool buscaMacho(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  bool buscaPE(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  bool buscaHumano(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  bool buscaFoco(int id, dre& seed, urd<double>& dist);

  __host__ __device__
  bool temMacho(int x, int y, int l, int q, tuple<int, int>& tu, double raio);
  __host__ __device__
  bool temPE(int x, int y, int l, int q, tuple<int, int>& tu, double raio);
  __host__ __device__
  bool temHumano(int x, int y, int l, int q, tuple<int, int>& tu, double raio);
  __host__ __device__
  bool estaEmPE(int quadra, int lote);

  __host__ __device__
  void vooLevy(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void moveMosquitoParaRua(int idMosquito);

  __host__ __device__
  int nVertVizinhos(int x, int y, int l, int q);
  __host__ __device__
  int nVertVizinhos(int x, int y, int l, int q, int qd);
  __host__ __device__
  int nVertVizinhos(int x, int y, int l, int q, int ld, int qd);
  __host__ __device__
  int getVertK(int k, int x, int y, int l, int q);
  __host__ __device__
  int getVertK(int k, int x, int y, int l, int q, int qd);
  __host__ __device__
  int getVertK(int k, int x, int y, int l, int q, int ld, int qd);
  __host__ __device__
  int getVertVL(
    int x, int y, int l, int q, int xo, int yo,
    double dist2, dre& seed, urd<double>& dist
  );

  __host__ __device__
  int getVertProxVizIn(int x, int y, int l, int q, int xd, int yd);
  __host__ __device__
  int getVertProxVizIn(
    int x, int y, int l, int q, int xd, int yd, int ld, int qd
  );

  __host__ __device__
  void moveMosquito(int id, int k);
  
};

#endif
