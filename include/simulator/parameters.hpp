#pragma once

#include <cstddef>
#include <string_view>

namespace simulator {

  struct Parameters {
    std::size_t runs;
    std::size_t cycles;
    double human_infection_rate;
    std::size_t human_initial_susceptible;
    std::size_t human_initial_exposed;
    std::size_t human_initial_infected;
    std::size_t human_initial_recovered;
    std::size_t human_transition_period_exposed;
    std::size_t human_transition_period_infected;
    std::size_t human_transition_period_recovered;
    double mosquito_infection_rate;
    std::size_t mosquito_initial_susceptible;
    std::size_t mosquito_initial_infected;
    std::size_t mosquito_initial_recovered;
    std::size_t mosquito_transition_period_infected;
    std::size_t mosquito_transition_period_recovered;

    static auto from_json(const std::string_view) -> Parameters;
  };

} // namespace simulator
