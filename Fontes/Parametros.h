#ifndef __PARAMETROS__
#define __PARAMETROS__

#include <fstream>
#include <iostream>
#include <limits>
#include <string>

#include <thrust/device_vector.h>

using std::cerr;
using std::endl;
using std::ifstream;
using std::fstream;
using std::numeric_limits;
using std::string;
using std::streamsize;

template <class T>
using DVector = thrust::device_vector<T>;

using thrust::raw_pointer_cast;

class Parametros {

  public:

  string entradaMC;
  int nParametros, nSims, nCiclos, nSubCiclos;
  double *parametros; DVector<double> *parametrosDev; double *PparametrosDev; 
  streamsize sMax = numeric_limits<streamsize>::max();

  Parametros(string entradaMC);
  int getMemoriaGPU();
  ~Parametros();

  private:

  void toGPU();
  void lerArquivo(string pasta, string nomeArquivo, int& i, int nPar);
  void lerParametros();

};

#endif
