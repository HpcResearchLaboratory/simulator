#pragma once

#include <simulator/util/toml.hpp>

#include <filesystem>

#include <toml++/toml.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  struct Environment {
    toml::table table;
    Environment(fs::path input_path) : table(util::parse_toml(input_path)) {}
    static auto from_dir(fs::path input_path) -> Environment;
  };
} // namespace simulator
