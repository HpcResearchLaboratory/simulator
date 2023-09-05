#include "Movimentacao.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Macros/1_MOV_H.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador é paralelizado para cada AGENTE.

  Responsável pela movimentação dos agentes humanos pelo ambiente de
  simulação. Existem 4 tipos distintos de movimentação empregados pelos
  agentes, definidos pelo atributo K:

  Aleatório:  Movimento aleatório pela vizinhança de Moore;
  Local:      Movimento aleatório restrito ao lote do agente;
  Trajeto:    Trajeto pré-definido com rotas traçadas pelo algoritmo A*;
  Livre:      Trajeto pré-definido com rotas definidas em tempo de execução.

  Para humanos com movimentação Local ou Aleatória no estado Infectante, há uma
  probabilidade de movimentação para uma posição aleatória do ambiente,
  mimetizando Redes de Mundo Pequeno.

  Adicionalmente, a movimentação do agente é condicionada à taxa de mobilidade
  correspondente à sua faixa etária.
*/
MovimentacaoHumanos::MovimentacaoHumanos(
  Humanos *humanos, Ambiente *ambiente, Parametros *parametros, Seeds *seeds
) {
  this->humanos = humanos->PhumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->indViz = ambiente->PindVizDev;
  this->viz = ambiente->PvizDev;
  this->indFron = ambiente->PindFronDev;
  this->fron = ambiente->PfronDev;
  this->indEsq = ambiente->PindEsqDev;
  this->esq = ambiente->PesqDev;
  this->indCEsq = ambiente->PindCEsqDev;
  this->cEsq = ambiente->PcEsqDev;
  this->indRotas = ambiente->PindRotasDev;
  this->rotas = ambiente->ProtasDev;
  this->indTraj = ambiente->PindTrajDev;
  this->indPeri = ambiente->PindPeriDev;
  this->peri = ambiente->PperiDev;
  this->pos = ambiente->PposDev;
  this->sizePos = ambiente->sizePos;
  this->seeds = seeds->PseedsDev;
}

/*
  Operador () da classe MovimentacaoHumanos.
*/
__host__ __device__
void MovimentacaoHumanos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  // Acesso aos atributos do agente
  int sd_h = GET_SD_H(id), fe_h = GET_FE_H(id), k_h = GET_K_H(id);

  // Movimentação por Redes de Mundo Pequeno
  if (k_h == LOCAL or k_h == ALEATORIO) {
    if (sd_h == INFECTANTE and randPerc <= PERC_MIGRACAO) {
      int p = randPerc * sizePos;
      SET_X_H(id, pos[p].x);
      SET_Y_H(id, pos[p].y);
      SET_L_H(id, pos[p].lote);
      SET_Q_H(id, pos[p].quadra);
    }
  }

  // Executa a movimentação correspondente ao atributo K do agente
  if (sd_h != MORTO and randPerc <= TAXA_MOBILIDADE(fe_h)) {
    switch (k_h) {
      case LOCAL: {
        movimentacaoLocal(id, seed, dist);
      } break;
      case ALEATORIO: {
        movimentacaoAleatoria(id, seed, dist);
      } break;
      case LIVRE: {
        movimentacaoLivre(id, seed, dist);
      } break;
      case TRAJETO: {
        movimentacaoTrajeto(id, seed, dist);
      } break;
    }
  }
}

/*
  Método dedicado à movimentação local.
  
  Neste tipo de movimentação o agente se move aleatoriamente por sua
  vizinhança, com a restrição de poder se mover apenas para pontos dentro
  da sua quadra atual.
*/
__host__ __device__
void MovimentacaoHumanos::movimentacaoLocal(
  int id, dre& seed, urd<double>& dist
) {
  // Acesso aos atributos do agente
  int l = GET_Q_H(id), q = GET_L_H(id);
  int x = GET_X_H(id), y = GET_Y_H(id);

  int n = nVertVizinhos(x, y, q, l, q, l);
  if (n == 0) return;

  int k = (int)(randPerc * n);

  int destino = getVertK(k, x, y, q, l, q, l);
  moveHumano(id, destino);
}

