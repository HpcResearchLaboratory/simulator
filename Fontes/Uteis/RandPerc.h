#ifndef __RAND_PERC__
#define __RAND_PERC__

#include <chrono>

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

using namespace std::chrono;

class RandPerc {

  unsigned seed; dre gen;
  urd<double> dis;

  public:

  RandPerc();
  double operator()();

};

#endif
