#include "Humanos.h"
#include "Fontes/Uteis/RandPerc.h"
#include "Fontes/Macros/MacrosGerais.h"
#include "Fontes/Macros/MacrosSO.h"
#include "Fontes/Macros/0_INI_H.h"
#include "Fontes/Macros/MacrosHumanos.h"
#include "Fontes/Parametros.h"
#include "Fontes/Ambiente.h"

/*
  Estrutura de dados que representa um agente do tipo humano.
*/
__host__ __device__
Humano::Humano() {
  // Identificador do agente
  id = 0U;
  // Variáveis bitstring
  t1 = 0U; t2 = 0U; t3 = 0U; t4 = 0U;
}

/*
  Este operador verifica se um agente humano está morto.
*/
__host__ __device__
bool EstaMortoHumano::operator()(Humano humano) {
  return GET_SD_H_ == MORTO;
}

/*
  Este operador verifica se um agente humano está suscetível.
*/
__host__ __device__
bool HumanoSuscetivel::operator()(Humano humano) {
  return GET_SD_H_ == SUSCETIVEL;
}

/*
  Este operador define o critério de ordenação por localidades
  do vetor de agentes humanos.
*/
__host__ __device__
bool MenorIdLocalidadeHumano::operator()(Humano humano1, Humano humano2) {
  Humano humano = humano1;
  int q_h1 = GET_Q_H_;
  humano = humano2;
  int q_h2 = GET_Q_H_;
  return q_h1 < q_h2;
}

/*
  Este operador retorna a localidade atual de um agente humano.
*/
__host__ __device__
int GetIdLocalidadeHumano::operator()(Humano humano) {
  return GET_Q_H_;
}

/*
  Construtor da classe Humanos.
  Responsável pela inicialização do vetor de agentes humanos.
*/
Humanos::Humanos(Parametros *parametros, Ambiente *ambiente) {
  this->parametros = parametros;
  this->ambiente = ambiente;

  // Criação e inicialização dos agentes humanos.
  contarHumanos();
  humanos = new Humano[nHumanos]();
  criarHumanos();
  sizeIndHumanos = ambiente->nQuadras + 1;

  t = make_counting_iterator(0);
  v1 = make_constant_iterator(1);

  // Envia o vetor para a GPU e atualiza os índices
  toGPU();
  atualizacaoIndices();
}

/*
  Destrutor da classe Humanos.
*/
Humanos::~Humanos() {
  delete[](humanos); delete(humanosDev); delete(indHumanosDev); 
}

/*
  Organiza os índices de acesso ao vetor de humanos.
  Para isso os agentes são ordenados por localidade, sendo
  então calculadas as posições iniciais e finais de cada
  segmento apontado pelo índice.
*/
void Humanos::atualizacaoIndices() {
  DVector<int> k2(ambiente->nQuadras, -1);
  DVector<int> v2(ambiente->nQuadras, -1);

  // Ordenação dos agentes humanos por quadra. 
  sort(
    humanosDev->begin(), humanosDev->end(), 
    MenorIdLocalidadeHumano()
  );

  // Obtenção dos identificadores das localidades de cada humano.
  DVector<int> k1(nHumanos);
  transform(
    humanosDev->begin(), humanosDev->end(), 
    k1.begin(), GetIdLocalidadeHumano()
  );

  // São obtidas as quantidades de agentes por quadra. 
  reduce_by_key(
    k1.begin(), k1.end(), v1, k2.begin(), v2.begin()
  );

  // Para as quadras sem agentes são inseridos no vetor de índices elementos 
  // com valor zero. 
  int nQuadrasSemAgentes = count(k2.begin(), k2.end(), -1);
  if (nQuadrasSemAgentes > 0) {
    v2.resize(v2.size() - nQuadrasSemAgentes);
    k2.resize(k2.size() - nQuadrasSemAgentes);
    sort(k2.begin(), k2.end());
    DVector<int> quadrasSemAgentes(nQuadrasSemAgentes);
    set_difference(
      t, t + ambiente->nQuadras, 
      k2.begin(), k2.end(), quadrasSemAgentes.begin()
    );
    for (int&& i : quadrasSemAgentes) {
      v2.insert(v2.begin() + i, 0);
    }
  }

  // Realiza uma soma parcial para obter os índices para as quadras. 
  inclusive_scan(
    v2.begin(), v2.end(), indHumanosDev->begin() + 1
  );
}

/*
  Retorna o total de memória ocupada pelo vetor de humanos.
*/
int Humanos::getMemoriaGPU() {
  int totMem = 0;
  totMem += (nHumanos * sizeof(Humano));
  totMem += (sizeIndHumanos * sizeof(int));
  return totMem;
}

/*
  Método responsável por inicializar e popular o vetor de humanos em GPU.
*/
void Humanos::toGPU() {
  humanosDev = new DVector<Humano>(humanos, humanos + nHumanos);
  indHumanosDev = new DVector<int>(sizeIndHumanos, 0);
  // Ponteiros para acesso aos vetores
  PhumanosDev = raw_pointer_cast(humanosDev->data());
  PindHumanosDev = raw_pointer_cast(indHumanosDev->data());
}