/*
  Método dedicado à movimentação aleatória.
  
  Neste tipo de movimentação o agente se move aleatoriamente por sua
  vizinhança, sem restrições.
*/
__host__ __device__
void MovimentacaoHumanos::movimentacaoAleatoria(
  int id, dre& seed, urd<double>& dist
) {
  // Acesso aos atributos do agente
  int l = GET_Q_H(id), q = GET_L_H(id);
  int x = GET_X_H(id), y = GET_Y_H(id);

  int n = nVertVizinhos(x, y, q, l);
  if (n == 0) return;

  int k = (int)(randPerc * n);
  int destino = getVertK(k, x, y, q, l);
  moveHumano(id, destino);
}

/*
  Método dedicado à movimentação do tipo livre.
  
  Neste tipo de movimentação o agente possui paradas predefinidas
  (lotes de interesse), entretanto sua trajetória é calculada durante
  a simulação.
*/
__host__ __device__
void MovimentacaoHumanos::movimentacaoLivre(
  int id, dre& seed, urd<double>& dist
) {
  int q = GET_Q_H(id), l = GET_L_H(id), x = GET_X_H(id);
  int y = GET_Y_H(id), m = GET_M_H(id), r = GET_R_H(id);
  int t = GET_T_H(id), k, n;
  // Conta quantas posicoes de vizinhanca o agente possui
  n = nVertVizinhos(x, y, q, l);
  // Se o agente possuir posicoes de vizinhancas
  if (n) {
    int qo = rotas[indRotas[indTraj[t] + r] + 0];
    int lo = rotas[indRotas[indTraj[t] + r] + 1];
    int qd = rotas[indRotas[indTraj[t] + r] + 2];
    int ld = rotas[indRotas[indTraj[t] + r] + 3];

    // O AGENTE ESTA NA QUADRA E NO LOTE DE ORIGEM
    if (q == qo and l == lo) {
      if (GET_F_H(id)) {
        SET_M_H(id, peri[indPeri[t] + r]);
        SET_F_H(id, 0);
      }
      m = GET_M_H(id);
      if (m) {
        movimentacaoLocal(id, seed, dist);
        SET_M_H(id, m - 1);
      } else {
        // Conta quantas posicoes vizinhas pertencem a proxima rua da rota
        k = nVertVizinhos(x, y, q, l, RUA);
        // Se a vizinhanca do agente tem uma posicao vizinha que pertence a
        // uma rua
        // (O agente esta na fronteira do lote)
        // Move o agente para esta posicao
        if (k) {
          k = getVertK(0, x, y, q, l, RUA);
          moveHumano(id, k);
          SET_F_H(id, 0);
        } else {
          // Se a vizinhanca do agente nao tem uma posicao vizinha que
          // pertence a uma rua
          // (O agente esta no interior do lote)
          // Encontra na lista de pontos de fronteira um ponto
          // que pertenca a uma rua
          k = indFron[indQuadras[2 * l] + q];
          // Encontra na vizinhanca do agente o ponto mais proximo
          // ao ponto de fronteira
          // e que pertenca ao mesmo lote atual do agente
          //k = getVertProxVizIn(x, y, q, l, fron[k].xDestino, fron[k].yDestino, q, l);
          k = getVertProxVizEx(x, y, q, l, fron[k].xDestino, fron[k].yDestino, q, l);
          // Move o agente
          moveHumano(id, k);
        }
      }
    } else {
      // O AGENTE ESTA NA RUA
      if (l == RUA) {
        int xd = fron[indFron[indQuadras[2 * ld] + qd]].xDestino;
        int yd = fron[indFron[indQuadras[2 * ld] + qd]].yDestino;

        // Conta quantas posicoes vizinhas pertencem a quadra e lote destino
        k = nVertVizinhos(x, y, q, l, qd, ld);
        // Se a vizinhanca do agente tem uma posicao vizinha com o lote
        // destino
        // Move para esta posicao
        if (k) {
          k = getVertK(0, x, y, q, l, qd, ld);
          moveHumano(id, k);
        } else {
          // Se a vizinhanca do agente nao tem uma posicao vizinha com o
          // lote destino
          // Se contador de movimentacao do agente e maior que zero
          if (m) {
            // Encontra na vizinhanca do agente o ponto de rua mais proximo
            // ao destino
            // e que pertenca a mesma rua do agente
            //k = getVertProxVizIn(x, y, q, l, xd, yd, q, RUA);
            k = getVertProxVizEx(x, y, q, l, xd, yd, q, RUA);
            moveHumano(id, k);
            // Decrementa o contador de movimentacao do agente
            SET_M_H(id, m - 1);
          } else {
            if (not GET_F_H(id)) {
              // Se a flag e igual a false
              // Procura na vizinhanca do agente uma posicao de rua que
              // diminua sua distancia ao destino
              k = getVertProxVizEx(x, y, q, l, xd, yd, RUA);
              // Se nao houver
              if (k == -1) {
                // seta flag = true
                SET_F_H(id, 1);
                // Encontra na lista de pontos de esquina o ponto com menor
                // distancia ao destino
                k = getVertProxEsqIn(q, xd, yd);
                // Encontra na vizinhanca do agente o ponto que diminua sua
                // distancia ao ponto de esquina
                k = getVertProxVizEx(x, y, q, l, esq[k].x, esq[k].y, RUA);
                if (k != -1) {
                  // Move o agente
                  moveHumano(id, k);
                }
              } else {
                moveHumano(id, k);
              }
            } else {
              // Encontra na lista de pontos de esquina o ponto com menor
              // distancia ao destino
              k = getVertProxEsqIn(l, xd, yd);
              // Encontra na vizinhanca do agente o ponto mais proximo ao
              // ponto de esquina

              // A FUNCAO NAO PODE SER ALTERADA PARA "getVertProxVizEx"!!!
              // Nem sempre havera uma posição que minimize a distancia
              // neste caso
              k = getVertProxVizIn(x, y, q, l, esq[k].x, esq[k].y, RUA);

              // Se esta posicao pertence a outra rua
              if (viz[k].loteDestino != q) {
                // seta flag = false
                SET_F_H(id, 0);
                // seta contador de movimentacao = 50
                SET_M_H(id, 50);
              }
              // Move o agente
              moveHumano(id, k);
            }
          }
        }
      } else {
        // O AGENTE ESTA NA LOCALIDADE E NA QUADRA DE DESTINO
        if (l == ld and q == qd) {
          if (not GET_F_H(id)) {
            SET_M_H(id, peri[indPeri[t] + r + 1]);
            SET_F_H(id, 1);
          }
          m = GET_M_H(id);
          if (m) {
            movimentacaoLocal(id, seed, dist);
            SET_M_H(id, m - 1);
          } else {
            SET_M_H(id, 0);
            SET_F_H(id, 0);
            // Se o agente nao esta percorrendo a ultima rota do trajeto
            if (r + 1 != (indTraj[t + 1] - indTraj[t])) {
              SET_R_H(id, r + 1);
            } else {
              // Se o agente esta percorrendo a ultima rota do trajeto
              SET_R_H(id, 0);
              SET_F_H(id, 1);
            }
          }
        }
      }
    }
  }
}

