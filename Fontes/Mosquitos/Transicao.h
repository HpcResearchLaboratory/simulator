#ifndef __TRANSICAO_MOSQUITOS__
#define __TRANSICAO_MOSQUITOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Ambiente;
class Parametros;
class Seeds;
class Mosquitos;
class Mosquito;
class Posicao;

struct TransicaoFasesMosquitos {

  Mosquito *mosquitos;
  double *parametros;
  dre *seeds;
  int *indMosquitos;
  Posicao *pos;
  int *indQuadras;
  int *indFocos;
  int *focos;
  int *capFocos;

  TransicaoFasesMosquitos(
    Ambiente *ambiente, Mosquitos *mosquitos,
    Parametros *parametros, Seeds *seeds
  );
  
  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  int getIdFoco(int x, int y, int q, int l);

};

struct TransicaoEstadosMosquitos {

  Mosquito *mosquitos;
  double *parametros;
  dre *seeds;

  TransicaoEstadosMosquitos(
    Mosquitos *mosquitos, Parametros *parametros, Seeds *seeds
  );
  
  __host__ __device__
  void operator()(int id);

};

#endif
