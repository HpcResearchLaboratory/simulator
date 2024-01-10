#pragma once

#include <simulator/environment.hpp>
#include <simulator/output.hpp>
#include <simulator/parameters.hpp>
#include <simulator/simulation.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  class MonteCarlo {
    const Parameters parameters;
    const Environment environment;
    const Output output;

  public:
    MonteCarlo(Parameters parameters, Environment environment, Output output);
    auto run() const -> void;
  };
} // namespace simulator
