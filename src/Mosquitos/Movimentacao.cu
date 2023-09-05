#include "Movimentacao.h"
#include "Fontes/Ambiente.h"
#include "Fontes/Parametros.h"
#include "Fontes/Seeds.h"
#include "Fontes/Macros/1_MOV_M.h"
#include "Fontes/Macros/5_GER_M.h"
#include "Fontes/Mosquitos/Mosquitos.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Humanos/Humanos.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Macros/MacrosGerais.h"

/*
  Este operador é paralelizado para cada AGENTE.

  Esté método é responsável pela movimentação dos agentes mosquitos através do
  ambiente de simulação. De maneira geral, a movimentação obedece às seguintes
  condições:

  - Durante a MANHÃ e a TARDE:
    Nestes períodos os mosquitos possuem movimentação DIURNA, sendo específica
    de acordo com os atributos internos dos agentes, regida por uma taxa de
    mobilidade diurna.

  - Durante o período da NOITE:
    Os mosquitos realizam movimentação LOCAL, regida por uma taxa de mobilidade
    noturna.
*/
MovimentacaoMosquitos::MovimentacaoMosquitos(
  Mosquitos *mosquitos, Humanos *humanos, Ambiente *ambiente,
  Parametros *parametros, int periodo, int sizePontEst, Seeds *seeds
) {
  this->mosquitos = mosquitos->PmosquitosDev;
  this->indMosquitos = mosquitos->PindMosquitosDev;
  this->humanos = humanos->PhumanosDev;
  this->indHumanos = humanos->PindHumanosDev;
  this->parametros = parametros->PparametrosDev;
  this->indQuadras = ambiente->PindQuadrasDev;
  this->indViz = ambiente->PindVizDev;
  this->viz = ambiente->PvizDev;
  this->indFron = ambiente->PindFronDev;
  this->fron = ambiente->PfronDev;
  this->indPos = ambiente->PindPosDev;
  this->pos = ambiente->PposDev;
  this->indEsq = ambiente->PindEsqDev;
  this->esq = ambiente->PesqDev;
  this->indCEsq = ambiente->PindCEsqDev;
  this->cEsq = ambiente->PcEsqDev;
  this->indRotas = ambiente->PindRotasDev;
  this->rotas = ambiente->ProtasDev;
  this->indTraj = ambiente->PindTrajDev;
  this->indPeri = ambiente->PindPeriDev;
  this->peri = ambiente->PperiDev;
  this->pontEst = ambiente->PpontEstDev;
  this->sizePontEst = sizePontEst;
  this->periodo = periodo;
  this->seeds = seeds->PseedsDev;
  this->indFocos = ambiente->PindFocosDev;
  this->focos = ambiente->PfocosDev;
  this->capFocos = ambiente->PcapFocosDev;
}

/*
  Operador () da classe MovimentacaoMosquitos.
*/
__host__ __device__
void MovimentacaoMosquitos::operator()(int id) {
  dre& seed = seeds[id];
  urd<double> dist(0.0, 1.0);

  int vd = GET_VD_M(id);
  int fs = GET_FS_M(id);
  int s = GET_S_M(id);
  
  // Filtra mosquitos vivos em fase alada
  if (vd == MORTO or (fs != ATIVA and fs != DECADENTE)) return;

  // Movimentação no periodo da manhã e da tarde
  if ((periodo == MANHA or periodo == TARDE)
      and randPerc <= TAXA_MOBILIDADE_DIURNA_MOSQUITOS(s)) {
      
      // Verifica o tipo de influência ambiental
      int ti = GET_TI_M(id);
      switch (ti) {
        case SEM_INFLUENCIA: {
          movimentacaoDiurna(id, seed, dist);
        } break;
        case PARADO: {
          if (randPerc <= TAXA_MOBILIDADE_MOSQUITO_PARADO) {
            movimentacaoDiurna(id, seed, dist);
          }
        } break;
        case ESPANTADO: {
          moveMosquitoParaRua(id);
        } break;
      }
  }

  // Movimentação no período noturno
  if (periodo == NOITE and randPerc <= TAXA_MOBILIDADE_NOTURNA_MOSQUITOS(s)) {
    movimentacaoLocal(id, seed, dist);
  }
}

