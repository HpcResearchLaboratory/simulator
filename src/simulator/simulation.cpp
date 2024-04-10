#include <simulator/agent/human.hpp>
#include <simulator/agent/mosquito.hpp>
#include <simulator/environment.hpp>
#include <simulator/result.hpp>
#include <simulator/simulation.hpp>
#include <simulator/util/functional.hpp>
#include <simulator/util/random.hpp>

#include <cstddef>
#include <execution>
#include <memory>

namespace simulator {
  Simulation::Simulation(std::unique_ptr<const Environment> environment,
                         std::unique_ptr<const Parameters> parameters) noexcept
    : environment(std::move(environment)), parameters(std::move(parameters)),
      humans(std::make_unique<std::vector<agent::Human>>(
        this->parameters->human_initial_susceptible +
        this->parameters->human_initial_exposed +
        this->parameters->human_initial_infected +
        this->parameters->human_initial_recovered)),
      mosquitos(std::make_unique<std::vector<agent::Mosquito>>(
        this->parameters->mosquito_initial_susceptible +
        this->parameters->mosquito_initial_infected +
        this->parameters->mosquito_initial_recovered)),
      agents_in_position(
        std::make_unique<std::vector<
          std::pair<std::vector<std::size_t>, std::vector<std::size_t>>>>(
          this->environment->size)) {}

  auto Simulation::run() noexcept -> void {
    const auto cycles = parameters->cycles;

    insertion();
    for (std::size_t i = 0; i < cycles; i++) {
      movement();
      contact();
      transition();
      output();
    }
  }

  auto Simulation::insertion() noexcept -> void {
    const auto random_position = util::make_cpu_rng(0UL, environment->size - 1);
    auto human_id = 0UL;
    auto& humans = *this->humans;
    auto& agents_in_position = *this->agents_in_position;

    for (std::size_t i = 0; i < parameters->human_initial_susceptible; i++) {
      const auto position = random_position();
      humans[human_id] = agent::Human { agent::Human::State::Susceptible,
                                        human_id, position, 0 };
      std::get<0>(agents_in_position[position]).push_back(human_id++);
    }

    for (std::size_t i = 0; i < parameters->human_initial_exposed; i++) {
      const auto position = random_position();
      humans[human_id] =
        agent::Human { agent::Human::State::Exposed, human_id, position, 0 };
      std::get<0>(agents_in_position[position]).push_back(human_id++);
    }

    for (std::size_t i = 0; i < parameters->human_initial_infected; i++) {
      const auto position = random_position();
      humans[human_id] =
        agent::Human { agent::Human::State::Infected, human_id, position, 0 };
      std::get<0>(agents_in_position[position]).push_back(human_id++);
    }

    for (std::size_t i = 0; i < parameters->human_initial_recovered; i++) {
      const auto position = random_position();
      humans[human_id] =
        agent::Human { agent::Human::State::Recovered, human_id, position, 0 };
      std::get<0>(agents_in_position[position]).push_back(human_id++);
    }

    auto& mosquitos = *this->mosquitos;
    auto mosquito_id = 0UL;

    for (std::size_t i = 0; i < parameters->mosquito_initial_susceptible; i++) {
      const auto position = random_position();
      mosquitos[mosquito_id] =
        agent::Mosquito { agent::Mosquito::State::Susceptible, mosquito_id,
                          position, 0 };
      std::get<1>(agents_in_position[position]).push_back(mosquito_id++);
    }

    for (std::size_t i = 0; i < parameters->mosquito_initial_infected; i++) {
      const auto position = random_position();
      mosquitos[mosquito_id] =
        agent::Mosquito { agent::Mosquito::State::Infected, mosquito_id,
                          position, 0 };
      std::get<1>(agents_in_position[position]).push_back(mosquito_id++);
    }

    for (std::size_t i = 0; i < parameters->mosquito_initial_recovered; i++) {
      const auto position = random_position();
      mosquitos[mosquito_id] =
        agent::Mosquito { agent::Mosquito::State::Recovered, mosquito_id,
                          position, 0 };
      std::get<1>(agents_in_position[position]).push_back(mosquito_id++);
    }
  }

  auto Simulation::movement() noexcept -> void {
    std::for_each(
      std::execution::par_unseq, std::begin(*humans), std::end(*humans),
      [environment = environment.get(),
       seed =
         std::chrono::high_resolution_clock::now().time_since_epoch().count()](
        auto& human) mutable noexcept {
        auto& edges = environment->edges[human.position];
        auto rng = util::make_gpu_rng(0UL, edges.size() - 1, seed);
        human.position = edges[rng(human.id)];
      });

    std::for_each(
      std::execution::par_unseq, std::begin(*mosquitos), std::end(*mosquitos),
      [environment = environment.get(),
       seed =
         std::chrono::high_resolution_clock::now().time_since_epoch().count()](
        auto& mosquito) mutable noexcept {
        auto& edges = environment->edges[mosquito.position];
        auto rng = util::make_gpu_rng(0UL, edges.size() - 1, seed);
        mosquito.position = edges[rng(mosquito.id)];
      });
  }

