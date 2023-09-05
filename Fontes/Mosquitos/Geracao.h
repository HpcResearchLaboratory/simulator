#ifndef __GERACAO__
#define __GERACAO__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Parametros;
class Mosquito;
class Mosquitos;
class Seeds;
class Ambiente;
class Posicao;

struct PreGeracao {

  Mosquito *mosquitos;
  double *parametros;
  dre *seeds;
  int *indFocos;
  int *focos;
  int *indQuadras;
  Posicao *pos;

  PreGeracao(
    Ambiente *ambiente, Mosquitos *mosquitos,
    Parametros *parametros, Seeds *seeds
  );

  __host__ __device__
  int operator()(int id);

  private:

  __host__ __device__
  bool estaEmFoco(int id);

};

struct Geracao {

  Mosquito *mosquitos;
  int nMosquitos; 
  double *parametros;
  bool alocarMosquitos;
  dre *seeds;
  int *indFocos;
  int *focos;
  Posicao *pos;
  int *indQuadras;
  int *capFocos;

  Geracao(
    Ambiente *ambiente, Mosquitos *mosquitos,
    Parametros *parametros, Seeds *seeds
  );
  
  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void postura(int id, int& i);

  __host__ __device__
  void inserirOvos(int id, int& i, int total, double frac, int sw);

  __host__ __device__
  void inserirMosquitos(
    int quantidade, int s, int sw, int fs, int sd, int st, 
    int q, int l, int x, int y, int& i
  );

  __host__ __device__
  void inicializarMosquito(
    int id, int s, int sw, int fs, int sd, int st,
    int q, int l, int x, int y
  );

  __host__ __device__
  bool estaEmFoco(int id);

  __host__ __device__
  int getIdFoco(int id);

};

#endif
