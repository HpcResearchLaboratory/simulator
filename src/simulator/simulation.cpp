#include <simulator/agent/human.hpp>
#include <simulator/agent/mosquito.hpp>
#include <simulator/environment.hpp>
#include <simulator/simulation.hpp>
#include <simulator/state.hpp>
#include <simulator/util/functional.hpp>
#include <simulator/util/random.hpp>

#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <execution>
#include <memory>
#include <tuple>
#include <utility>

#include <stdexec/execution.hpp>

namespace simulator {
  Simulation::Simulation(std::shared_ptr<const Environment> environment,
                         std::unique_ptr<const Parameters> parameters,
                         nvexec::multi_gpu_stream_scheduler&& gpu,
                         exec::static_thread_pool::scheduler&& cpu) noexcept
    : environment(std::move(environment)), parameters(std::move(parameters)),
      gpu(std::move(gpu)), cpu(std::move(cpu)),
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
          std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>>(
          std::vector<
            std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>(
            this->environment->size,
            std::make_pair(
              std::vector<std::int64_t>(this->humans->size(), -1),
              std::vector<std::int64_t>(this->mosquitos->size(), -1))))) {}

  auto Simulation::run() noexcept -> void {
    const auto cycles = parameters->cycles;

    auto start = std::chrono::high_resolution_clock::now();
    insertion();
    std::cout << "Insertion: "
              << std::chrono::duration_cast<std::chrono::milliseconds>(
                   std::chrono::high_resolution_clock::now() - start)
                   .count()
              << "ms" << std::endl;
    for (std::size_t i = 0; i < cycles; i++) {
      auto start = std::chrono::high_resolution_clock::now();
      movement();
      std::cout << "Movement: "
                << std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::high_resolution_clock::now() - start)
                     .count()
                << "ms" << std::endl;
      start = std::chrono::high_resolution_clock::now();
      contact();
      std::cout << "Contact: "
                << std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::high_resolution_clock::now() - start)
                     .count()
                << "ms" << std::endl;
      start = std::chrono::high_resolution_clock::now();
      transition();
      std::cout << "Transition: "
                << std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::high_resolution_clock::now() - start)
                     .count()
                << "ms" << std::endl;
      start = std::chrono::high_resolution_clock::now();
      output();
      std::cout << "Output: "
                << std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::high_resolution_clock::now() - start)
                     .count()
                << "ms" << std::endl;
    }
  }

  auto Simulation::insertion() noexcept -> void {
    auto random_human_position = util::make_gpu_rng(
      0UL, environment->size - 1,
      std::chrono::high_resolution_clock::now().time_since_epoch().count());

    const auto insert_susceptible_human =
      [random_human_position, humans = humans.get(),
       agents_in_position = agents_in_position.get()](auto i) mutable noexcept {
        const auto position = random_human_position(i);
        (*humans)[i] =
          agent::Human { agent::Human::State::Susceptible, i, position, 0 };
        std::get<0>((*agents_in_position)[position])[i] = i;
      };

    const auto insert_infected_human =
      [random_human_position, humans = humans.get(),
       agents_in_position = agents_in_position.get(),
       inital_index =
         parameters->human_initial_infected](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*humans)[idx] = agent::Human { agent::Human::State::Infected, idx,
                                        random_human_position(idx), 0 };
        std::get<0>((*agents_in_position)[(*humans)[idx].position])[idx] = idx;
      };

    const auto insert_exposed_human =
      [random_human_position, humans = humans.get(),
       agents_in_position = agents_in_position.get(),
       inital_index =
         parameters->human_initial_susceptible](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*humans)[idx] = agent::Human { agent::Human::State::Exposed, idx,
                                        random_human_position(idx), 0 };
        std::get<0>((*agents_in_position)[(*humans)[idx].position])[idx] = idx;
      };

    const auto insert_recovered_human =
      [random_human_position, humans = humans.get(),
       agents_in_position = agents_in_position.get(),
       inital_index = parameters->human_initial_infected +
         parameters->human_initial_exposed](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*humans)[idx] = agent::Human { agent::Human::State::Recovered, idx,
                                        random_human_position(idx), 0 };
        std::get<0>((*agents_in_position)[(*humans)[idx].position])[idx] = idx;
      };

    auto random_mosquito_position = util::make_gpu_rng(
      0UL, environment->size - 1,
      std::chrono::high_resolution_clock::now().time_since_epoch().count());

    const auto insert_susceptible_mosquito =
      [random_mosquito_position, mosquitos = this->mosquitos.get(),
       agents_in_position = agents_in_position.get()](auto i) mutable noexcept {
        (*mosquitos)[i] = agent::Mosquito { agent::Mosquito::State::Susceptible,
                                            i, random_mosquito_position(i), 0 };
        std::get<1>((*agents_in_position)[(*mosquitos)[i].position])[i] = i;
      };

    const auto insert_infected_mosquito =
      [random_mosquito_position, mosquitos = this->mosquitos.get(),
       agents_in_position = agents_in_position.get(),
       inital_index =
         parameters->mosquito_initial_susceptible](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*mosquitos)[idx] =
          agent::Mosquito { agent::Mosquito::State::Infected, idx,
                            random_mosquito_position(idx), 0 };
        std::get<1>((*agents_in_position)[(*mosquitos)[idx].position])[idx] =
          idx;
      };

    const auto insert_recovered_mosquito =
      [random_mosquito_position, mosquitos = this->mosquitos.get(),
       agents_in_position = agents_in_position.get(),
       inital_index = parameters->mosquito_initial_susceptible +
         parameters->mosquito_initial_infected](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*mosquitos)[idx] =
          agent::Mosquito { agent::Mosquito::State::Recovered, idx,
                            random_mosquito_position(idx), 0 };
        std::get<1>((*agents_in_position)[(*mosquitos)[idx].position])[idx] =
          idx;
      };

    const auto work = stdexec::when_all(
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(parameters->human_initial_susceptible,
                               insert_susceptible_human)),
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(parameters->human_initial_exposed,
                               insert_exposed_human)),
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(parameters->human_initial_infected,
                               insert_infected_human)),
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(parameters->human_initial_recovered,
                               insert_recovered_human)),
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(parameters->mosquito_initial_susceptible,
                               insert_susceptible_mosquito)),
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(parameters->mosquito_initial_infected,
                               insert_infected_mosquito)),
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(parameters->mosquito_initial_recovered,
                               insert_recovered_mosquito)));

    stdexec::sync_wait(std::move(work));
  }

  auto Simulation::movement() noexcept -> void {
    auto random_human_position = util::make_gpu_rng(
      0UL, environment->size - 1,
      std::chrono::high_resolution_clock::now().time_since_epoch().count());

    const auto human_movement =
      [random_human_position, environment = environment.get(),
       humans = humans.get(),
       agents_in_position = agents_in_position.get()](auto i) mutable noexcept {
        auto& position = (*humans)[i].position;
        const auto& edges = environment->edges[position];
        std::get<0>((*agents_in_position)[position])[i] = -1;
        position = edges[random_human_position(i) % edges.size()];
        std::get<0>((*agents_in_position)[position])[i] = i;
      };

    auto random_mosquito_position = util::make_gpu_rng(
      0UL, environment->size - 1,
      std::chrono::high_resolution_clock::now().time_since_epoch().count());

    const auto mosquito_movement =
      [random_mosquito_position, environment = environment.get(),
       mosquitos = mosquitos.get(),
       agents_in_position = agents_in_position.get()](auto i) mutable noexcept {
        auto& position = (*mosquitos)[i].position;
        std::get<1>((*agents_in_position)[position])[i] = -1;
        const auto& edges = environment->edges[position];
        position = edges[random_mosquito_position(i) % edges.size()];
        std::get<1>((*agents_in_position)[position])[i] = i;
      };

    const auto work = stdexec::transfer_when_all(
      gpu, stdexec::just() | stdexec::bulk(humans->size(), human_movement),
      stdexec::just() | stdexec::bulk(mosquitos->size(), mosquito_movement));

    stdexec::sync_wait(std::move(work));
  }

  auto Simulation::contact() noexcept -> void {
    auto agents_set = std::make_unique<std::vector<
      std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>>(
      environment->size);

    auto generate_agents_in_position =
      [agents_set = agents_set.get(),
       agents_in_position = agents_in_position.get()](auto i) mutable noexcept {
        std::copy_if(std::execution::seq,
                     std::begin(std::get<0>((*agents_in_position)[i])),
                     std::end(std::get<0>((*agents_in_position)[i])),
                     std::back_inserter(std::get<0>((*agents_set)[i])),
                     [](auto a) { return a != -1; });

        std::copy_if(std::execution::seq,
                     std::begin(std::get<1>((*agents_in_position)[i])),
                     std::end(std::get<1>((*agents_in_position)[i])),
                     std::back_inserter(std::get<1>((*agents_set)[i])),
                     [](auto a) { return a != -1; });
      };

    auto random_probability = util::make_gpu_rng(
      0.0, 1.0,
      std::chrono::high_resolution_clock::now().time_since_epoch().count());

    const auto human_mosquito_contact =
      [random_probability, environment = environment.get(),
       parameters = parameters.get(), humans = humans.get(),
       mosquitos = mosquitos.get(),
       agents_in_position = agents_set.get()](auto i) mutable noexcept {
        auto& humans_in_pos = std::get<0>((*agents_in_position)[i]);
        auto& mosquitos_in_pos = std::get<1>((*agents_in_position)[i]);
        for (const auto& human_id : humans_in_pos) {
          for (const auto& mosquito_id : mosquitos_in_pos) {
            auto& human = (*humans)[human_id];
            auto& mosquito = (*mosquitos)[mosquito_id];

            if (human.state == agent::Human::State::Susceptible &&
                mosquito.state == agent::Mosquito::State::Infected &&
                random_probability(human_id) <
                  parameters->human_infection_rate) {
              human.state = agent::Human::State::Exposed;
            } else if (human.state == agent::Human::State::Infected &&
                       mosquito.state == agent::Mosquito::State::Susceptible &&
                       random_probability(mosquito_id) <
                         parameters->mosquito_infection_rate) {
              mosquito.state = agent::Mosquito::State::Infected;
            }
          }
        }
      };

    const auto mosquito_mosquito_contact =
      [random_probability, mosquitos = mosquitos.get(),
       parameters = parameters.get(),
       agents_in_position = agents_set.get()](auto i) mutable noexcept {
        auto& mosquitos_in_pos = std::get<1>((*agents_in_position)[i]);
        for (const auto& mosquito_id : mosquitos_in_pos) {
          for (const auto& mosquito_id2 : mosquitos_in_pos) {
            if (mosquito_id != mosquito_id2) {
              auto& mosquito = (*mosquitos)[mosquito_id];
              auto& mosquito2 = (*mosquitos)[mosquito_id2];
              if (mosquito.state == agent::Mosquito::State::Infected &&
                  mosquito2.state == agent::Mosquito::State::Susceptible &&
                  random_probability(mosquito.id) <
                    parameters->mosquito_infection_rate) {
                mosquito2.state = agent::Mosquito::State::Infected;
              } else if (mosquito.state ==
                           agent::Mosquito::State::Susceptible &&
                         mosquito2.state == agent::Mosquito::State::Infected &&
                         random_probability(mosquito2.id) <
                           parameters->mosquito_infection_rate) {
                mosquito.state = agent::Mosquito::State::Infected;
              }
            }
          }
        }
      };

    const auto work1 = stdexec::just() |
      exec::on(cpu,
               stdexec::bulk(environment->size, generate_agents_in_position));

    const auto work2 = stdexec::when_all(
      stdexec::just() |
        exec::on(gpu, stdexec::bulk(environment->size, human_mosquito_contact)),
      stdexec::just() |
        exec::on(gpu,
                 stdexec::bulk(environment->size, mosquito_mosquito_contact)));

    stdexec::sync_wait(std::move(work1));
    stdexec::sync_wait(std::move(work2));
  }

  auto Simulation::transition() noexcept -> void {
    const auto human_transition = [=, humans = humans.get(),
                                   parameters =
                                     parameters.get()](auto i) noexcept {
      auto& human = (*humans)[i];

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
          if (human.counter >= parameters->human_transition_period_recovered) {
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
    };

    const auto mosquito_transition = [=, mosquitos = mosquitos.get(),
                                      parameters =
                                        parameters.get()](auto i) noexcept {
      auto& mosquito = (*mosquitos)[i];

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
    };

    const auto work = stdexec::when_all(
      stdexec::just() |
        exec::on(gpu, stdexec::bulk(humans->size(), human_transition)),
      stdexec::just() |
        exec::on(gpu, stdexec::bulk(mosquitos->size(), mosquito_transition)));

    stdexec::sync_wait(std::move(work));
  }

  auto Simulation::output() noexcept -> State {
    auto humans_in_states = std::transform_reduce(
      std::execution::par_unseq, std::begin(*humans), std::end(*humans),
      std::make_tuple<std::size_t, std::size_t, std::size_t, std::size_t>(
        0L, 0L, 0L, 0L),
      [](const auto& seir1, const auto& seir2) {
        return std::make_tuple<std::size_t, std::size_t, std::size_t,
                               std::size_t>(
          std::get<0>(seir1) + std::get<0>(seir2),
          std::get<1>(seir1) + std::get<1>(seir2),
          std::get<2>(seir1) + std::get<2>(seir2),
          std::get<3>(seir1) + std::get<3>(seir2));
      },
      [](const auto& human) {
        return std::make_tuple<std::size_t, std::size_t, std::size_t,
                               std::size_t>(
          human.state == agent::Human::State::Susceptible ? 1 : 0,
          human.state == agent::Human::State::Exposed ? 1 : 0,
          human.state == agent::Human::State::Infected ? 1 : 0,
          human.state == agent::Human::State::Recovered ? 1 : 0);
      });

    auto mosquitos_in_states = std::transform_reduce(
      std::execution::par_unseq, std::begin(*mosquitos), std::end(*mosquitos),
      std::make_tuple<std::size_t, std::size_t, std::size_t>(0L, 0L, 0L),
      [](const auto& sir1, const auto& sir2) {
        return std::make_tuple<std::size_t, std::size_t, std::size_t>(
          std::get<0>(sir1) + std::get<0>(sir2),
          std::get<1>(sir1) + std::get<1>(sir2),
          std::get<2>(sir1) + std::get<2>(sir2));
      },
      [](const auto& mosquito) {
        return std::make_tuple<std::size_t, std::size_t, std::size_t>(
          mosquito.state == agent::Mosquito::State::Susceptible ? 1 : 0,
          mosquito.state == agent::Mosquito::State::Infected ? 1 : 0,
          mosquito.state == agent::Mosquito::State::Recovered ? 1 : 0);
      });

    return State { { ++iteration, parameters->cycles },
                   humans_in_states,
                   mosquitos_in_states };
  }

} // namespace simulator