  auto Simulation::contact() noexcept -> void {
    std::for_each(
      std::execution::seq, std::begin(*agents_in_position),
      std::end(*agents_in_position),
      [environment = environment.get(), parameters = parameters.get(),
       humans = humans.get(), mosquitos = mosquitos.get(),
       seed =
         std::chrono::high_resolution_clock::now().time_since_epoch().count()](
        auto& agents) noexcept {
        auto& humans_in_pos = std::get<0>(agents);
        auto& mosquitos_in_pos = std::get<1>(agents);

        for (const auto& human_id : humans_in_pos) {
          for (const auto& mosquito_id : mosquitos_in_pos) {
            auto& human = humans->at(human_id);
            auto& mosquito = mosquitos->at(mosquito_id);
            auto rng = util::make_gpu_rng(0.0, 1.0, seed);

            if (human.state == agent::Human::State::Susceptible &&
                mosquito.state == agent::Mosquito::State::Infected &&
                (rng(human.id) < parameters->human_infection_rate)) {
              human.state = agent::Human::State::Exposed;
            } else if (human.state == agent::Human::State::Infected &&
                       mosquito.state == agent::Mosquito::State::Susceptible &&
                       (rng(mosquito.id) <
                        parameters->mosquito_infection_rate)) {
              mosquito.state = agent::Mosquito::State::Infected;
            }
          }
        }
      });

    std::for_each(
      std::execution::seq, std::begin(*agents_in_position),
      std::end(*agents_in_position),
      [environment = environment.get(), parameters = parameters.get(),
       humans = humans.get(), mosquitos = mosquitos.get(),
       seed =
         std::chrono::high_resolution_clock::now().time_since_epoch().count()](
        auto& agents) noexcept {
        auto& mosquitos_in_pos = std::get<1>(agents);
        for (const auto& mosquito_id : mosquitos_in_pos) {
          for (const auto& mosquito_id2 : mosquitos_in_pos) {
            if (mosquito_id != mosquito_id2) {
              const auto& mosquito = mosquitos->at(mosquito_id);
              const auto& mosquito2 = mosquitos->at(mosquito_id2);
              auto rng = util::make_gpu_rng(0.0, 1.0, seed);

              if (mosquito.state == agent::Mosquito::State::Infected &&
                  mosquito2.state == agent::Mosquito::State::Susceptible &&
                  (rng(mosquito.id) < parameters->mosquito_infection_rate)) {
                mosquito2.state = agent::Mosquito::State::Infected;
              } else if (mosquito.state ==
                           agent::Mosquito::State::Susceptible &&
                         mosquito2.state == agent::Mosquito::State::Infected &&
                         (rng(mosquito2.id) <
                          parameters->mosquito_infection_rate)) {
                mosquito.state = agent::Mosquito::State::Infected;
              }
            }
          }
        }
      });
  }

  auto Simulation::transition() noexcept -> void {
    std::for_each(
      std::execution::par_unseq, std::begin(*humans), std::end(*humans),
      [parameters = parameters.get()](auto& human) mutable noexcept {
        switch (human.state) {
          case agent::Human::State::Exposed:
            if (human.counter >= parameters->human_transition_period_exposed) {
              human.state = agent::Human::State::Infected;
              human.counter = 0;
            } else {
              human.counter++;
            }
            break;
          case agent::Human::State::Infected:
            if (human.counter >= parameters->human_transition_period_infected) {
              human.state = agent::Human::State::Recovered;
              human.counter = 0;
            } else {
              human.counter++;
            }
            break;
          case agent::Human::State::Recovered:
            if (human.counter >=
                parameters->human_transition_period_recovered) {
              human.state = agent::Human::State::Susceptible;
              human.counter = 0;
            } else {
              human.counter++;
            }
            break;
          case agent::Human::State::Susceptible:
            human.counter++;
            break;
        }
      });

    std::for_each(
      std::execution::par_unseq, std::begin(*mosquitos), std::end(*mosquitos),
      [parameters = parameters.get()](auto& mosquito) mutable noexcept {
        switch (mosquito.state) {
          case agent::Mosquito::State::Infected:
            if (mosquito.counter >=
                parameters->mosquito_transition_period_infected) {
              mosquito.state = agent::Mosquito::State::Recovered;
              mosquito.counter = 0;
            } else {
              mosquito.counter++;
            }
            break;
          case agent::Mosquito::State::Recovered:
            if (mosquito.counter >=
                parameters->mosquito_transition_period_recovered) {
              mosquito.state = agent::Mosquito::State::Susceptible;
              mosquito.counter = 0;
            } else {
              mosquito.counter++;
            }
            break;
          case agent::Mosquito::State::Susceptible:
            mosquito.counter++;
            break;
        }
      });
  }

  auto Simulation::output() noexcept -> void {
    auto result = std::transform_reduce(
      std::execution::par_unseq, std::begin(*humans), std::end(*humans),
      std::begin(*mosquitos), Result { { 0, 0, 0, 0 }, { 0, 0, 0 } },
      [](Result result1, Result result2) {
        const auto& [h1, m1] = result1;
        const auto& [h2, m2] = result2;
        const auto& [s1, e1, i1, r1] = h1;
        const auto& [s2, e2, i2, r2] = h2;
        const auto& [s3, i3, r3] = m1;
        const auto& [s4, i4, r4] = m2;

        return Result { { s1 + s2, e1 + e2, i1 + i2, r1 + r2 },
                        { s3 + s4, i3 + i4, r3 + r4 } };
      },
      [](const auto& human, const auto& mosquito) {
        return Result { { human.state == agent::Human::State::Susceptible,
                          human.state == agent::Human::State::Exposed,
                          human.state == agent::Human::State::Infected,
                          human.state == agent::Human::State::Recovered },
                        { mosquito.state == agent::Mosquito::State::Susceptible,
                          mosquito.state == agent::Mosquito::State::Infected,
                          mosquito.state ==
                            agent::Mosquito::State::Recovered } };
      });
    auto [humans, mosquitos] = result;
    auto [s1, e1, i1, r1] = humans;
    auto [s2, i2, r2] = mosquitos;

    std::cout << "Humans: " << s1 << " " << e1 << " " << i1 << " " << r1
              << std::endl;
    std::cout << "Mosquitos: " << s2 << " " << i2 << " " << r2 << std::endl;
  }
} // namespace simulator
