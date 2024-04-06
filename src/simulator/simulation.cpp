#include <iostream>
#include <simulator/agents/agent.hpp>
#include <simulator/environment.hpp>
#include <simulator/simulation.hpp>
#include <simulator/util/random.hpp>

namespace simulator {
  Simulation::Simulation(const Environment& environment,
                         const Parameters& parameters)
    : environment(environment), parameters(parameters) {}

  auto Simulation::run() -> void {
    const auto cycles = parameters.cycles;

    insertion();
    for (std::size_t i = 0; i < cycles; i++) {
      movement();
      contact();
      transition();
    }
  }

  auto Simulation::insertion() -> void {
    humans.reserve(
      parameters.human_initial_susceptible + parameters.human_initial_exposed +
      parameters.human_initial_infected + parameters.human_initial_recovered);
    mosquitos.reserve(parameters.mosquito_initial_susceptible +
                      parameters.mosquito_initial_infected +
                      parameters.mosquito_initial_recovered);

    const auto random_position_id =
      [random_index =
         util::make_random_generator_in_range(0UL, environment.size() - 1),
       this]() {
        return environment.get_nth_point_id(random_index());
      };

    auto human_id = 0UL;

    for (std::size_t i = 0; i < parameters.human_initial_susceptible; i++) {
      humans.insert(
        Human { Human::State::Susceptible, human_id++, random_position_id() });
    }

    for (std::size_t i = 0; i < parameters.human_initial_exposed; i++) {
      humans.insert(
        Human { Human::State::Exposed, human_id++, random_position_id() });
    }

    for (std::size_t i = 0; i < parameters.human_initial_infected; i++) {
      humans.insert(
        Human { Human::State::Infected, human_id++, random_position_id() });
    }

    for (std::size_t i = 0; i < parameters.human_initial_recovered; i++) {
      humans.insert(
        Human { Human::State::Recovered, human_id++, random_position_id() });
    }

    auto mosquito_id = 0UL;

    for (std::size_t i = 0; i < parameters.mosquito_initial_susceptible; i++) {
      mosquitos.insert(Mosquito { Mosquito::State::Susceptible, mosquito_id++,
                                  random_position_id() });
    }

    for (std::size_t i = 0; i < parameters.mosquito_initial_infected; i++) {
      mosquitos.insert(Mosquito { Mosquito::State::Infected, mosquito_id++,
                                  random_position_id() });
    }

    for (std::size_t i = 0; i < parameters.mosquito_initial_recovered; i++) {
      mosquitos.insert(Mosquito { Mosquito::State::Recovered, mosquito_id++,
                                  random_position_id() });
    }
  }

  auto Simulation::movement() -> void {
    for (auto& human : humans) {
      const auto position = human.position;
      const auto edges = environment.get_edges(position);
      const auto random_edge =
        util::make_random_generator_in_range(0UL, edges.size() - 1)();
      human.position =
        *std::next(edges.begin(), static_cast<std::ptrdiff_t>(random_edge));
    }

    for (auto& mosquito : mosquitos) {
      const auto position_id = mosquito.position;
      const auto edges = environment.get_edges(position_id);
      const auto random_edge =
        util::make_random_generator_in_range(0UL, edges.size() - 1)();
      mosquito.position =
        *std::next(edges.begin(), static_cast<std::ptrdiff_t>(random_edge));
    }
  }

  auto Simulation::contact() -> void {
    const auto& points = environment.get_points();

    for (const auto& [id, point] : points) {
      std::cout << "ID: " << id << " - Point: (" << point.first << ", "
                << point.second << ")\n";
    }
  }

  auto Simulation::transition() -> void {}
} // namespace simulator
