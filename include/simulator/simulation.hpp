#pragma once

#include <simulator/agents/human.hpp>
#include <simulator/agents/mosquito.hpp>
#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>

#include <unordered_set>

namespace simulator {
  class Simulation {
    const Environment& environment;
    const Parameters& parameters;

    std::unordered_set<Human> humans;
    std::unordered_set<Mosquito> mosquitos;

    auto insertion() -> void;
    auto movement() -> void;
    auto contact() -> void;
    auto transition() -> void;

  public:
    Simulation(const Environment& environment, const Parameters& parameters);
    auto run() -> void;
  };
} // namespace simulator