/*
  Este método aplica a movimentação diurna normal dos agentes mosquitos, que
  varia para machos e fêmeas. Enquanto machos realizam movimentação aleatória,
  fêmeas possuem uma rotina particular de movimentação.
*/
__host__ __device__
void MovimentacaoMosquitos::movimentacaoDiurna(
  int id, dre& seed, urd<double>& dist
) {
  if (GET_S_M(id) == MACHO) {
    movimentacaoAleatoria(id, seed, dist);
  } else {
    movimentacaoFemea(id, seed, dist);
  }
}

/*
  Esta rotina de movimentação é aplicada aos mosquitos machos nos períodos da
  manhã e da tarde. O agente se movimenta aleatoriamente para alguma posição
  na vizinhança de sua posição atual, sem quaisquer restrições.
*/
__host__ __device__
void MovimentacaoMosquitos::movimentacaoAleatoria(
  int id, dre& seed, urd<double>& dist
) {
  int q = GET_Q_M(id), l = GET_L_M(id), x = GET_X_M(id), y = GET_Y_M(id);
  int k, n;

  n = nVertVizinhos(x, y, l, q);
  if (n == 0) return;

  k = (int)(randPerc * n);
  k = getVertK(k, x, y, l, q);
  moveMosquito(id, k);
}

/*
  Esta rotina de movimentação é aplicada a todos os mosquitos no período da
  noite. O agente se movimenta aleatoriamente para alguma posição na
  vizinhança de sua posição atual, sem sair da quadra em que está.
*/
__host__ __device__
void MovimentacaoMosquitos::movimentacaoLocal(
  int id, dre& seed, urd<double>& dist
) {
  int q = GET_Q_M(id), l = GET_L_M(id), x = GET_X_M(id), y = GET_Y_M(id);
  int k, n;

  n = nVertVizinhos(x, y, l, q, l, q);
  if (n == 0) return;

  k = (int)(randPerc * n);
  k = getVertK(k, x, y, l, q, l, q);
  moveMosquito(id, k);
}

/*
  A fêmea do mosquito segue uma movimentação específica, de acordo com
  diversos atributos para modelar sua dinâmica particular.

  - Fêmeas não acasaladas seguem uma rotina de busca por um agente macho para
  acasalar. Como estratégia para essa busca a fêmea pode procurar PEs (pontos
  estratégicos), que geralmente abrigam uma grande concentração de mosquitos.
  - Fêmeas acasaladas não alimentadas seguem uma rotina de busca por humano
  para realizar repasto.
  - Fêmeas acasaladas e alimentadas buscam pontos de foco para realizar a
  postura de ovos.
*/
__host__ __device__
void MovimentacaoMosquitos::movimentacaoFemea(
  int id, dre& seed, urd<double>& dist
) {
  if (GET_TA_M(id) == NENHUM) {
    movimentacaoFemeaNaoAcasalada(id, seed, dist);
  } else {
    movimentacaoFemeaAcasalada(id, seed, dist);
  }
}

