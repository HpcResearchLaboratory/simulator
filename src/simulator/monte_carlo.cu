#include <simulator/environment.hpp>
#include <simulator/monte_carlo.hpp>
#include <simulator/parameters.hpp>

namespace simulator {

  MonteCarlo::MonteCarlo(Parameters parameters, Environment environment,
                         Output output)
    : parameters(std::move(parameters)), environment(std::move(environment)),
      output(std::move(output)) {}

  auto MonteCarlo::run() const -> void {
    const auto number_of_simulations =
      *parameters.table["simulation"]["number_of_simulations"]
         .as<std::int64_t>();

    for (auto i = 0ull; i < number_of_simulations; ++i) {
      const auto humans = Humans { parameters, environment };
      const auto mosquitos = Mosquitos { parameters, environment };
      auto simulation =
        Simulation { i, parameters, environment, output, humans, mosquitos };
      simulation.run();
    }
  }
} // namespace simulator
