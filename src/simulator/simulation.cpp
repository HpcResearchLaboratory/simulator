#include <simulator/environment.hpp>
#include <simulator/human.hpp>
#include <simulator/mosquito.hpp>
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
                         std::shared_ptr<const Parameters> parameters,
                         std::size_t threads) noexcept
    : environment(std::move(environment)), parameters(std::move(parameters)),
      cpu { static_cast<uint32_t>(threads) }, gpu {},
      humans(std::make_unique<std::vector<Human>>(
        this->parameters->human_initial_susceptible +
        this->parameters->human_initial_exposed +
        this->parameters->human_initial_infected +
        this->parameters->human_initial_recovered)),
      mosquitos(std::make_unique<std::vector<Mosquito>>(
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
      states(std::make_unique<std::vector<State>>()) {}

  auto Simulation::prepare() noexcept -> void {
    insertion();
  }

  auto Simulation::iterate() noexcept -> std::optional<const State* const> {
    if (iteration >= parameters->cycles) {
      return std::nullopt;
    }

    movement();
    contact();
    transition();
    auto& state = output();

    // TFW no std::optional in C++ :(
    return &state;
  }

  auto Simulation::run() noexcept -> void {
    const auto cycles = parameters->cycles;

    insertion();
    for (std::size_t i = 0; i < cycles; i++) {
      movement();
      contact();
      transition();
      /*auto _ = output();*/
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
        (*humans)[i] = Human { Human::State::Susceptible, i, position, 0 };
        std::get<0>((*agents_in_position)[position])[i] = i;
      };

    const auto insert_infected_human =
      [random_human_position, humans = humans.get(),
       agents_in_position = agents_in_position.get(),
       inital_index =
         parameters->human_initial_infected](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*humans)[idx] =
          Human { Human::State::Infected, idx, random_human_position(idx), 0 };
        std::get<0>((*agents_in_position)[(*humans)[idx].position])[idx] = idx;
      };

    const auto insert_exposed_human =
      [random_human_position, humans = humans.get(),
       agents_in_position = agents_in_position.get(),
       inital_index =
         parameters->human_initial_susceptible](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*humans)[idx] =
          Human { Human::State::Exposed, idx, random_human_position(idx), 0 };
        std::get<0>((*agents_in_position)[(*humans)[idx].position])[idx] = idx;
      };

    const auto insert_recovered_human =
      [random_human_position, humans = humans.get(),
       agents_in_position = agents_in_position.get(),
       inital_index = parameters->human_initial_infected +
         parameters->human_initial_exposed](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*humans)[idx] =
          Human { Human::State::Recovered, idx, random_human_position(idx), 0 };
        std::get<0>((*agents_in_position)[(*humans)[idx].position])[idx] = idx;
      };

    auto random_mosquito_position = util::make_gpu_rng(
      0UL, environment->size - 1,
      std::chrono::high_resolution_clock::now().time_since_epoch().count());

    const auto insert_susceptible_mosquito =
      [random_mosquito_position, mosquitos = this->mosquitos.get(),
       agents_in_position = agents_in_position.get()](auto i) mutable noexcept {
        (*mosquitos)[i] = Mosquito { Mosquito::State::Susceptible, i,
                                     random_mosquito_position(i), 0 };
        std::get<1>((*agents_in_position)[(*mosquitos)[i].position])[i] = i;
      };

    const auto insert_infected_mosquito =
      [random_mosquito_position, mosquitos = this->mosquitos.get(),
       agents_in_position = agents_in_position.get(),
       inital_index =
         parameters->mosquito_initial_susceptible](auto i) mutable noexcept {
        const auto idx = inital_index + i;
        (*mosquitos)[idx] = Mosquito { Mosquito::State::Infected, idx,
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
        (*mosquitos)[idx] = Mosquito { Mosquito::State::Recovered, idx,
                                       random_mosquito_position(idx), 0 };
        std::get<1>((*agents_in_position)[(*mosquitos)[idx].position])[idx] =
          idx;
      };

#ifdef SYNC
    auto range =
      std::vector<std::size_t>(parameters->human_initial_susceptible);
    std::iota(std::begin(range), std::end(range), 0UL);

    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  insert_susceptible_human);
    range = std::vector<std::size_t>(parameters->human_initial_exposed);
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  insert_exposed_human);
    range = std::vector<std::size_t>(parameters->human_initial_infected);
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  insert_infected_human);
    range = std::vector<std::size_t>(parameters->human_initial_recovered);
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  insert_recovered_human);
    range = std::vector<std::size_t>(parameters->mosquito_initial_susceptible);
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  insert_susceptible_mosquito);
    range = std::vector<std::size_t>(parameters->mosquito_initial_infected);
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  insert_infected_mosquito);
    range = std::vector<std::size_t>(parameters->mosquito_initial_recovered);
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  insert_recovered_mosquito);
#else
    const auto work = stdexec::when_all(
      stdexec::just() |
        exec::on(
  #ifdef INSERTION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(parameters->human_initial_susceptible,
                        insert_susceptible_human)),
      stdexec::just() |
        exec::on(
  #ifdef INSERTION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(parameters->human_initial_exposed,
                        insert_exposed_human)),
      stdexec::just() |
        exec::on(
  #ifdef INSERTION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(parameters->human_initial_infected,
                        insert_infected_human)),
      stdexec::just() |
        exec::on(
  #ifdef INSERTION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(parameters->human_initial_recovered,
                        insert_recovered_human)),
      stdexec::just() |
        exec::on(
  #ifdef INSERTION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(parameters->mosquito_initial_susceptible,
                        insert_susceptible_mosquito)),
      stdexec::just() |
        exec::on(
  #ifdef INSERTION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(parameters->mosquito_initial_infected,
                        insert_infected_mosquito)),
      stdexec::just() |
        exec::on(
  #ifdef INSERTION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(parameters->mosquito_initial_recovered,
                        insert_recovered_mosquito)));

    stdexec::sync_wait(std::move(work));