/*
  Este método é responsável pela rotina de movimentação de fêmeas que ainda
  não acasalaram. A movimentação destes agentes é regida pelas flags:
    FM = Flag Busca Macho
    FP = Flag Busca Ponto Estrategico

  Ao entrar na fase alada, a fêmea inicialmente possui a flag FM ativada, logo
  ela procura um macho para acasalar nas suas redondezas.

  A busca por macho utiliza o atributo C como contador de tentativas. Após um
  número máximo determinado pelo parâmetro TENTATIVAS_BUSCA_MACHO, a fêmea
  verifica se está em um PE. Se sim, ela realiza um vôo de Levy e reinicia
  sua busca. Caso não esteja em um PE, a flag FP é ativada.

  Na busca por Pontos Estratégicos, a função buscaPE procura PEs em um certo
  raio ao redor do agente. Caso não se encontre nenhum PE, a fêmea realiza um
  vôo de Levy. Caso exista um PE nas redondezas, a fêmea se move em sua
  direção. Ao chegar no PE ou realizar o vôo de Levy, a flag FM é novamente
  ativada.
*/
__host__ __device__
void MovimentacaoMosquitos::movimentacaoFemeaNaoAcasalada(
  int id, dre& seed, urd<double>& dist
) {
  // Acesso aos atributos da fêmea
  int lote = GET_L_M(id);
  int quadra = GET_Q_M(id);
  
  // Busca por machos
  if (GET_FM_M(id)) {
    int c = GET_C_M(id);
    if (c < TENTATIVAS_BUSCA_MACHO) {
      // Se existe um macho nas proximidades, a fêmea se move em sua direção
      if (not buscaMacho(id, seed, dist)) {
        SET_C_M(id, c + 1); // Caso não encontre, incrementa o contador
      }
    } else {
      // Reseta o contador de tentativas
      SET_C_M(id, 0);
      if (estaEmPE(quadra, lote)) {
        // Se já está em PE realiza vôo de Lévy
        vooLevy(id, seed, dist);
      } else {
        // Senão tenta procurar um PE próximo
        SET_FP_M(id, 1);
        SET_FM_M(id, 0);
      }
    }
  }
  
  // Busca por Pontos Estratégicos
  if (GET_FP_M(id)) {
    if (estaEmPE(quadra, lote)) {
      // Se chegou em PE tenta procurar macho.
      SET_FP_M(id, 0);
      SET_FM_M(id, 1);
    } else {
      // Senão tenta buscar PE.
      if (not buscaPE(id, seed, dist)) {
        // Se não há PE próximo realiza vôo de Lévy e tenta procurar macho.
        vooLevy(id, seed, dist);
        SET_FP_M(id, 0);
        SET_FM_M(id, 1);
      }
    }
  }
}

/*
  Este método é responsável pela movimentação da fêmea após o acasalamento. A
  rotina é diferente para fêmeas que estão ou não estão alimentadas:
  - Fêmeas não alimentadas buscam humanos para realizar repasto.
  - Fêmeas alimentadas buscam focos para realizar a postura de seus ovos.

  Em ambos os casos, caso a fêmea não encontre nada nas redondezas ela
  performa um vôo de Levy para procurar em outro local.
*/
__host__ __device__
void MovimentacaoMosquitos::movimentacaoFemeaAcasalada(
  int id, dre& seed, urd<double>& dist
) {
  if (not GET_AM_M(id)) {
    if (not buscaHumano(id, seed, dist)) {
      vooLevy(id, seed, dist);
    }
  } else {
    if (not buscaFoco(id, seed, dist)) {
      vooLevy(id, seed, dist);
    }
  }
}

/*
  Método de movimentação alternativa para a fêmea acasalada
  não alimentada (busca por humanos).

  Nesta versão da rotina de movimento a fêmea não busca diretamente os agentes
  humanos em suas redondezas. Em vez disso a movimentação é regida por uma
  composição duas funções de movimentação ponderadas pela variável percVooLevy:

    (percVooLevy)       Probabilidade de executar a manobra de Voo de Levy.
    
    (1 - percVooLevy)   Probabilidade de executar movimentação aleatória.
*/
__host__ __device__
void MovimentacaoMosquitos::movimentacaoAleatoriaVooLevy(
  double percVooLevy, int id, dre& seed, urd<double>& dist
) {
  if (randPerc < percVooLevy) {
    vooLevy(id, seed, dist);
  } else {
    movimentacaoAleatoria(id, seed, dist);
  }
}

/*
  Este método verifica se existe um mosquito macho dentro de um determinado
  raio (RAIO_BUSCA_MACHO) e, caso exista, move o agente em sua direção.
*/
__host__ __device__
bool MovimentacaoMosquitos::buscaMacho(int id, dre& seed, urd<double>& dist) {
  int x = GET_X_M(id), y = GET_Y_M(id), l = GET_L_M(id), q = GET_Q_M(id);
  int x_m, y_m, k;

  int raioBuscaMacho = RAIO_BUSCA_MACHO;
  tuple<int, int> tu;

  if (not temMacho(x, y, l, q, tu, raioBuscaMacho)) return false;

  x_m = get<0>(tu); y_m = get<1>(tu);
  k = getVertProxVizIn(x, y, l, q, x_m, y_m);
  moveMosquito(id, k);
  return true;
}

