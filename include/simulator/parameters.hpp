#pragma once

#include <simulator/util/toml.hpp>

#include <filesystem>

#include <toml++/toml.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  struct Parameters {
    const toml::table table;
    static auto from_dir(const fs::path input_path) -> Parameters;
  };
} // namespace simulator