/*
  Método dedicado à movimentação do tipo trajeto.
  
  Neste tipo de movimentação o agente possui paradas predefinidas
  (lotes de interesse). Sua trajetória, no que diz respeito às esquinas
  por onde deve passar, também é calculada previamente.
*/
__host__ __device__
void MovimentacaoHumanos::movimentacaoTrajeto(
  int id, dre& seed, urd<double>& dist
) {
  int l = GET_Q_H(id), q = GET_L_H(id), x = GET_X_H(id);
  int y = GET_Y_H(id), m = GET_M_H(id), r = GET_R_H(id);
  int t = GET_T_H(id), k, n;
  // Conta quantas posicoes de vizinhanca o agente possui
  n = nVertVizinhos(x, y, q, l);
  // Se o agente possuir posicoes de vizinhancas
  if (n) {
    int qo = rotas[indRotas[indTraj[t] + r] + 0];
    int lo = rotas[indRotas[indTraj[t] + r] + 1];
    int qd = rotas[indRotas[indTraj[t] + r] + 2];
    int ld = rotas[indRotas[indTraj[t] + r] + 3];

    // O AGENTE ESTA NA LOCALIDADE E NA QUADRA DE ORIGEM
    if (l == lo and q == qo) {
      if (GET_F_H(id)) {
        SET_M_H(id, peri[indPeri[t] + r]);
        SET_F_H(id, 0);
      }
      m = GET_M_H(id);
      if (m) {
        movimentacaoLocal(id, seed, dist);
        SET_M_H(id, m - 1);
      } else {
        int primeiraRuaRota = rotas[indRotas[indTraj[t] + r] + 4];

        // Conta quantas posicoes vizinhas pertencem a proxima rua da rota
        k = nVertVizinhos(x, y, q, l, primeiraRuaRota, RUA);
        // Se a vizinhanca do agente tem uma posicao vizinha que pertence a
        // proxima rua da rota
        // (O agente esta na fronteira do lote)
        // Move o agente para esta posicao
        if (k) {
          k = getVertK(0, x, y, q, l, primeiraRuaRota, RUA);
          moveHumano(id, k);
          SET_F_H(id, 0);
        } else {
          // Se a vizinhanca do agente nao tem uma posicao vizinha que
          // pertence a uma rua
          // (O agente esta no interior do lote)
          // Encontra na lista de pontos de fronteira um ponto
          // que pertenca a proxima rua da rota
          k = 0;
          for (int i = indFron[indQuadras[2 * l] + q];
                i < indFron[indQuadras[2 * l] + q + 1]; i++) {
            if (fron[i].loteDestino == primeiraRuaRota) {
              k = i;
              break;
            }
          }
          // Encontra na vizinhanca do agente o ponto mais proximo
          // ao ponto de fronteira
          // e que pertenca ao mesmo lote atual do agente
          //k = getVertProxVizIn(x, y, q, l, fron[k].xDestino, fron[k].yDestino, q, l);
          k = getVertProxVizEx(x, y, q, l, fron[k].xDestino, fron[k].yDestino, q, l);
          // Move o agente
          moveHumano(id, k);
        }
      }
    } else {
      // O AGENTE ESTA NA RUA
      if (l == RUA) {
        int xd, yd;
        for (int i = indFron[indQuadras[2 * ld] + qd];
              i < indFron[indQuadras[2 * ld] + qd + 1];
              i++) {
          if (fron[i].loteDestino == q) {
            xd = fron[i].xDestino, yd = fron[i].yDestino;
            break;
          }
        }
        int proxRuaRota = rotas[indRotas[indTraj[t] + r] + 4 + m + 1];
        bool isUltimaRuaRota = (m + 1 ==
                                ((indRotas[indTraj[t] + r + 1] -
                                  indRotas[indTraj[t] + r]) - 4));

        // Conta quantas posicoes vizinhas pertencem a quadra e lote destino
        k = nVertVizinhos(x, y, q, l, qd, ld);
        // Se a vizinhanca do agente tem uma posicao vizinha com o lote
        // destino
        // Move para esta posicao
        if (k) {
          k = getVertK(0, x, y, q, l, qd, ld);
          moveHumano(id, k);
        } else {
          // Se o agente esta na ultima rua da rota atual
          if (isUltimaRuaRota) {
            // Encontra na vizinhanca do agente um ponto que diminua sua
            // distancia ao
            // ponto de destino e que pertenca ao seu lote atual
            k = getVertProxVizEx(x, y, q, l, xd, yd, q, RUA);
            if (k != -1) {
              // Move o agente
              moveHumano(id, k);
            } else {
							// Agente humano esta em posicao de minimo local:
							// altera-se seu tipo de movimento para aleatorio
							SET_K_H(id, ALEATORIO);
							movimentacaoAleatoria(id, seed, dist);
            }
          } else {
            // Procura um ponto central de esquina que pertenca a proxima
            // rua da rota atual
            int pontoCentral = -1;
            for (int i = indCEsq[q]; i < indCEsq[q + 1]; i++) {
              if (cEsq[i].lote == proxRuaRota) {
                pontoCentral = i;
                break;
              }
            }
            // Encontra na vizinhanca do agente o ponto mais proximo ao
            // ponto central da esquina que pertenca a proxima rua do
            // trajeto

            // A FUNCAO NAO PODE SER ALTERADA PARA "getVertProxVizEx"!!!
            // Nem sempre havera uma posição que minimize a distancia
            // neste caso
            k = getVertProxVizIn(x, y, q, l, cEsq[pontoCentral].x,
                                 cEsq[pontoCentral].y, proxRuaRota, RUA);

            // Se a distancia entre a posicao do agente e a posicao proxima
            // ao centro da esquina
            // for menor que 10
            double d = DIST(viz[k].xDestino, viz[k].yDestino,
                            cEsq[pontoCentral].x, cEsq[pontoCentral].y);
            if (d <= 10) {
              // Move o agente
              moveHumano(id, k);
              // incrementa o contador de movimentacao
              SET_M_H(id, m + 1);
            } else {
              // Encontra na vizinhanca do agente o ponto mais proximo ao
              // ponto central da esquina que pertenca a mesma rua do agente
              k = getVertProxVizEx(x, y, q, l, cEsq[pontoCentral].x,
                                   cEsq[pontoCentral].y, q, RUA);

              if (k != -1) {
                // Move o agente
                moveHumano(id, k);
              } else {
								// Agente humano esta em posicao de minimo local:
								// altera-se seu tipo de movimento para aleatorio
								SET_K_H(id, ALEATORIO);
								movimentacaoAleatoria(id, seed, dist);
              }
            }
          }
        }
      } else {
        // O AGENTE ESTA NA LOCALIDADE E NA QUADRA DE DESTINO
        if (l == ld and q == qd) {
          if (not GET_F_H(id)) {
            SET_M_H(id, peri[indPeri[t] + r + 1]);
            SET_F_H(id, 1);
          }
          m = GET_M_H(id);
          if (m) {
            movimentacaoLocal(id, seed, dist);
            SET_M_H(id, m - 1);
          } else {
            SET_M_H(id, 0);
            SET_F_H(id, 0);
            // Se o agente nao esta percorrendo a ultima rota do trajeto
            if (r + 1 != (indTraj[t + 1] - indTraj[t])) {
              SET_R_H(id, r + 1);
            } else {
              // Se o agente esta percorrendo a ultima rota do trajeto
              SET_R_H(id, 0);
              SET_F_H(id, 1);
            }
          }
        }
      }
    }
  }
}

