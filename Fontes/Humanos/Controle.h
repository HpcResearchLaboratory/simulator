#ifndef __CONTROLE_HUMANOS__
#define __CONTROLE_HUMANOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Seeds;
class Humanos;
class Humano;
class Parametros;

struct ControleNaturalHumanos {

  Humano *humanos; double *parametros; dre *seeds;

  ControleNaturalHumanos(Humanos *humanos, Parametros *parametros,
                         Seeds *seeds);
  __host__ __device__
  void operator()(int id);

};

#endif
