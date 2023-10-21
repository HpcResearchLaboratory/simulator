#include <simulator/macros/parameters.hpp>
#include <simulator/seeds.hpp>
#include <simulator/util/rand_perc.hpp>

/*
  Operador () da classe InitSeeds.

  Este método é responsável por inicializar as seeds para geração de
  números aleatórios em GPU. O primeiro elemento da tupla "t" é um id númerico
  da seed e o segundo elemento é a estrutura utilizada para geração dos
  números aleatórios.
*/
__host__ __device__ void InitSeeds::operator()(thrust::tuple<int, dre &> t) {
  int seed = get<0>(t);
  get<1>(t) = dre(seed);
}

/*
  Construtor da classe Seeds, que armazena todas as seeds utilizadas para a
  geração de números  aleatórios em GPU durante a execução de simulações.

  A variável "idx" armazena uma instância da classe "counting_iterator", que
  mimetiza um contador infinito, começando em "0". Esta variável é utilizada à
  geração de ids à execução dos métodos em GPU. Cada id indexa um dado que
  pode ser processado paralelamente aos outros dados do conjunto.

  O método realiza a geração de números aleatórios em CPU e os utiliza à
  geração das seeds em GPU.

  A quantidade de seeds geradas é obtida a partir do valor máximo encontrado
  na lista "l". A lista "l" é inicializada com os valores das quantidades de
  agentes humanos, agentes mosquitos e posições do ambiente.
*/
Seeds::Seeds(initializer_list<int> l) {
  // Inicialização do contador em 0.
  idx = make_counting_iterator(0);

  // Obtenção da quantidade de seeds necessárias.
  nSeeds = max(l);

  RandPerc rand;

  // Geração de números aleatórios em CPU.
  seedsDev = new DVector<dre>(nSeeds);
  int *rands = new int[nSeeds]();
  generate(rands, rands + nSeeds,
           [&]() { return (int)ENTRE_FAIXA(0, 100000, rand()); });
  DVector<int> randsDev(rands, rands + nSeeds);
  delete[] (rands);

  // Inicialização das seeds em GPU.
  for_each_n(make_zip_iterator(make_tuple(randsDev.begin(), seedsDev->begin())),
             nSeeds, InitSeeds());
  PseedsDev = raw_pointer_cast(seedsDev->data());
}

/*
  Método responsável pela obtenção do consumo de memória da classe Seeds.
*/
int Seeds::getMemoriaGPU() { return (nSeeds * sizeof(dre)); }

/*
  Destrutor da classe Seeds
*/
Seeds::~Seeds() { delete (seedsDev); }
