#pragma once

#include <simulator/util/toml.hpp>

#include <filesystem>

#include <toml++/toml.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  struct Parameters {
    toml::table table;
    Parameters(fs::path input_path) : table(util::parse_toml(input_path)) {}
    static auto from_dir(fs::path input_path) -> Parameters;
  };
} // namespace simulator
