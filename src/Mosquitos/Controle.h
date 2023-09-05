#ifndef __CONTROLE_MOSQUITOS__
#define __CONTROLE_MOSQUITOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Ambiente;
class Parametros;
class Seeds;
class Mosquitos;
class Mosquito;
class Posicao;
class Controle;
class Vizinhanca;
class Climatico;

struct ControleNaturalMosquitosPorIdade {

  Mosquito *mosquitos; double *parametros;
  dre *seeds;

  ControleNaturalMosquitosPorIdade(
    Mosquitos *mosquitos, Parametros *parametros, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

};

struct ControleNaturalMosquitosPorSelecao {

  Mosquito *mosquitos; double *parametros;
  int ciclo, *indMosquitos, *indQuadras, *indFocos, *focos, *capFocos;
  Posicao *pos; Climatico *cli;
  dre *seeds;
  int idLira, nLira, *contrLira;
  int sizePontEst, *pontEst;

  ControleNaturalMosquitosPorSelecao(
    Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
    int ciclo, int idLira, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void remove(
    dre& seed, urd<double>& dist, int idM,
    int s, int sw, int fs, double prob
  );

  __host__ __device__
  int getIdFoco(int idM);
  __host__ __device__
  bool estaEmFoco(int x, int y, int q, int l);
  __host__ __device__
  bool estaEmPE(int q, int l);

};

struct PreControlesMosquitos {

  double *parametros;
  int ciclo, idContr; Controle *contr;
  dre *seeds;

  PreControlesMosquitos(
    Ambiente *ambiente, Parametros *parametros,
    int ciclo, int idContr, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);
};

struct ControlesMosquitos {

  Mosquito *mosquitos; double *parametros;
  int ciclo, idContr; Controle *contr; Posicao *pos;
  int *indMosquitos, *pontEst, sizePontEst;
  int *indContrPontos; Posicao *contrPontos;
  int *indRaios; Posicao *raios;
  dre *seeds;

  ControlesMosquitos(
    Mosquitos *mosquitos, Ambiente *ambiente,
    Parametros *parametros, int ciclo, int idContr,
    int sizePontEst, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  bool temRaio(int q, int l, int x, int y);
  __host__ __device__
  bool temBloqueio(int q, int l, int x, int y);
  __host__ __device__
  bool temPE(int q, int l);
  __host__ __device__
  bool temTratamento(int q, int l, int x, int y);

  __host__ __device__
  void controleQuimicoNaoAlados(
    dre& seed, urd<double>& dist,
    int x, int y, int l, int q, double taxa
  );

  __host__ __device__
  void controleMecanicoNaoAlados(
    dre& seed, urd<double>& dist,
    int x, int y, int l, int q
  );

  __host__ __device__
  void controleQuimicoAlados(
    dre& seed, urd<double>& dist,
    int x, int y, int l, int q
  );
};

struct PosControlesMosquitos {

  double *parametros;
  int idContr; Controle *contr;
  dre *seeds;

  PosControlesMosquitos(
    Ambiente *ambiente, Parametros *parametros,
    int idContr, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);
};

struct PreControleBiologico {

  double *parametros; int ciclo;

  PreControleBiologico(Parametros *parametros, int ciclo);

  __host__ __device__
  int operator()(int id);

};

struct ControleBiologico {

  Mosquito *mosquitos; double *parametros; bool alocarMosquitos;
  int ciclo, *conBio, *nLotes, *indQuadras, *indPos; Posicao *pos;
  dre *seeds;

  ControleBiologico(
    Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
    int ciclo, bool alocarMosquitos, Seeds *seeds
  );

  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void inicializarMosquito(
    int id, int s, int sw, int fs, int ie,
    int sd, int st, int q, int l, int x, int y
  );

  __host__ __device__
  void inserirMosquitos(
    dre& seed, urd<double>& dist, int quantidade, int s,
    int sw, int fs, int sd, int st, int q, int& i
  );

};

struct TratamentoAmbiental {

  Mosquito *mosquitos; double *parametros;
  int ciclo, sizeConAmb, *conAmb, *indMosquitos;
  dre *seeds;

  TratamentoAmbiental(
    Mosquitos *mosquitos, Ambiente *ambiente, Parametros *parametros,
    int ciclo, int sizeConAmb, Seeds *seeds
  );
  
  __host__ __device__
  void operator()(int id);

};

#endif