/*
  Método de inicialização de agentes humanos.
  São atribuídos valores padrão para os atributos necessários,
  além de valores determinados pelos parâmetros desta função.
*/
void Humanos::inicializarHumano(
  int id, int e, int x, int y, int l, int q,
  int s, int fe, int t, int k, int st, int a
) {
  // Determina os sorotipos contraídos
  int sc = (st == 0) ? 0 : 1 << (st - 1);

  // Atributos das variáveis bitstring
  SET_R_H(id, 0);
  SET_T_H(id, t);
  SET_F_H(id, 1);
  SET_M_H(id, 0);
  SET_K_H(id, k);

  SET_S_H(id, s);
  SET_FE_H(id, fe);
  SET_SD_H(id, e);
  SET_ST_H(id, st);
  SET_SC_H(id, sc);
  SET_A_H(id, a);
  SET_C_H(id, 0);
  SET_CV_H(id, 0);

  SET_X_H(id, x);
  SET_Q_H(id, q);

  SET_Y_H(id, y);
  SET_L_H(id, l);

  // Identificador aleatório
  RandPerc rand;
  SET_ID_H(id, ENTRE_FAIXA(0, MAX_UINT32, rand()));
}

/*
  Este método é responsável por inicializar um conjunto de agentes humanos.
  Parâmetros:
    n    - Número de agentes a serem inseridos.
    estado  - Estado de saúde dos agentes quanto à dengue
    sexo    - Sexo dos agentes
    fe      - Faixa etária dos agentes
    mov     - Estratégia de movimentação dos agentes
    i       - Referência à última posição ocupada dentro do vetor
*/
void Humanos::inserirHumanos(
  int n, int estado, int sexo, int fe, int mov, int& i
) {
  int p, x, y, l, q, t = 0, st = 0;
  RandPerc rand;

  for (int j = 0; j < n; ++j) {
    // Uma fração dos agentes ocupará posições aleatórias no ambiente. 
    if (rand() <= PROBABILIDADE_DISTRIBUICAO_HUMANOS(rand())) {
      mov = ALEATORIO;
      if (rand() <= 0.5) {
        // Escolhe uma posição pertencente à uma rua. 
        p = ENTRE_FAIXA(ambiente->indPosReg[0], ambiente->indPosReg[1], 
                        rand());
      } else {
        // Escolhe uma posição rural. 
        p = ENTRE_FAIXA(ambiente->indPosReg[1], ambiente->indPosReg[2], 
                        rand());
      }
      x = ambiente->pos[p].x; y = ambiente->pos[p].y;
      l = ambiente->pos[p].lote; q = ambiente->pos[p].quadra;
    } else {
      // Escolhe um trajeto para o agente. 
      t = ENTRE_FAIXA(ambiente->indTrajFE[fe],
                      ambiente->indTrajFE[fe + 1], rand());

      // Obtém o lote e quadra inicial do agente. 
      l = ambiente->rotas[ambiente->indRotas[ambiente->indTraj[t]] + 0];
      q = ambiente->rotas[ambiente->indRotas[ambiente->indTraj[t]] + 1];

      // Escolhe aleatoriamente uma posição inicial para o agente. 
      p = (ambiente->indPos[ambiente->indQuadras[2 * q] + l + 1] -
            ambiente->indPos[ambiente->indQuadras[2 * q] + l]);
      p = ENTRE_FAIXA(0, p, rand());

      x = ambiente->pos[ambiente->indPos[ambiente->indQuadras
                                        [q * 2] + l] + p].x;
      y = ambiente->pos[ambiente->indPos[ambiente->indQuadras
                                        [q * 2] + l] + p].y;
    }

    // Uma fração dos agentes recuperados são inseridos como assintomáticos. 
    int a = (estado == RECUPERADO and 
             rand() <= PROBABILIDADE_HUMANO_ASSINTOMATICO_(rand()));
    
    // Uma fração dos agentes infectantes ou recuperados possuem sorotipo 
    // diferente do predominante. 
    if (estado == INFECTANTE or estado == RECUPERADO) {
      if (rand() <= PROBABILIDADE_SOROTIPO_PREDOMINANTE(rand())) {
        st = SOROTIPO_PREDOMINANTE;
      } else {
        st = ENTRE_FAIXA(1, 5, rand());
      }
    }
    
    // Inicializa o novo agente. 
    inicializarHumano(i, estado, x, y, l, q, sexo, fe, t, mov, st, a);
    i += 1;
  }
}

/*
  Este método percorre os parâmetros de inicialização de humanos,
  chamando o método "inserirHumanos" para cada subgrupo de acordo com
  sexo, idade, estratégia de movimentação e estado de saúde.
*/
void Humanos::criarHumanos() {
  int i = 0;
  int desl = DESL_0_INI_H;
  for (int sexo = MASCULINO; sexo <= FEMININO; ++sexo) {
    for (int idade = BEBE; idade <= IDOSO; ++idade) {
      for (int mov = LOCAL; mov <= TRAJETO; ++mov) {
        for (int estado : { SUSCETIVEL, EXPOSTO, INFECTANTE, RECUPERADO }) {
          inserirHumanos(
            parametros->parametros[desl], estado, sexo, idade, mov, i
          );
          desl += 2; // Soma-se 2 pois cada parâmetro tem mínimo e máximo
        }
      }
    }
  }
}

/*
  Retorna o total de humanos de acordo com os parâmetros de inicialização.
*/
void Humanos::contarHumanos() {
  nHumanos = 0;
  for (int i = DESL_0_INI_H; i < DESL_1_MOV_H - N_PAR_0_INI_H; i += 2) {
    nHumanos += parametros->parametros[i];
  }
}
