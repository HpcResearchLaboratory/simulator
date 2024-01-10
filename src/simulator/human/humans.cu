#include <simulator/environment.hpp>
#include <simulator/human/humans.hpp>
#include <simulator/parameters.hpp>
#include <simulator/util/random.hpp>

namespace simulator {
  Humans::Humans(const Parameters& parameters, const Environment& environment)
    : parameters(parameters), environment(environment) {

    const auto humans_distribution =
      *parameters.table.at_path("humans.initialization.distribution")
         .as<toml::array>();

    for (const auto& h : humans_distribution) {
      const auto human_entry = *h.as_table();
      auto movement_type = static_cast<Human::MovementType>(
        human_entry["movement_type"].value_or("r")[0]);
      auto gender =
        static_cast<Human::Gender>(human_entry["gender"].value_or("m")[0]);
      auto age_group =
        static_cast<Human::AgeGroup>(human_entry["age_group"].value_or("a")[0]);
      auto state =
        static_cast<Human::State>(human_entry["state"].value_or("s")[0]);
      auto serotype =
        static_cast<Human::Serotype>(human_entry["serotype"].value_or(1));
      auto quantity = util::random_value_in_range<std::int64_t>(
        human_entry.at_path("quantity").as_table());

      auto random_probability = util::make_random_generator_in_range(0.0, 1.0);
      for (auto i = 0; i < quantity; i++) {
        if (random_probability() <=
            util::random_value_in_range<double>(
              parameters.table
                .at_path(
                  "humans.initialization.random_distribution_probability")
                .as_table())) {
          movement_type = Human::MovementType::random;
        }
      }
    }
  }
} // namespace simulator
