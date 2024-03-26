#include <simulator/human/humans.hpp>
#include <simulator/mosquito/mosquitos.hpp>
#include <simulator/simulation.hpp>
#include <utility>

namespace simulator {
  Simulation::Simulation(std::uint64_t id, const Parameters& parameters,
                         const Environment& environment, const Output& output,
                         Humans humans, Mosquitos mosquitos)
    : id(id), parameters(parameters), environment(environment), output(output),
      humans(std::move(humans)), mosquitos(std::move(mosquitos)) {}

  auto Simulation::run() -> void {
    const auto number_of_cycles =
      *parameters.table["simulation"]["cycles_per_simulation"]
         .as<std::int64_t>();
    const auto number_of_subcycles =
      *parameters.table["simulation"]["subcycles_per_period"]
         .as<std::int64_t>();

    for (auto cycle = 0; cycle < number_of_cycles; ++cycle) {
      for (auto period = static_cast<std::int64_t>(Period::Evening);
           period <= static_cast<std::int64_t>(Period::Afternoon); period++) {
        humans_movement();
        for (auto subcycle = 0; subcycle < number_of_subcycles; subcycle++) {
          mosquitos_movement();

          mosquitos_contact(static_cast<Period>(period));
          mosquitos_humans_contact(static_cast<Period>(period));
        }
      }

      mosquitos_phase_transition();
      mosquitos_state_transition();
      humans_state_transition();

      mosquitos_age_control();
      mosquitos_selection_control();
      humans_selection_control();

      mosquitos_generation();

      humans_insertion();
      mosquitos_insertion();
    }
  }

  auto Simulation::humans_movement() -> void {};
  auto Simulation::mosquitos_movement() -> void {};

  auto Simulation::mosquitos_contact(Period period) -> void {};
  auto Simulation::mosquitos_humans_contact(Period period) -> void {};

  auto Simulation::mosquitos_phase_transition() -> void {};
  auto Simulation::mosquitos_state_transition() -> void {};
  auto Simulation::humans_state_transition() -> void {};

  auto Simulation::mosquitos_age_control() -> void {};
  auto Simulation::mosquitos_selection_control() -> void {};
  auto Simulation::humans_selection_control() -> void {};

  auto Simulation::mosquitos_generation() -> void {};

  auto Simulation::humans_insertion() -> void {};
  auto Simulation::mosquitos_insertion() -> void {};

} // namespace simulator
