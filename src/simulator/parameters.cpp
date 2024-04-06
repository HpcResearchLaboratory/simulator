#include <simulator/parameters.hpp>
#include <simulator/util/random.hpp>

#include <string_view>

#include <nlohmann/json.hpp>

namespace simulator {
  using json = nlohmann::json;

  auto Parameters::from_json(const std::string_view data) -> Parameters {
    const json json_data = json::parse(data);

    const auto& runs = json_data["runs"].get<std::size_t>();
    const auto& cycles = json_data["cycles"].get<std::size_t>();

    const auto& human_infection_rate =
      json_data["human_infection_rate"].get<std::pair<double, double>>();

    const auto& human_initial_susceptible =
      json_data["human_initial_susceptible"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& human_initial_exposed =
      json_data["human_initial_exposed"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& human_initial_infected =
      json_data["human_initial_infected"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& human_initial_recovered =
      json_data["human_initial_recovered"]
        .get<std::pair<std::size_t, std::size_t>>();

    const auto& human_transition_period_exposed =
      json_data["human_transition_period_exposed"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& human_transition_period_infected =
      json_data["human_transition_period_infected"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& human_transition_period_recovered =
      json_data["human_transition_period_recovered"]
        .get<std::pair<std::size_t, std::size_t>>();

    const auto& mosquito_infection_rate =
      json_data["mosquito_infection_rate"].get<std::pair<double, double>>();

    const auto& mosquito_initial_susceptible =
      json_data["mosquito_initial_susceptible"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& mosquito_initial_infected =
      json_data["mosquito_initial_infected"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& mosquito_initial_recovered =
      json_data["mosquito_initial_recovered"]
        .get<std::pair<std::size_t, std::size_t>>();

    const auto& mosquito_transition_period_infected =
      json_data["mosquito_transition_period_infected"]
        .get<std::pair<std::size_t, std::size_t>>();
    const auto& mosquito_transition_period_recovered =
      json_data["mosquito_transition_period_recovered"]
        .get<std::pair<std::size_t, std::size_t>>();

    return { runs,
             cycles,
             util::make_random_generator_in_range(
               std::get<0>(human_infection_rate),
               std::get<1>(human_infection_rate))(),
             util::make_random_generator_in_range(
               std::get<0>(human_initial_susceptible),
               std::get<1>(human_initial_susceptible))(),
             util::make_random_generator_in_range(
               std::get<0>(human_initial_exposed),
               std::get<1>(human_initial_exposed))(),
             util::make_random_generator_in_range(
               std::get<0>(human_initial_infected),
               std::get<1>(human_initial_infected))(),
             util::make_random_generator_in_range(
               std::get<0>(human_initial_recovered),
               std::get<1>(human_initial_recovered))(),
             util::make_random_generator_in_range(
               std::get<0>(human_transition_period_exposed),
               std::get<1>(human_transition_period_exposed))(),
             util::make_random_generator_in_range(
               std::get<0>(human_transition_period_infected),
               std::get<1>(human_transition_period_infected))(),
             util::make_random_generator_in_range(
               std::get<0>(human_transition_period_recovered),
               std::get<1>(human_transition_period_recovered))(),
             util::make_random_generator_in_range(
               std::get<0>(mosquito_infection_rate),
               std::get<1>(mosquito_infection_rate))(),
             util::make_random_generator_in_range(
               std::get<0>(mosquito_initial_susceptible),
               std::get<1>(mosquito_initial_susceptible))(),
             util::make_random_generator_in_range(
               std::get<0>(mosquito_initial_infected),
               std::get<1>(mosquito_initial_infected))(),
             util::make_random_generator_in_range(
               std::get<0>(mosquito_initial_recovered),
               std::get<1>(mosquito_initial_recovered))(),
             util::make_random_generator_in_range(
               std::get<0>(mosquito_transition_period_infected),
               std::get<1>(mosquito_transition_period_infected))(),
             util::make_random_generator_in_range(
               std::get<0>(mosquito_transition_period_recovered),
               std::get<1>(mosquito_transition_period_recovered))() };
  }
} // namespace simulator
