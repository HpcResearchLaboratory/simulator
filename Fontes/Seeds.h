#ifndef __SEEDS__
#define __SEEDS__

#include <algorithm>
#include <initializer_list>

#include <thrust/random.h>
#include <thrust/for_each.h>
#include <thrust/device_vector.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/tuple.h>

using std::generate;
using std::max;
using std::initializer_list;

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

template <class T>
using DVector = thrust::device_vector<T>;

using thrust::counting_iterator;
using thrust::for_each_n;
using thrust::get;
using thrust::make_counting_iterator;
using thrust::make_tuple;
using thrust::make_zip_iterator;
using thrust::raw_pointer_cast;
using thrust::zip_iterator;

struct InitSeeds {

  __host__ __device__ 
  void operator()(thrust::tuple<int, dre &> t);
  
};

class Seeds {

  public:

  int nSeeds; DVector<dre> *seedsDev; 
  dre *PseedsDev;

  counting_iterator<int> idx;
  
  Seeds(initializer_list<int> l);

  int getMemoriaGPU();
  ~Seeds();

};

#endif