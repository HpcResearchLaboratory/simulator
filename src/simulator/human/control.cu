#include <simulator/human/control.hpp>
#include <simulator/human/human.hpp>
#include <simulator/macros/4_CON_H.hpp>
#include <simulator/macros/general.hpp>
#include <simulator/macros/human.hpp>
#include <simulator/parameters.hpp>
#include <simulator/seeds.hpp>

/*
  Este operador é paralelizado para cada AGENTE.

  Percorre o vetor de humanos e aplica a taxa de mortalidade natural,
  definida por TAXA_MORTE_NATURAL.
*/
ControleNaturalHumanos::ControleNaturalHumanos(Humanos *humanos,
                                               Parametros *parametros,
                                               Seeds *seeds) {
  this->humanos = humanos->PhumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe ControleNaturalHumanos.
*/
__host__ __device__ void ControleNaturalHumanos::operator()(int id) {
  dre &seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  if (randPerc <= TAXA_MORTE_NATURAL) {
    SET_SD_H(id, MORTO);
  }
}
