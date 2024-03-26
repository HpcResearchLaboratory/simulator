#include <simulator/parameters.hpp>

#include <filesystem>

#include <toml++/toml.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  auto Parameters::from_dir(const fs::path input_path) -> Parameters {
    return { toml::table(util::parse_toml(input_path)) };
  }

} // namespace simulator
