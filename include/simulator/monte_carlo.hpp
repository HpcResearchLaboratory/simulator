#pragma once

#include <simulator/simulation.hpp>

#include <filesystem>

namespace simulator {
  namespace fs = std::filesystem;

  class MonteCarlo {
    fs::path input_path;
    fs::path output_path;
    bool subcycle_output;

  public:
    MonteCarlo(fs::path input_path, fs::path output_path,
               bool subcycle_output = false);

    auto run() const -> void;
  };
} // namespace simulator
