#ifndef __SAIDAS_MOSQUITOS__
#define __SAIDAS_MOSQUITOS__

class Ambiente;
class Saidas;
class Mosquitos;
class Mosquito;
class Posicao;

struct ContPopTMD {

  Mosquito *mosquitos; int *popT, ciclo; int nMosquitos;

  ContPopTMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContPopQMD {

  Mosquito *mosquitos; int *indPopQ, *popQ, ciclo; int nMosquitos;

  ContPopQMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContEspacialMD {

  Mosquito *mosquitos; 
  int *espacial, ciclo, nCiclos, *indMosquitos; Posicao *pos;

  ContEspacialMD(
    Mosquitos *mosquitos, Saidas *saidas, Ambiente *ambiente,
    int nCiclos, int ciclo
  );

  __host__ __device__
  void operator()(int id);

};

struct ContPopTMW {

  Mosquito *mosquitos; int *popT, ciclo; int nMosquitos;

  ContPopTMW(Mosquitos *mosquitos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContPopQMW {

  Mosquito *mosquitos; int *indPopQ, *popQ, ciclo; int nMosquitos;

  ContPopQMW(Mosquitos *mosquitos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContPopNovoTMD {

  Mosquito *mosquitos; int *popNovoT, ciclo; int nMosquitos;

  ContPopNovoTMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

struct ContPopNovoQMD {

  Mosquito *mosquitos; int *indPopQ, *popQ, ciclo; int nMosquitos;

  ContPopNovoQMD(Mosquitos *mosquitos, Saidas *saidas, int ciclo);

  __host__ __device__
  void operator()(int id);

};

#endif