#ifndef __MOVIMENTACAO_HUMANOS__
#define __MOVIMENTACAO_HUMANOS__

#include <thrust/random.h>

using dre = thrust::default_random_engine;
template <class T>
using urd = thrust::uniform_real_distribution<T>;

class Ambiente;
class Parametros;
class Seeds;
class Humanos;
class Humano;
class Posicao;
class Vizinhanca;
class Fronteira;
class Esquina;

struct MovimentacaoHumanos {

  Humano *humanos; double *parametros; int sizePos;
  int *indQuadras, *indViz, *indFron, *indEsq;
  Esquina *esq, *cEsq; Fronteira *fron; Vizinhanca *viz;
  int *indCEsq, *indRotas, *rotas, *indTraj, *indPeri, *peri;
  Posicao *pos;
  dre *seeds;

  MovimentacaoHumanos(Humanos *humanos, Ambiente *ambiente,
                      Parametros *parametros, Seeds *seeds);
  __host__ __device__
  void operator()(int id);

  private:

  __host__ __device__
  void movimentacaoLocal(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoAleatoria(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoLivre(int id, dre& seed, urd<double>& dist);
  __host__ __device__
  void movimentacaoTrajeto(int id, dre& seed, urd<double>& dist);
  
  __host__ __device__
  int nVertVizinhos(int x, int y, int q, int l);
  __host__ __device__
  int nVertVizinhos(int x, int y, int q, int l, int ld);
  __host__ __device__
  int nVertVizinhos(int x, int y, int q, int l, int qd, int ld);

  __host__ __device__
  int getVertK(int k, int x, int y, int q, int l);
  __host__ __device__
  int getVertK(int k, int x, int y, int q, int l, int ld);
  __host__ __device__
  int getVertK(int k, int x, int y, int q, int l, int qd, int ld);

  __host__ __device__
  int getVertProxVizIn(
    int x, int y, int q, int l,
    int xd, int yd, int ld
  );
  __host__ __device__
  int getVertProxVizIn(
    int x, int y, int q, int l,
    int xd, int yd, int qd, int ld
  );
  __host__ __device__
  int getVertProxVizIn(
    int x, int y, int q, int l,
    int xd, int yd, int qd, int ld, int xmin, int ymin
  );

  __host__ __device__
  int getVertProxVizEx(
    int x, int y, int q, int l,
    int xd, int yd, int ld
  );
  __host__ __device__
  int getVertProxVizEx(
    int x, int y, int q, int l,
    int xd, int yd, int qd, int ld
  );
  __host__ __device__
  int getVertProxVizEx(
    int x, int y, int q, int l,
    int xd, int yd, int qd, int ld, int xmin, int ymin
  );

  __host__ __device__
  int getVertProxEsqIn(int l, int xd, int yd);
  __host__ __device__
  void moveHumano(int id, int k);

};

#endif
