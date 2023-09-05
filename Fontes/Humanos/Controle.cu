#include "Controle.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Macros/4_CON_H.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador é paralelizado para cada AGENTE.

  Percorre o vetor de humanos e aplica a taxa de mortalidade natural,
  definida por TAXA_MORTE_NATURAL.
*/
ControleNaturalHumanos::ControleNaturalHumanos(
  Humanos *humanos, Parametros *parametros, Seeds *seeds
) {
  this->humanos = humanos->PhumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe ControleNaturalHumanos.
*/
__host__ __device__
void ControleNaturalHumanos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  if (randPerc <= TAXA_MORTE_NATURAL) {
    SET_SD_H(id, MORTO);
  }
}
