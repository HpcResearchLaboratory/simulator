#include <simulator/util/rand_perc.hpp>

/*
  Classe responsável pela geração de números aleatórios em CPU. Cada instância 
  da classe armazena os seeds, geradores e distribuição própria. É utilizada 
  a distribuição uniforme à geração dos números aleatórios, assim como é feito 
  para os números aleatórios gerados em GPU. 
*/
RandPerc::RandPerc() {
  seed = system_clock::now().time_since_epoch().count();
  gen = dre(seed);
  dis = urd<double>(0.0, 1.0);
}

/*
  Operador () da classe RandPerc, responsável por retornar um número 
  aleatório no intervalo [0.0, 1.0). 
*/
double RandPerc::operator()() {
  return dis(gen);
}