#endif
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

#ifdef SYNC
    auto range = std::vector<std::size_t>(humans->size());
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  human_movement);
    range = std::vector<std::size_t>(mosquitos->size());
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  mosquito_movement);
#else
    const auto work = stdexec::transfer_when_all(
  #ifdef MOVEMENT_CPU
      cpu.get_scheduler()
  #else
      gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
        ,
      stdexec::just() | stdexec::bulk(humans->size(), human_movement),
      stdexec::just() | stdexec::bulk(mosquitos->size(), mosquito_movement));

    stdexec::sync_wait(std::move(work));
#endif
  }

  auto Simulation::contact() noexcept -> void {
    auto agents_set = std::make_unique<std::vector<
      std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>>(
      environment->size);

    auto generate_agents_in_position =
      [agents_set = agents_set.get(),
       agents_in_position = agents_in_position.get()](auto i) mutable {
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

            if (human.state == Human::State::Susceptible &&
                mosquito.state == Mosquito::State::Infected &&
                random_probability(human_id) <
                  parameters->human_infection_rate) {
              human.state = Human::State::Exposed;
            } else if (human.state == Human::State::Infected &&
                       mosquito.state == Mosquito::State::Susceptible &&
                       random_probability(mosquito_id) <
                         parameters->mosquito_infection_rate) {
              mosquito.state = Mosquito::State::Infected;
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
              if (mosquito.state == Mosquito::State::Infected &&
                  mosquito2.state == Mosquito::State::Susceptible &&
                  random_probability(mosquito.id) <
                    parameters->mosquito_infection_rate) {
                mosquito2.state = Mosquito::State::Infected;
              } else if (mosquito.state == Mosquito::State::Susceptible &&
                         mosquito2.state == Mosquito::State::Infected &&
                         random_probability(mosquito2.id) <
                           parameters->mosquito_infection_rate) {
                mosquito.state = Mosquito::State::Infected;
              }
            }
          }
        }
      };

    const auto work1 = stdexec::just() |
      exec::on(cpu.get_scheduler(),
               stdexec::bulk(environment->size, generate_agents_in_position));

    stdexec::sync_wait(std::move(work1));

