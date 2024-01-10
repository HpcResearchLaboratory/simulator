#pragma once

#include <simulator/environment.hpp>
#include <simulator/output.hpp>
#include <simulator/parameters.hpp>

namespace simulator {
  class Simulation {
    const std::uint64_t id;

    const Parameters& parameters;
    const Environment& environment;
    const Output& output;

  public:
    Simulation(std::uint64_t id, const Parameters& parameters,
               const Environment& environment, const Output& output);
    auto run() const -> void;
  };
} // namespace simulator
