#pragma once

#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>

namespace simulator {
  class MonteCarlo {
    const Environment& environment;
    const Parameters& parameters;

  public:
    MonteCarlo(const Environment& environment, const Parameters& parameters);
    auto run() const -> void;
  };
} // namespace simulator
