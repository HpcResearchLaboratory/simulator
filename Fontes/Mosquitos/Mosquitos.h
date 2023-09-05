#ifndef __MOSQUITOS__
#define __MOSQUITOS__

#include <thrust/copy.h>
#include <thrust/count.h>
#include <thrust/iterator/constant_iterator.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/device_vector.h>
#include <thrust/reduce.h>
#include <thrust/replace.h>
#include <thrust/scan.h>
#include <thrust/set_operations.h>
#include <thrust/sort.h>
#include <thrust/transform.h>
#include <thrust/transform_reduce.h>

template <class T>
using DVector = thrust::device_vector<T>;

using thrust::copy;
using thrust::count;
using thrust::counting_iterator;
using thrust::constant_iterator;
using thrust::inclusive_scan;
using thrust::make_constant_iterator;
using thrust::make_counting_iterator;
using thrust::raw_pointer_cast;
using thrust::reduce_by_key;
using thrust::replace;
using thrust::set_difference;
using thrust::sort;
using thrust::transform_reduce;
using thrust::transform;

class Parametros;
class Ambiente;

struct Mosquito {

  unsigned id, t1, t2, t3, t4;

  __host__ __device__
  Mosquito();

};

struct EstaMortoMosquito {

  __host__ __device__
  bool operator()(Mosquito mosquito);

};

struct MosquitoFemeaSuscetivelAlado {

  __host__ __device__
  bool operator()(Mosquito mosquito);

};

struct MosquitoFemeaAlado {

  __host__ __device__
  bool operator()(Mosquito mosquito);

};

struct LessQuadraMosquito {

  __host__ __device__
  bool operator()(Mosquito mosquito1, Mosquito mosquito2);

};

struct ToQuadraMosquito {

  __host__ __device__
  int operator()(Mosquito mosquito);

};

class Mosquitos {

  public:

  Parametros *parametros; Ambiente *ambiente;
  Mosquito *mosquitos; int nMosquitos, maxMosquitos;
  DVector<Mosquito> *mosquitosDev; Mosquito *PmosquitosDev;
  DVector<int> *indMosquitosDev; int *PindMosquitosDev;
  int sizeIndMosquitos, nDistRurMos; bool alocarMosquitos;

  counting_iterator<int> t;
  constant_iterator<int> v1;

  Mosquitos(Parametros *parametros, Ambiente *ambiente);
  ~Mosquitos();
  void atualizacaoIndices();
  int getMemoriaGPU();

  private:

  void toGPU();

  void inicializarMosquito(
    int id, int s, int sw, int fs, int ie, int sd, int st,
    int q, int l, int x, int y
  );

  void inserirMosquitos(
    int quantidade, int s, int sw, int fs,
    int sd, int st, int& i
  );

  void inserirOvosEmFocos(
    int quantidade, int s, int sw, int fs,
    int sd, int st, int& i
  );

  void criarMosquitos();
  void contarMosquitos();

};

#endif
