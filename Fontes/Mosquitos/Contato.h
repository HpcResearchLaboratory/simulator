#ifndef __CONTATO_MOSQUITOS__
#define __CONTATO_MOSQUITOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Mosquito;
class Ambiente;
class Seeds;
class Parametros;
class Mosquitos;
class Posicao;

struct ContatoMosquitos {

  Mosquito *mosquitos; double *parametros;
  int *indMosquitos; Posicao *pos;
  dre *seeds; int periodo;

  ContatoMosquitos(
    Mosquitos *mosquitos, Ambiente *ambiente,
    Parametros *parametros, int periodo, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  int getMacho(int x, int y, int l, int q);

};

#endif
