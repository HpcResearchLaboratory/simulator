#include <simulator/agent/human.hpp>
#include <simulator/agent/mosquito.hpp>
#include <simulator/environment.hpp>
#include <simulator/result.hpp>
#include <simulator/simulation.hpp>
#include <simulator/util/functional.hpp>
#include <simulator/util/random.hpp>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <execution>
#include <memory>
#include <thread>
#include <utility>

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
          std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>>(
          std::vector<
            std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>(
            this->environment->size,
            std::make_pair(
              std::vector<std::int64_t>(this->humans->size(), -1),
              std::vector<std::int64_t>(this->mosquitos->size(), -1))))),
      gpu_ctx {}, cpu_ctx { std::thread::hardware_concurrency() },
      gpu(gpu_ctx.get_scheduler()), cpu(cpu_ctx.get_scheduler()) {}

  auto Simulation::run() noexcept -> void {
    const auto cycles = parameters->cycles;

    insertion();
    for (std::size_t i = 0; i < cycles; i++) {
      auto start = std::chrono::high_resolution_clock::now();
      std::cout << "Cycle: " << i << std::endl;
      movement();
      std::cout << "Movement: "
                << std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::high_resolution_clock::now() - start)
                     .count()
                << "ms" << std::endl;
      contact();
      std::cout << "Contact: "
                << std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::high_resolution_clock::now() - start)
                     .count()
                << "ms" << std::endl;
      transition();
      std::cout << "Transition: "
                << std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::high_resolution_clock::now() - start)
                     .count()
                << "ms" << std::endl
                << std::endl;
    }
  }

  auto Simulation::insertion() noexcept  {
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

    return stdexec::when_all(
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
  };

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
  }
} // namespace simulator
