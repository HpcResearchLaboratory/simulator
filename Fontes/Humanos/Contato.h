#ifndef __CONTATO_HUMANOS__
#define __CONTATO_HUMANOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Ambiente;
class Parametros;
class Seeds;
class Humanos;
class Humano;
class Mosquitos;
class Mosquito;
class Posicao;

struct ContatoHumanos {

  Mosquito *mosquitos; Humano *humanos; double *parametros;
  int ciclo, *indMosquitos, *indHumanos; double *comp;
  Posicao *pos; int periodo;
  dre *seeds;

  ContatoHumanos(Mosquitos *mosquitos, Humanos *humanos,
                 Ambiente *ambiente, Parametros *parametros, int ciclo,
                 int periodo, Seeds *seeds);
  __host__ __device__
  void operator()(int id);
  __host__ __device__
  void infeccaoHumano(int idMosquito, int idHumano, urd<double> dist, dre& seed);
  __host__ __device__
  void infeccaoMosquito(int idMosquito, int idHumano, urd<double> dist, dre& seed);
  __host__ __device__
  bool contraiuEsteSorotipo(int sc_h, int st_m);

};

#endif
