#include <simulator/environment.hpp>

#include <filesystem>

#include <toml++/toml.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  auto Environment::from_dir(fs::path input_path) -> Environment {
    return { input_path };
  }

} // namespace simulator