/*
  Retorna o total de posições na vizinhança do ponto especificado.

  Parâmetros:
    x     Longitude da posição de referência
    y     Latitude da posição de referência
    q     Quadra da posição de referência
    l     Localidade da posição de referência
*/
__host__ __device__
int MovimentacaoHumanos::nVertVizinhos(int x, int y, int q, int l) {
  int n = 0;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) n++;
  }
  return n;
}

/*
  Retorna o número de posições na vizinhança do ponto especificado
  filtrando apenas os pontos que pertencem à localidade indicada.

  Parâmetros:
    x   Longitude da posição de referência
    y   Latitude da posição de referência
    q   Quadra da posição de referência
    l   Localidade da posição de referência
    ld  Localidade para filtrar as posições retornadas
*/
__host__ __device__
int MovimentacaoHumanos::nVertVizinhos(
  int x, int y, int q, int l, int ld
) {
  int n = 0;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == ld) n++;
    }
  }
  return n;
}

/*
  Retorna o número de posições na vizinhança do ponto especificado
  filtrando apenas os pontos que pertencem à quadra e à localidade
  indicadas.

  Parâmetros:
    x   Longitude da posição de referência
    y   Latitude da posição de referência
    q   Quadra da posição de referência
    l   Localidade da posição de referência
    qd  Quadra para filtrar as posições retornadas
    ld  Localidade para filtrar as posições retornadas
*/
__host__ __device__
int MovimentacaoHumanos::nVertVizinhos(
  int x, int y, int q, int l, int qd, int ld
) {
  int n = 0;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (
      viz[i].xOrigem == x and viz[i].yOrigem == y and
      viz[i].loteDestino == qd and viz[i].quadraDestino == ld
    ) n++;
  }
  return n;
}

