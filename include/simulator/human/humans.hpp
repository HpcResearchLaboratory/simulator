#pragma once

#include <simulator/environment.hpp>
#include <simulator/human/human.hpp>
#include <simulator/parameters.hpp>

namespace simulator {

  class Humans {
    const Parameters& parameters;
    const Environment& environment;
    std::vector<Human> humans;
    void update_indexes();

  public:
    Humans(const Parameters& parameters, const Environment& environment);
  };
} // namespace simulator
