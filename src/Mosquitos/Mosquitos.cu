#include "Mosquitos.h"
#include "Fontes/Uteis/RandPerc.h"
#include "Fontes/Macros/MacrosGerais.h"
#include "Fontes/Macros/MacrosSO.h"
#include "Fontes/Macros/0_SIM.h"
#include "Fontes/Macros/0_INI_M.h"
#include "Fontes/Macros/3_TRA_M.h"
#include "Fontes/Macros/MacrosMosquitos.h"
#include "Fontes/Parametros.h"
#include "Fontes/Ambiente.h"

/*
  Estrutura de dados que representa um agente do tipo mosquito.
*/
__host__ __device__
Mosquito::Mosquito() {
  // Identificador do agente
  id = 0U;
  // Variáveis bitstring
  t1 = 0U; t2 = 0U; t3 = 0U; t4 = 0U;
}

/*
  Este operador verifica se um agente mosquito está morto.
*/
__host__ __device__
bool EstaMortoMosquito::operator()(Mosquito mosquito) {
  return GET_VD_M_ == MORTO;
}

/*
  Este operador verifica se um agente mosquito é fêmea, está no estado
  suscetível e está na fase alada.
*/
__host__ __device__
bool MosquitoFemeaSuscetivelAlado::operator()(Mosquito mosquito) {
  bool vivo = GET_VD_M_ == VIVO;
  bool femea = GET_S_M_ == FEMEA;
  bool suscetivel = GET_SD_M_ == SUSCETIVEL;
  bool ativo = GET_FS_M_ == ATIVA;
  bool decadente = GET_FS_M_ == DECADENTE;
  bool alado = ativo or decadente;
  return vivo and femea and suscetivel and alado;
}

/*
  Este operador verifica se um agente mosquito é fêmea e está na fase alada.
*/
__host__ __device__
bool MosquitoFemeaAlado::operator()(Mosquito mosquito) {
  bool vivo = GET_VD_M_ == VIVO;
  bool femea = GET_S_M_ == FEMEA;
  bool ativo = GET_FS_M_ == ATIVA;
  bool decadente = GET_FS_M_ == DECADENTE;
  bool alado = ativo or decadente;
  return vivo and femea and alado;
}

/*
  Este operador define o critério de ordenação por localidades
  do vetor de agentes mosquitos.
*/
__host__ __device__
bool LessQuadraMosquito::operator()(Mosquito mosquito1, Mosquito mosquito2) {
  Mosquito mosquito = mosquito1;
  int q_m1 = GET_Q_M_;
  mosquito = mosquito2;
  int q_m2 = GET_Q_M_;
  return q_m1 < q_m2;
}

/*
  Este operador retorna a localidade atual de um agente humano.
*/
__host__ __device__
int ToQuadraMosquito::operator()(Mosquito mosquito) {
  return GET_Q_M_;
}

/*
  Construtor da classe Mosquitos.
  Responsável pela inicialização do vetor de agentes mosquitos.
*/
Mosquitos::Mosquitos(Parametros *parametros, Ambiente *ambiente) {
  this->parametros = parametros;
  this->ambiente = ambiente;

  // Criação e inicialização dos agentes mosquitos.
  contarMosquitos();
  mosquitos = new Mosquito[nMosquitos]();
  criarMosquitos();
  maxMosquitos = PROPORCAO_MAXIMO_MOSQUITOS * nMosquitos;
  sizeIndMosquitos = ambiente->nQuadras + 1;

  alocarMosquitos = true;

  t = make_counting_iterator(0);
  v1 = make_constant_iterator(1);

  toGPU();

  atualizacaoIndices();
}

/*
  Destrutor da classe Mosquitos.
*/
Mosquitos::~Mosquitos() {
  delete[](mosquitos); delete(mosquitosDev); delete(indMosquitosDev);
}

/*
  Organiza os índices de acesso ao vetor de mosquitos.
  Para isso os agentes são ordenados por localidade, sendo
  então calculadas as posições iniciais e finais de cada
  segmento apontado pelo índice.
*/
void Mosquitos::atualizacaoIndices() {
  DVector<int> k2(ambiente->nQuadras, -1);
  DVector<int> v2(ambiente->nQuadras, -1);

  // Ordenação dos agentes mosquitos por quadra.
  sort(
    mosquitosDev->begin(), mosquitosDev->end(),
    LessQuadraMosquito()
  );

  // Conversão dos agentes mosquitos para identificadores de quadra.
  DVector<int> k1(nMosquitos);
  transform(
    mosquitosDev->begin(), mosquitosDev->end(),
    k1.begin(), ToQuadraMosquito()
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
    v2.begin(), v2.end(), indMosquitosDev->begin() + 1
  );
}

