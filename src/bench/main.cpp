#include <filesystem>
#include <iostream>

#include <argparse/argparse.hpp>

namespace fs = std::filesystem;

auto main() -> int {
  argparse::ArgumentParser program("simula", "v1.0.0");

  program.add_argument("-i", "--input")
    .help("Input directory")
    .default_value(std::string("./assets/input"))
    .action([](const std::string& value) -> fs::path { return value; });

  program.add_argument("-o", "--output")
    .help("Output directory")
    .default_value(std::string("./assets/output"))
    .action([](const std::string& value) -> fs::path { return value; });
  std::cout << "Blazing fast :)" << std::endl;
  return 0;
}
