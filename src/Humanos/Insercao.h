#ifndef __INSERCAO_HUMANOS__
#define __INSERCAO_HUMANOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Ambiente;
class Parametros;
class Seeds;
class Humanos;
class Humano;
class Posicao;
class Caso;

struct PreInsercaoHumanos {
  double *parametros; int ciclo;
  int sizeDistHumanos;
  Caso *distHumanos;

  PreInsercaoHumanos(Parametros *parametros, int ciclo, Ambiente *ambiente);
  __host__ __device__
  int operator()(int id);
};

struct InsercaoHumanos {

  public:

  double *parametros; Humano *humanos;
  int ciclo, nHumanos, nNovosHumanos, *indTrajFE, *indTraj;
  int *indRotas, *rotas, *indQuadras, *indPos;
  Posicao *pos;
  int sizeDistHumanos;
  Caso *distHumanos;
  dre *seeds;

  InsercaoHumanos(Humanos *humanos, Ambiente *ambiente,
                  Parametros *parametros, int ciclo, Seeds *seeds);
  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void inserirHumanosTrajeto(
    dre& seed, urd<double>& dist, int qtde, int st, int& i
  );

  __host__ __device__
  void inserirHumanosAleatorio(int& i);
  
  __host__ __device__
  void inicializarHumano(
    int id, int e, int x, int y, int l, int q,
    int s, int i, int t, int k, int st
  );

};

#endif