/*
  Este método verifica se existe um Ponto Estratégico dentro de um determinado
  raio (RAIO_BUSCA_PE) e, caso exista, move o agente em sua direção.
*/
__host__ __device__
bool MovimentacaoMosquitos::buscaPE(int id, dre& seed, urd<double>& dist) {
  int x = GET_X_M(id), y = GET_Y_M(id), l = GET_L_M(id), q = GET_Q_M(id);
  int x_pe, y_pe, k;

  int raioBuscaPE = RAIO_BUSCA_PE;
  tuple<int, int> tu;

  if (not temPE(x, y, l, q, tu, raioBuscaPE)) return false;

  x_pe = get<0>(tu); y_pe = get<1>(tu);
  k = getVertProxVizIn(x, y, l, q, x_pe, y_pe);
  moveMosquito(id, k);
  return true;
}

/*
  Este método verifica se existe um humano dentro de um determinado raio
  (RAIO_BUSCA_HUMANO) e, caso exista, move o agente em sua direção.
*/
__host__ __device__
bool MovimentacaoMosquitos::buscaHumano(int id, dre& seed, urd<double>& dist) {
  int x = GET_X_M(id), y = GET_Y_M(id), l = GET_L_M(id), q = GET_Q_M(id);
  int x_h, y_h, k;

  int raioBuscaHumano = RAIO_BUSCA_HUMANO;
  tuple<int, int> tu;

  if (not (temHumano(x, y, l, q, tu, raioBuscaHumano))) return false;

  x_h = get<0>(tu); y_h = get<1>(tu);
  k = getVertProxVizIn(x, y, l, q, x_h, y_h);
  moveMosquito(id, k);
  return true;
}

/*
  Este método procura, dentro do lote, um ponto de foco vantajoso para o agente
  e tenta movê-lo em sua direção. Consideram-se os critérios:

  - Caso não existam focos na quadra atual do agente, ou ainda estejam todos
    completamente ocupados, retorna falso.

  - Avaliam-se todos os focos presentes na quadra em que a fêmea se encontra,
    exceto sua posição atual caso esteja em um foco, por meio da expressão
                          dist * (capFocos ^ 2)
    sendo:
      dist      - distância do agente até o ponto de foco
      capFocos  - número de agentes na fase aquática já instalados no foco
  
  - Caso a posição atual do agente não seja um foco, move o agente em direção
    ao foco com menor valor obtido para a expressão acima e retorna verdadeiro.

  - Caso o agente já esteja em um foco, porém o foco mais vantajoso obtido
    acima está menos ocupado, move o agente em direção a este novo foco e
    retorna verdadeiro.

  - Caso o agente já esteja em um foco que está menos ocupado do que a melhor
    alternativa encontrada, o agente fica onde está e retorna verdadeiro.
*/
__host__ __device__
bool MovimentacaoMosquitos::buscaFoco(int id, dre& seed, urd<double>& dist) {
  
  int x = GET_X_M(id);
  int y = GET_Y_M(id);
  int l = GET_L_M(id);
  int q = GET_Q_M(id);

  int inicioFocos = indFocos[indQuadras[q * 2] + l];
  int finalFocos = indFocos[indQuadras[q * 2] + l + 1];
  if (inicioFocos >= finalFocos) return false;

  double menorFator = INT_MAX;
  int nAgentesFocoAtual = INT_MAX;
  int focoPreferencial = -1;

  // Procura o ponto de foco menos ocupado e mais próximo
  for (int i = inicioFocos; i < finalFocos; i++) {
    int x_foco = pos[focos[i]].x;
    int y_foco = pos[focos[i]].y;
    int nAgentes = capFocos[i];
    
    // Se já está em um foco, fica nele a não ser que esteja 60% ocupado
    if (x == x_foco and y == y_foco) {
      if (nAgentes < 0.6 * LIMITE_FOCOS) {
        return true;
      } else {
        // Armazena a quantidade de agentes no foco atual, se ainda há espaço
        if (nAgentes < LIMITE_FOCOS) nAgentesFocoAtual = nAgentes;
        continue;
      }
    }

    double dist = DIST(x_foco, y_foco, x, y);
    double fatorPonto = dist * nAgentes * nAgentes;
    if (fatorPonto < menorFator) {
      menorFator = fatorPonto;
      focoPreferencial = i;
    }
  }

  if (focoPreferencial == -1) return false;

  // Fica no foco atual caso seja mais vantajoso
  if (capFocos[focoPreferencial] >= nAgentesFocoAtual) return true;
  // Caso o foco preferencial já esteja lotado retorna falso
  if (capFocos[focoPreferencial] >= LIMITE_FOCOS) return false;

  // Move o agente em direção ao ponto de foco encontrado
  int x_foco = pos[focos[focoPreferencial]].x;
  int y_foco = pos[focos[focoPreferencial]].y;
  if (x == x_foco and y == y_foco) return true;
  int k = getVertProxVizIn(x, y, l, q, x_foco, y_foco);
  moveMosquito(id, k);
  return true;
}

