#pragma once

#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>

namespace simulator {

  class Humans {
    const Parameters& parameters;
    const Environment& environment;
    std::vector<Human> humans;

  public:
    Humans(const Parameters& parameters, const Environment& environment);
  };
} // namespace simulator