#ifdef SYNC
    auto range = std::vector<std::size_t>(environment->size);
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  human_mosquito_contact);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  mosquito_mosquito_contact);
#else
    const auto work2 = stdexec::when_all(
      stdexec::just() |
        exec::on(
  #ifdef CONTACT_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(environment->size, human_mosquito_contact)),
      stdexec::just() |
        exec::on(
  #ifdef CONTACT_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(environment->size, mosquito_mosquito_contact)));

    stdexec::sync_wait(std::move(work2));
#endif
  }

  auto Simulation::transition() noexcept -> void {
    const auto human_transition = [=, humans = humans.get(),
                                   parameters =
                                     parameters.get()](auto i) noexcept {
      auto& human = (*humans)[i];

      switch (human.state) {
        case Human::State::Exposed:
          if (human.counter >= parameters->human_transition_period_exposed) {
            human.state = Human::State::Infected;
            human.counter = 0;
          } else {
            human.counter++;
          }
          break;
        case Human::State::Infected:
          if (human.counter >= parameters->human_transition_period_infected) {
            human.state = Human::State::Recovered;
            human.counter = 0;
          } else {
            human.counter++;
          }
          break;
        case Human::State::Recovered:
          if (human.counter >= parameters->human_transition_period_recovered) {
            human.state = Human::State::Susceptible;
            human.counter = 0;
          } else {
            human.counter++;
          }
          break;
        case Human::State::Susceptible:
          human.counter++;
          break;
      }
    };

    const auto mosquito_transition = [=, mosquitos = mosquitos.get(),
                                      parameters =
                                        parameters.get()](auto i) noexcept {
      auto& mosquito = (*mosquitos)[i];

      switch (mosquito.state) {
        case Mosquito::State::Infected:
          if (mosquito.counter >=
              parameters->mosquito_transition_period_infected) {
            mosquito.state = Mosquito::State::Recovered;
            mosquito.counter = 0;
          } else {
            mosquito.counter++;
          }
          break;
        case Mosquito::State::Recovered:
          if (mosquito.counter >=
              parameters->mosquito_transition_period_recovered) {
            mosquito.state = Mosquito::State::Susceptible;
            mosquito.counter = 0;
          } else {
            mosquito.counter++;
          }
          break;
        case Mosquito::State::Susceptible:
          mosquito.counter++;
          break;
      }
    };

#ifdef SYNC
    auto range = std::vector<std::size_t>(humans->size());
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  human_transition);

    range = std::vector<std::size_t>(mosquitos->size());
    std::iota(std::begin(range), std::end(range), 0UL);
    std::for_each(std::execution::par_unseq, std::begin(range), std::end(range),
                  mosquito_transition);
#else
    const auto work = stdexec::when_all(
      stdexec::just() |
        exec::on(
  #ifdef TRANSITION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(humans->size(), human_transition)),
      stdexec::just() |
        exec::on(
  #ifdef TRANSITION_CPU
          cpu.get_scheduler()
  #else
          gpu.get_scheduler(nvexec::stream_priority::high)
  #endif
            ,
          stdexec::bulk(mosquitos->size(), mosquito_transition)));

    stdexec::sync_wait(std::move(work));
#endif
  }

  auto Simulation::output() noexcept -> const State& {
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
          human.state == Human::State::Susceptible ? 1 : 0,
          human.state == Human::State::Exposed ? 1 : 0,
          human.state == Human::State::Infected ? 1 : 0,
          human.state == Human::State::Recovered ? 1 : 0);
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
          mosquito.state == Mosquito::State::Susceptible ? 1 : 0,
          mosquito.state == Mosquito::State::Infected ? 1 : 0,
          mosquito.state == Mosquito::State::Recovered ? 1 : 0);
      });

    states->push_back({
      { ++iteration, parameters->cycles },
      humans_in_states,
      mosquitos_in_states,
    });

    // copy all humans to the states
    std::copy(std::begin(*humans), std::end(*humans),
              std::back_inserter(states->back().humans));
    std::copy(std::begin(*mosquitos), std::end(*mosquitos),
              std::back_inserter(states->back().mosquitos));

    return states->back();
  }

  auto Simulation::get_states() noexcept -> const std::vector<State>& {
    return *states;
  }

} // namespace simulator
