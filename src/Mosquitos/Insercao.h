#ifndef __INSERCAO_MOSQUITOS__
#define __INSERCAO_MOSQUITOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Ambiente;
class Seeds;
class Mosquitos;
class Mosquito;
class Parametros;
class Posicao;
class PopMosquitos;

struct PreInsercaoMosquitos {

  int ciclo;
  PopMosquitos *distMosquitos;
  int sizeDistMosquitos;

  PreInsercaoMosquitos(int ciclo, Ambiente *ambiente);
  __host__ __device__
  int operator()(int id);

};

struct InsercaoMosquitos {

  Mosquito *mosquitos;
  int ciclo, nMosquitos;
  int sizeDistMosquitos;
  PopMosquitos *distMosquitos;
  double *parametros; 
  int *nLotes, *indPos, *indQuadras; Posicao *pos;
  int sizePontEst, *pontEst;
  dre *seeds;

  InsercaoMosquitos(
    Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
    int ciclo, int sizePontEst, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void inicializarMosquito(
    int id, int s, int sw, int fs, int ie, int sd, int st, int q, 
    int l, int x, int y
  );

};

#endif
