#ifndef __SAIDAS_HUMANOS__
#define __SAIDAS_HUMANOS__

class Ambiente;
class Saidas;
class Humano;
class Humanos;
class Posicao;

struct ContPopTH {

  Humano *humanos; int *popT, ciclo; int nHumanos;

  ContPopTH(Humanos *humanos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContPopQH {

  Humano *humanos; int *indPopQ, *popQ, ciclo; int nHumanos;

  ContPopQH(Humanos *humanos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContEspacialH {

  Humano *humanos; 
  int *espacial, ciclo, nCiclos, *indHumanos;
  Posicao *pos;

  ContEspacialH(
    Humanos *humanos, Saidas *saidas, Ambiente *ambiente,
    int nCiclos, int ciclo
  );

  __host__ __device__
  void operator()(int id);

};

struct ContPopNovoTH {

  Humano *humanos; int *popNovoT, ciclo; int nHumanos;

  ContPopNovoTH(Humanos *humanos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContPopNovoQH {

  Humano *humanos; int *indPopQ, *popQ, ciclo; int nHumanos;

  ContPopNovoQH(Humanos *humanos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContEspacialNovoH {

  Humano *humanos; 
  int *espacial, ciclo, nCiclos, *indHumanos;
  Posicao *pos;

  ContEspacialNovoH(
    Humanos *humanos, Saidas *saidas, Ambiente *ambiente,
    int nCiclos, int ciclo
  );

  __host__ __device__
  void operator()(int id);

};

#endif