/*
  Retorna o total de memória ocupada pelo vetor de mosquitos.
*/
int Mosquitos::getMemoriaGPU() {
  int totMem = 0;
  totMem += (nMosquitos * sizeof(Mosquito));
  totMem += (sizeIndMosquitos * sizeof(int));
  return totMem;
}

/*
  Método responsável por inicializar e popular o vetor de mosquitos em GPU.
*/
void Mosquitos::toGPU() {
  mosquitosDev = new DVector<Mosquito>(mosquitos, mosquitos + nMosquitos);
  indMosquitosDev = new DVector<int>(sizeIndMosquitos, 0);

  PmosquitosDev = raw_pointer_cast(mosquitosDev->data());
  PindMosquitosDev = raw_pointer_cast(indMosquitosDev->data());

  // Copia as quantidades de ovos da CPU para GPU
  copy_n(
    ambiente->capFocos, ambiente->sizeFocos, ambiente->capFocosDev->begin()
  );
}

/*
  Método de inicialização de agentes mosquitos.
  São atribuídos valores padrão para os atributos necessários,
  além de valores determinados pelos parâmetros desta função.
*/
void Mosquitos::inicializarMosquito(
  int id, int s, int sw, int fs, int ie, int sd, int st,
  int q, int l, int x, int y
) {
  SET_S_M(id, s);
  SET_SW_M(id, sw);
  SET_FS_M(id, fs);
  SET_IE_M(id, ie);
  SET_SD_M(id, sd);
  SET_ST_M(id, st);
  SET_VD_M(id, VIVO);
  SET_C_M(id, 0);

  SET_CR_M(id, 0);
  SET_FG_M(id, 0);
  SET_TI_M(id, SEM_INFLUENCIA);
  SET_FM_M(id, 1);
  SET_FP_M(id, 0);
  SET_FV_M(id, 0);
  SET_CG_M(id, 0);
  SET_CE_M(id, 0);
  SET_PR_M(id, NENHUM);
  SET_AM_M(id, 0);
  SET_TA_M(id, NENHUM);
  SET_CP_M(id, 0);

  SET_X_M(id, x);
  SET_Q_M(id, q);

  SET_Y_M(id, y);
  SET_L_M(id, l);

  // Sorteia um identificador para o novo agente
  RandPerc rand;
  SET_ID_M(id, ENTRE_FAIXA(0, MAX_UINT32, rand()));
}

/*
  Este método é responsável por inicializar um conjunto de agentes mosquitos.

  Parâmetros:
    quantidade  - Número de agentes a serem inseridos.
    s           - Sexo dos agentes
    sw          - Estado de saúde dos agentes quanto à Wolbachia
    fs          - Fase dos agentes (ovo, larva, pupa, adulta, decadente)
    sd          - Estado de saúde dos agentes quanto à dengue
    st          - Sorotipo do vírus caso os agentes estejam infectados
    i           - Referência à última posição ocupada dentro do vetor
*/
void Mosquitos::inserirMosquitos(
  int quantidade, int s, int sw, int fs, int sd, int st, int& i
) {
  int p, l, q, ie;
  RandPerc rand;

  for (int j = 0; j < quantidade; ++j) {
    // Uma fração dos agentes é distribuída em posições de lotes pertencentes
    // à pontos estratégicos.
    if (rand() <= PROBABILIDADE_DISTRIBUICAO_MOSQUITOS_(rand()) and
        ambiente->sizePontEst > 0) {
      p = ENTRE_FAIXA(0, ambiente->sizePontEst / 2, rand());
      q = ambiente->pontEst[2 * p + 0];
      l = ambiente->pontEst[2 * p + 1];
    } else {
      // Escolhe uma posicao urbana.
      p = ENTRE_FAIXA(ambiente->indPosReg[2], ambiente->indPosReg[3], rand());
      l = ambiente->pos[p].lote;
      q = ambiente->pos[p].quadra;
    }
    // Escolhe aleatoriamente uma posição inicial para o agente.
    p = (ambiente->indPos[ambiente->indQuadras[2 * q] + l + 1] -
          ambiente->indPos[ambiente->indQuadras[2 * q] + l]);
    p = ENTRE_FAIXA(0, p, rand());
    int x = ambiente->pos[ambiente->indPos[ambiente->indQuadras[q * 2] + l] + p].x;
    int y = ambiente->pos[ambiente->indPos[ambiente->indQuadras[q * 2] + l] + p].y;

    // Escolhe a idade inicial do agente.
    switch (fs) {
      case ATIVA: ie = IDADE_MOSQUITOS_ATIVOS_(s, sw, rand());
        break;
      case DECADENTE: ie = IDADE_MOSQUITOS_DECADENTES_(s, sw, rand());
        break;
    }

    // Inicializa o novo agente.
    inicializarMosquito(i, s, sw, fs, ie, sd, st, q, l, x, y);
    i += 1;
  }
}