/*
  Este método procura o mosquito mais próximo dentro da quadra atual. Caso o
  mosquito encontrado esteja dentro do raio especificado, retorna sua posição
  na tupla "tu".
*/
__host__ __device__
bool MovimentacaoMosquitos::temMacho(
  int x, int y, int l, int q, tuple<int, int>& tu, double raio
) {
  int ind = 0;
  double menorDist = INT_MAX, dist;
  for (int i = indMosquitos[q]; i < indMosquitos[q + 1]; ++i) {
    if (GET_S_M(i) == MACHO) {
      dist = DIST(GET_X_M(i), GET_Y_M(i), x, y);
      if (dist < menorDist) {
        menorDist = dist;
        ind = i;
      }
    }
  }

  if (menorDist > raio) return false;

  get<0>(tu) = GET_X_M(ind);
  get<1>(tu) = GET_Y_M(ind);
  return true;
}

/*
  Este método procura o PE mais próximo dentro da quadra atual. Caso o lote
  encontrado esteja dentro do raio especificado, retorna sua posição na tupla
  "tu".
*/
__host__ __device__
bool MovimentacaoMosquitos::temPE(
  int x, int y, int l, int q, tuple<int, int>& tu, double raio
) {
  int ind = 0, x_pe, y_pe, l_pe, q_pe;
  double menorDist = INT_MAX, dist;
  for (int i = 0; i < sizePontEst; i += 2) {
    q_pe = pontEst[i];
    l_pe = pontEst[i + 1];
    x_pe = pos[indPos[indQuadras[q_pe * 2] + l_pe]].x;
    y_pe = pos[indPos[indQuadras[q_pe * 2] + l_pe]].y;
    dist = DIST(x_pe, y_pe, x, y);
    if (dist < menorDist) {
      menorDist = dist;
      ind = i;
    }
  }

  if (menorDist > raio) return false;

  q_pe = pontEst[ind];
  l_pe = pontEst[ind + 1];
  x_pe = pos[indPos[indQuadras[q_pe * 2] + l_pe]].x;
  y_pe = pos[indPos[indQuadras[q_pe * 2] + l_pe]].y;
  get<0>(tu) = x_pe;
  get<1>(tu) = y_pe;
  return true;
}

/*
  Este método procura o humano mais próximo dentro da quadra atual. Caso o
  humano encontrado esteja dentro do raio especificado, retorna sua posição
  na tupla "tu".
*/
__host__ __device__
bool MovimentacaoMosquitos::temHumano(
  int x, int y, int l, int q, tuple<int, int>& tu, double raio
) {
  int ind = 0;
  double menorDist = INT_MAX, dist;
  for (int i = indHumanos[q]; i < indHumanos[q + 1]; ++i) {
    dist = DIST(GET_X_H(i), GET_Y_H(i), x, y);
    if (dist < menorDist) {
      menorDist = dist;
      ind = i;
    }
  }

  if (menorDist > raio) return false;

  get<0>(tu) = GET_X_H(ind);
  get<1>(tu) = GET_Y_H(ind);
  return true;
}

/*
  Este método verifica se o lote especificado é um Ponto Estratégico ou não.
*/
__host__ __device__
bool MovimentacaoMosquitos::estaEmPE(int quadra, int lote) {
  for (int i = 0; i < sizePontEst; i += 2) {
    if ((quadra == pontEst[i]) and (lote == pontEst[i + 1]))
      return true;
  }
  return false;
}