/*
  Retorna a Késima posição na vizinhança do ponto especificado (x, y).
*/
__host__ __device__
int MovimentacaoHumanos::getVertK(int k, int x, int y, int q, int l) {
  int j = 0;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (j++ == k) return i;
    }
  }
  return -1;
}

/*
  Retorna a Késima posição na vizinhança do ponto especificado (x, y),
  contabilizando apenas pontos que estejam na localidade "ld".
*/
__host__ __device__
int MovimentacaoHumanos::getVertK(int k, int x, int y, int q, int l, int ld) {
  int j = 0;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == ld) {
        if (j++ == k) return i;
      }
    }
  }
  return -1;
}

/*
  Retorna a Késima posição na vizinhança do ponto especificado (x, y),
  contabilizando apenas pontos que estejam na quadra "qd" e na localidade "ld".
*/
__host__ __device__
int MovimentacaoHumanos::getVertK(
  int k, int x, int y, int q, int l, int qd, int ld
) {
  int j = 0;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].loteDestino == qd and viz[i].quadraDestino == ld) {
        if (j++ == k) return i;
      }
    }
  }
  return -1;
}

/*
  Retorna a posição na vizinhança do ponto especificado (x, y) que está mais
  próxima de um ponto de destino desejado (xd, yd), com a restrição de que esta
  posição pertença à localidade "ld".
*/
__host__ __device__
int MovimentacaoHumanos::getVertProxVizIn(
  int x, int y, int q, int l, int xd, int yd, int ld
) {
  int ind = -1;
  double menorDist = INT_MAX, dist;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == ld) {
        dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
        if (dist < menorDist) {
          menorDist = dist;
          ind = i;
        }
      }
    }
  }
  return ind;
}

