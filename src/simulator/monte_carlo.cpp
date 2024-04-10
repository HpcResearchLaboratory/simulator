#include <simulator/monte_carlo.hpp>
#include <simulator/simulation.hpp>

namespace simulator {
  MonteCarlo::MonteCarlo(const Environment& environment,
                         const Parameters& parameters)
    : environment(environment), parameters(parameters) {}

  auto MonteCarlo::run() const -> void {
    /*auto simulations_count = parameters.runs;*/
    /**/
    /*for (auto i = 0U; i < simulations_count; ++i) {*/
    /*  auto simulation = Simulation(environment, parameters);*/
    /*  simulation.run();*/
    /*}*/
  }
} // namespace simulator
