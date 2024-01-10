#include <simulator/human/humans.hpp>
#include <simulator/simulation.hpp>

namespace simulator {
  Simulation::Simulation(std::uint64_t id, const Parameters& parameters,
                         const Environment& environment, const Output& output)
    : id(id), parameters(parameters), environment(environment), output(output) {
    const auto humans = Humans { parameters, environment };
  }
  auto Simulation::run() const -> void {
    const auto number_of_cycles =
      *parameters.table["simulation"]["cycles_per_simulation"]
         .as<std::int64_t>();
    for (auto cycle = 0; cycle < number_of_cycles; ++cycle) {
    }
  }
} // namespace simulator