/*
  Retorna a posição na vizinhança do ponto especificado (x, y) que está mais
  próxima de um ponto de destino desejado (xd, yd), com a restrição de que esta
  posição pertença à quadra "qd" e à localidade "ld".
*/
__host__ __device__
int MovimentacaoHumanos::getVertProxVizIn(
  int x, int y, int q, int l, int xd, int yd, int qd, int ld
) {
  int ind = -1;
  double menorDist = INT_MAX, dist;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].loteDestino == ld and viz[i].quadraDestino == qd) {
        dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
        if (dist < menorDist) {
          menorDist = dist;
          ind = i;
        }
      }
    }
  }
  return ind;
}

/*
  Retorna a posição na vizinhança do ponto especificado (x, y) que está mais
  próxima de um ponto de destino desejado (xd, yd), com a restrição de que esta
  posição pertença à quadra "qd" e à localidade "ld". Exclui desta busca um ponto
  específico de minimo local (xmin, ymin).
*/
__host__ __device__
int MovimentacaoHumanos::getVertProxVizIn(
  int x, int y, int q, int l, int xd, int yd, int qd, int ld, int xmin, int ymin
) {
  int ind = -1;
  double menorDist = INT_MAX, dist;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].loteDestino == qd and viz[i].quadraDestino == ld) {
        if (viz[i].xDestino == xmin and viz[i].yDestino == ymin) continue;
        dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
        if (dist < menorDist) {
          menorDist = dist;
          ind = i;
        }
      }
    }
  }
  return ind;
}