/*
  Este método faz o mosquito performar um Voo de Levy, em que  o agente
  percorre uma grande distância para redirecionar a busca por parceiros,
  focos ou repasto.

  A distância percorrida é regulada por um número de iterações definido
  pelos parâmetros:

    MOV009  Deslocamentos no Voo de Levy Curto
    MOV010  Deslocamentos no Voo de Levy Longo
  
  Os vôos curto e longo são realizados alternadamente, utilizando para
  isso a flag FV (Flag Vôo Levy).

  - O algoritmo se inicia movimentando o agente para uma das posições
  vizinhas, escolhida aleatoriamente.
  - A distância entre a nova posição e a origem é então armazenada na
  variável 'dist2'.
  - Move o agente para uma posição aleatória na nova vizinhança, sendo
  consideradas apenas as posições que levarão o agente para mais longe
  da origem.
  - Para isso toma como referência 'dist2', e atualiza esse valor após
  mover o agente.
  - Repete este deslocamento de acordo com o parâmetro.
*/
__host__ __device__
void MovimentacaoMosquitos::vooLevy(int id, dre& seed, urd<double>& dist) {
  int xo = GET_X_M(id), yo = GET_Y_M(id);
  int lo = GET_L_M(id), qo = GET_Q_M(id);
  int xd, yd, ld, qd;

  int raio, k, n;
  double dist2;

  if (GET_FV_M(id)) {
    raio = RAIO_VOO_LEVY_LONGO - 1;
    SET_FV_M(id, 0);
  } else {
    raio = RAIO_VOO_LEVY_CURTO - 1;
    SET_FV_M(id, 1);
  }

  n = nVertVizinhos(xo, yo, lo, qo);
  if (n == 0) return;

  k = (int)(randPerc * n);
  k = getVertK(k, xo, yo, lo, qo);
  moveMosquito(id, k);

  xd = GET_X_M(id), yd = GET_Y_M(id), ld = GET_L_M(id), qd = GET_Q_M(id);

  dist2 = DIST(xo, yo, xd, yd);
  for (int i = 0; i < raio; ++i) {
    k = getVertVL(xd, yd, ld, qd, xo, yo, dist2, seed, dist);
    moveMosquito(id, k);
    xd = GET_X_M(id), yd = GET_Y_M(id);
    ld = GET_L_M(id), qd = GET_Q_M(id);
    dist2 = DIST(xo, yo, xd, yd);
  }
}

/*
  Este método move o agente em direção a uma posição de rua.

  Caso o agente esteja em uma posição de fronteira, simplesmente o move para a
  posição de rua adjacente, caso contrário o agente é deslocado para a posição
  mais próxima de uma fronteira com a rua, considerando apenas a quadra atual.
*/
__host__ __device__
void MovimentacaoMosquitos::moveMosquitoParaRua(int idMosquito) {
  int x = GET_X_M(idMosquito), y = GET_Y_M(idMosquito);
  int l = GET_L_M(idMosquito), q = GET_Q_M(idMosquito);
  int k;

  k = nVertVizinhos(x, y, l, q, RUA);
  if (k) {
    k = getVertK(0, x, y, l, q, RUA);
    moveMosquito(idMosquito, k);
    SET_TI_M(idMosquito, SEM_INFLUENCIA);
  } else {
    k = indFron[indQuadras[2 * q] + l];
    k = getVertProxVizIn(x, y, l, q, fron[k].xDestino, fron[k].yDestino, l, q);
    moveMosquito(idMosquito, k);
  }
}

/*
  Contabiliza o número de vértices na vizinhança da posição especificada.
*/
__host__ __device__
int MovimentacaoMosquitos::nVertVizinhos(int x, int y, int l, int q) {
  int nVert = 0;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      nVert++;
    }
  }
  return nVert;
}

/*
  Contabiliza o número de vértices na vizinhança da posição especificada,
  considerando apenas as posições que pertencem à localidade qd.
*/
__host__ __device__
int MovimentacaoMosquitos::nVertVizinhos(int x, int y, int l, int q, int qd) {
  int nVert = 0;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == qd) {
        nVert++;
      }
    }
  }
  return nVert;
}

/*
  Contabiliza o número de vértices na vizinhança da posição especificada,
  considerando apenas as posições que pertencem à localidade qd e à quadra ld.
*/
__host__ __device__
int MovimentacaoMosquitos::nVertVizinhos(
  int x, int y, int l, int q, int ld, int qd
) {
  int nVert = 0;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == qd and viz[i].loteDestino == ld) {
        nVert++;
      }
    }
  }
  return nVert;
}

