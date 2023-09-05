#include "Timer.h"

/*
  Classe responsável pelo cálculo do tempo de execução entre dois trechos de 
  código. Esta classe pode ser utilizada para mensurar o tempo gasto na 
  execução de métodos em GPU. O método "start" inicia a contagem do tempo, 
  "stop" termina a contagem do tempo e "getTime" retorna o tempo dispendido 
  em segundos. 
*/
Timer::Timer() {
  this->total = 0;
}

/*
  Método responsável por armazenar o tempo inicial da ocorrência de um evento. 
*/
void Timer::start() {
  cudaEventCreate(&begin);
  cudaEventCreate(&end);
  cudaEventRecord(begin);
}

/*
  Método responsável por armazenar o tempo final da ocorrência de um evento. 
  Com os tempos iniciais e finais é possível calcular o tempo dispendido em 
  uma operação. 
*/
void Timer::stop() {
  cudaEventRecord(end);
  cudaEventSynchronize(end);
  cudaEventElapsedTime(&parcial, begin, end);
  total += parcial;
}

/*
  Retorna o tempo calculado em segundos. 
*/
double Timer::getTime() {
  return total / 1000;
}