/*
  Retorna a posição na vizinhança do ponto especificado (x, y) que está mais
  próxima de um ponto de destino desejado (xd, yd), com a restrição de que esta
  posição pertença à localidade "ld". Adicionalmente, este método considera apenas
  posições mais próximas do ponto especificado do que o ponto de destino.
*/
__host__ __device__
int MovimentacaoHumanos::getVertProxVizEx(
  int x, int y, int q, int l, int xd, int yd, int ld
) {
  int ind = -1;
  double menorDist = DIST(x, y, xd, yd), dist;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == ld) {
        dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
        if (dist < menorDist) {
          menorDist = dist;
          ind = i;
        }
      }
    }
  }
  return ind;
}

/*
  Retorna a posição na vizinhança do ponto especificado (x, y) que está mais
  próxima de um ponto de destino desejado (xd, yd), com a restrição de que esta
  posição pertença à quadra "qd" e à localidade "ld". Adicionalmente, este método
  considera apenas posições mais próximas do ponto especificado do que o ponto
  de destino.
*/
__host__ __device__
int MovimentacaoHumanos::getVertProxVizEx(
  int x, int y, int q, int l, int xd, int yd, int qd, int ld
) {
  int ind = -1;
  double menorDist = DIST(x, y, xd, yd), dist;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].loteDestino == qd and viz[i].quadraDestino == ld) {
        dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
        if (dist < menorDist) {
          menorDist = dist;
          ind = i;
        }
      }
    }
  }
  return ind;
}

/*
  Retorna a posição na vizinhança do ponto especificado (x, y) que está mais
  próxima de um ponto de destino desejado (xd, yd), com a restrição de que esta
  posição pertença à quadra "qd" e à localidade "ld". Exclui desta busca um ponto
  específico de minimo local (xmin, ymin). Adicionalmente, este método
  considera apenas posições mais próximas do ponto especificado do que o ponto
  de destino.
*/
__host__ __device__
int MovimentacaoHumanos::getVertProxVizEx(
  int x, int y, int q, int l, int xd, int yd, int qd, int ld, int xmin, int ymin
) {
  int ind = -1;
  double menorDist = DIST(x, y, xd, yd), dist;
  int inicio = indViz[indQuadras[2 * l] + q];
  int fim = indViz[indQuadras[2 * l] + q + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].loteDestino == qd and viz[i].quadraDestino == ld) {
        if (viz[i].xDestino == xmin and viz[i].yDestino == ymin) continue;
        dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
        if (dist < menorDist) {
          menorDist = dist;
          ind = i;
        }
      }
    }
  }
  return ind;
}

/*
  Retorna a posição de esquina pertencente à rua "q" que se encontra mais
  próxima de um ponto de destino desejado (xd, yd).
*/
__host__ __device__
int MovimentacaoHumanos::getVertProxEsqIn(int q, int xd, int yd) {
  int ind = -1;
  double menorDist = INT_MAX, dist;
  for (int i = indEsq[q]; i < indEsq[q + 1]; i++) {
    dist = DIST(esq[i].x, esq[i].y, xd, yd);
    if (dist < menorDist) {
      menorDist = dist;
      ind = i;
    }
  }
  return ind;
}

/*
  Método responsável por atualizar os atributos do agente na movimentação.
  O parâmetro K corresponde ao índice do ponto de destino na vizinhança da
  posição atual do agente.
*/
__host__ __device__
void MovimentacaoHumanos::moveHumano(int id, int k) {
  if (k >= 0) {
    SET_X_H(id, viz[k].xDestino);
    SET_Y_H(id, viz[k].yDestino);
    SET_L_H(id, viz[k].loteDestino);
    SET_Q_H(id, viz[k].quadraDestino);
  }
}
