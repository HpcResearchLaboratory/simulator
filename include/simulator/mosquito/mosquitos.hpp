#pragma once

#include <simulator/environment.hpp>
#include <simulator/mosquito/mosquito.hpp>
#include <simulator/parameters.hpp>

namespace simulator {

  class Mosquitos {
    const Parameters& parameters;
    const Environment& environment;
    std::vector<Mosquito> mosquitos;
    void update_indexes();

  public:
    Mosquitos(const Parameters& parameters, const Environment& environment);
  };
} // namespace simulator
