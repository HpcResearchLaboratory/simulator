#ifndef __HUMANOS__
#define __HUMANOS__

#include <thrust/count.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/constant_iterator.h>
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
using thrust::transform;
using thrust::transform_reduce;

class Ambiente;
class Parametros;

struct Humano {
  unsigned id, t1, t2, t3, t4;
  __host__ __device__
  Humano();
};

struct EstaMortoHumano {
  __host__ __device__
  bool operator()(Humano humano);
};

struct HumanoSuscetivel {
  __host__ __device__
  bool operator()(Humano humano);
};

struct MenorIdLocalidadeHumano {
  __host__ __device__
  bool operator()(Humano humano1, Humano humano2);
};

struct GetIdLocalidadeHumano {
  __host__ __device__
  int operator()(Humano humano);
};

class Humanos {

  public:

  Parametros *parametros; Ambiente *ambiente;
  Humano *humanos; int nHumanos;
  DVector<Humano> *humanosDev; Humano *PhumanosDev;
  DVector<int> *indHumanosDev; int *PindHumanosDev;
  int sizeIndHumanos;

  counting_iterator<int> t;
  constant_iterator<int> v1;

  Humanos(Parametros *parametros, Ambiente *ambiente);
  ~Humanos();
  void atualizacaoIndices();
  int getMemoriaGPU();

  private:

  void toGPU();
  void criarHumanos();
  void contarHumanos();
  
  void inicializarHumano(
    int id, int e, int x, int y, int l,  int q,
    int s, int fe, int t, int k, int st, int a
  );

  void inserirHumanos(
    int n, int estado, int sexo, int fe, int mov, int& i
  );

};

#endif