/*
  Este método é responsável por inicializar um conjunto de agentes na fase
  aquática dentro de posições de foco.

  Parâmetros:
    quantidade  - Número de agentes a serem inseridos.
    s           - Sexo dos agentes
    sw          - Estado de saúde dos agentes quanto à Wolbachia
    fs          - Fase dos agentes (ovo, larva, pupa, adulta, decadente)
    sd          - Estado de saúde dos agentes quanto à dengue
    st          - Sorotipo do vírus caso os agentes estejam infectados
    i           - Referência à última posição ocupada dentro do vetor
*/
void Mosquitos::inserirOvosEmFocos(
  int quantidade, int s, int sw, int fs, int sd, int st, int& i
) {
  RandPerc rand;
  for (int j = 0; j < quantidade; j++) {
    int idFoco = ENTRE_FAIXA(0, ambiente->sizeFocos, rand());
    ambiente->capFocos[idFoco]++;
    int p = ambiente->focos[idFoco];
    int x = ambiente->pos[p].x;
    int y = ambiente->pos[p].y;
    int q = ambiente->pos[p].quadra;
    int l = ambiente->pos[p].lote;
    int ie = IDADE_MOSQUITOS_NAO_ALADOS_(fs, rand());
    inicializarMosquito(i, s, sw, fs, ie, sd, st, q, l, x, y);
    i += 1;
  }
}

/*
  Este método percorre os parâmetros de inicialização de mosquitos, chamando
  os métodos "inserirHumanos" e "inserirOvosEmFocos" para cada subgrupo de
  acordo com sexo, fase e estado de saúde para dengue e Wolbachia.
*/
void Mosquitos::criarMosquitos() {
  int i = 0;
  for (int sexo = MACHO; sexo <= FEMEA; ++sexo) {
    int sorotipo = 0, nSau, nWol;

    // Inserção de mosquitos ovos.
    nSau = QUANTIDADE_MOSQUITOS_SAUDAVEIS(sexo, 0);
    nWol = QUANTIDADE_MOSQUITOS_WOLBACHIA(sexo, 0);
    inserirOvosEmFocos(nSau, sexo, SAUDAVEL, OVO, SUSCETIVEL, sorotipo, i);
    inserirOvosEmFocos(nWol, sexo, WOLBACHIA, OVO, SUSCETIVEL, sorotipo, i);

    // Inserção de mosquitos ativos.
    nSau = QUANTIDADE_MOSQUITOS_SAUDAVEIS(sexo, 1);
    nWol = QUANTIDADE_MOSQUITOS_WOLBACHIA(sexo, 1);
    inserirMosquitos(nSau, sexo, SAUDAVEL, ATIVA, SUSCETIVEL, sorotipo, i);
    inserirMosquitos(nWol, sexo, WOLBACHIA, ATIVA, SUSCETIVEL, sorotipo, i);

    // Inserção de mosquitos decadentes.
    nSau = QUANTIDADE_MOSQUITOS_SAUDAVEIS(sexo, 2);
    nWol = QUANTIDADE_MOSQUITOS_WOLBACHIA(sexo, 2);
    inserirMosquitos(nSau, sexo, SAUDAVEL, DECADENTE, SUSCETIVEL, sorotipo, i);
    inserirMosquitos(nWol, sexo, WOLBACHIA, DECADENTE, SUSCETIVEL, sorotipo, i);
  }
  // Inserção de mosquitos fêmeas ativas infectadas com Dengue.
  for (int sorotipo = SOROTIPO_1; sorotipo <= SOROTIPO_4; sorotipo++) {
    int nInf = QUANTIDADE_MOSQUITOS_DENGUE(sorotipo);
    inserirMosquitos(nInf, FEMEA, SAUDAVEL, ATIVA, INFECTANTE, sorotipo, i);
  }
}

/*
  Retorna o total de mosquitos de acordo com os parâmetros de inicialização.
*/
void Mosquitos::contarMosquitos() {
  nMosquitos = 0;
  for (int sexo = MACHO; sexo <= FEMEA; ++sexo) {
    for (int fase = 0; fase <= 2; fase++) {
      nMosquitos += QUANTIDADE_MOSQUITOS_SAUDAVEIS(sexo, fase);
      nMosquitos += QUANTIDADE_MOSQUITOS_WOLBACHIA(sexo, fase);
    }
  }
  for (int sorotipo = SOROTIPO_1; sorotipo <= SOROTIPO_4; sorotipo++) {
    nMosquitos += QUANTIDADE_MOSQUITOS_DENGUE(sorotipo);
  }
}
