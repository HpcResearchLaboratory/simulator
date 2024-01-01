#include <simulator/simulation.hpp>

#include <iostream>

namespace simulator {
  auto Simulation::run() const -> void {
    std::cout << "Simulation started" << std::endl;
  }
} // namespace simulator
