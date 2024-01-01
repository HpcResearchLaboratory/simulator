#include <simulator/parameters.hpp>

#include <filesystem>

#include <toml++/toml.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  auto Parameters::from_dir(fs::path input_path) -> Parameters {
    return { input_path };
  }

} // namespace simulator