/*
  Retorna o vértice de índice k na vizinhança da posição especificada.
*/
__host__ __device__
int MovimentacaoMosquitos::getVertK(int k, int x, int y, int l, int q) {
  int j = 0;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (j == k) return i;
      j++;
    }
  }
  return -1;
}

/*
  Retorna o vértice de índice k na vizinhança da posição especificada,
  considerando apenas as posições que pertencem à localidade qd.
*/
__host__ __device__
int MovimentacaoMosquitos::getVertK(int k, int x, int y, int l, int q, int qd) {
  int j = 0;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == qd) {
        if (j == k) return i;
        j++;
      }
    }
  }
  return -1;
}

/*
  Retorna o vértice de índice k na vizinhança da posição especificada,
  considerando apenas as posições que pertencem à localidade qd e à quadra ld.
*/
__host__ __device__
int MovimentacaoMosquitos::getVertK(
  int k, int x, int y, int l, int q, int ld, int qd
) {
  int j = 0;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == qd and viz[i].loteDestino == ld) {
        if (j == k) return i;
        j++;
      }
    }
  }
  return -1;
}

/*
  Este método, utilizado na função 'vooLevy', é responsável por retornar
  a próxima posição que distancie o agente da origem (xo, yo).

  Inicialmente são verificadas as posições na vizinhança cuja distância
  até (xo, yo) seja maior do que a distância especificada pelo parâmetro
  'dist2', que representa a distância atual do agente até a origem.

  Na sequência retorna uma vizinhança entre as filtradas, escolhida
  aleatoriamente.
*/
__host__ __device__
int MovimentacaoMosquitos::getVertVL(
  int x, int y, int l, int q, int xo, int yo,
  double dist2, dre& seed, urd<double>& dist
) {
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  int nVert = 0;
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (DIST(viz[i].xDestino, viz[i].yDestino, xo, yo) > dist2) {
        nVert++;
      }
    }
  }
  if (nVert == 0) return -1; // Caso não encontre nenhuma posição
  int k = (int)(randPerc * nVert);
  int j = 0;
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (DIST(viz[i].xDestino, viz[i].yDestino, xo, yo) > dist2) {
        if (j++ == k) return i;
      }
    }
  }
  return -1;
}

/*
  Determina a posição vizinha à atual que seja mais próxima a um ponto de
  destino (xd, yd).
*/
__host__ __device__
int MovimentacaoMosquitos::getVertProxVizIn(
  int x, int y, int l, int q, int xd, int yd
) {
  int ind = 0;
  double menorDist = INT_MAX;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      double dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
      if (dist < menorDist) {
        menorDist = dist;
        ind = i;
      }
    }
  }
  return ind;
}

/*
  Determina a posição vizinha à atual que seja mais próxima a um ponto de
  destino (xd, yd), considerando apenas posições que pertencem à localidade qd
  e à quadra ld.
*/
__host__ __device__
int MovimentacaoMosquitos::getVertProxVizIn(
  int x, int y, int l, int q, int xd, int yd, int ld, int qd
) {
  int ind = 0;
  double menorDist = INT_MAX;
  int inicio = indViz[indQuadras[2 * q] + l];
  int fim = indViz[indQuadras[2 * q] + l + 1];
  for (int i = inicio; i < fim; i++) {
    if (viz[i].xOrigem == x and viz[i].yOrigem == y) {
      if (viz[i].quadraDestino == qd and viz[i].loteDestino == ld) {
        double dist = DIST(viz[i].xDestino, viz[i].yDestino, xd, yd);
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
  Este método é responsável por alterar de fato a posição do agente.
  Recebe o parâmetro "k", que representa o índice do vetor de vizinhanças
  que contém a posição de destino desejada.
*/
__host__ __device__
void MovimentacaoMosquitos::moveMosquito(int id, int k) {
  if (k != -1) {
    SET_X_M(id, viz[k].xDestino);
    SET_Y_M(id, viz[k].yDestino);
    SET_L_M(id, viz[k].loteDestino);
    SET_Q_M(id, viz[k].quadraDestino);
  }
}
