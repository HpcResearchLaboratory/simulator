#pragma once

#include <simulator/environment.hpp>
#include <simulator/human/humans.hpp>
#include <simulator/mosquito/mosquitos.hpp>
#include <simulator/output.hpp>
#include <simulator/parameters.hpp>

namespace simulator {
  class Simulation {
    enum class Period {
      Morning,
      Afternoon,
      Evening
    };
    const std::uint64_t id;

    const Parameters& parameters;
    const Environment& environment;
    const Output& output;

    Humans humans;
    Mosquitos mosquitos;

    auto humans_movement() -> void;
    auto mosquitos_movement() -> void;

    auto mosquitos_contact(Period period) -> void;
    auto mosquitos_humans_contact(Period period) -> void;

    auto mosquitos_phase_transition() -> void;
    auto mosquitos_state_transition() -> void;
    auto humans_state_transition() -> void;

    auto mosquitos_age_control() -> void;
    auto mosquitos_selection_control() -> void;
    auto humans_selection_control() -> void;

    auto mosquitos_generation() -> void;

    auto humans_insertion() -> void;
    auto mosquitos_insertion() -> void;

  public:
    Simulation(std::uint64_t id, const Parameters& parameters,
               const Environment& environment, const Output& output,
               Humans humans, Mosquitos mosquitos);
    auto run() -> void;
  };
} // namespace simulator
