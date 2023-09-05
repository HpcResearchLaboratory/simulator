#ifndef __MACROS_SO__
#define __MACROS_SO__

#include <string>
using std::string;

// Comando para criação de uma pasta no Linux.
#define CRIAR_PASTA string("mkdir -p ")
// Comando para remoção de uma pasta no Linux.
#define EXCLUIR_PASTA string("rm -rf ")
// Separador utilizado no Linux para caminhos de pastas e arquivos.
#define SEP string("/")

#endif
