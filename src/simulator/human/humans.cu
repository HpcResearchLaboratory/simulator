#include <simulator/environment.hpp>
#include <simulator/human/human.hpp>
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
      const auto gender =
        static_cast<Human::Gender>(human_entry["gender"].value_or("m")[0]);
      const auto age_group =
        static_cast<Human::AgeGroup>(human_entry["age_group"].value_or("a")[0]);
      const auto state =
        static_cast<Human::State>(human_entry["state"].value_or("s")[0]);
      auto serotype =
        static_cast<Human::Serotype>(human_entry["serotype"].value_or(1));
      const auto quantity = util::random_value_in_range<std::int64_t>(
        human_entry.at_path("quantity").as_table());

      std::int64_t x = 0;
      std::int64_t y = 0;
      std::int64_t block = 0;
      std::int64_t group = 0;
      std::int64_t path = 0;
      std::int64_t position = 0;

      const auto random_probability =
        util::make_random_generator_in_range(0.0, 1.0);
      for (auto i = 0; i < quantity; i++) {
        if (random_probability() <=
            util::random_value_in_range<double>(
              parameters.table
                .at_path(
                  "humans.initialization.random_distribution_probability")
                .as_table())) {
          movement_type = Human::MovementType::random;

          // NOTE: 50% change of spawning in a urban or rural region
          position = random_probability() <= 0.5
            ? util::random_value_between<std::int64_t>(
                environment.position_region_indexes[0],
                environment.position_region_indexes[1])
            : util::random_value_between(
                environment.position_region_indexes[2],
                environment.position_region_indexes[3]);

          x = environment.positions[position].x;
          y = environment.positions[position].y;
          block = environment.positions[position].block;
          group = environment.positions[position].group;
        } else {
          // NOTE: A random path is selected
          path = util::random_value_between<std::int64_t>(
            environment.path_age_groups_indexes.front(),
            environment.path_age_groups_indexes.back());

          group = environment.routes[environment.routes_indexes[path]];

          block = environment.routes[environment.routes_indexes[path] + 1];

          position = util::random_value_between<std::int64_t>(
            0,
            environment
                .positions_indexes[environment.blocks_indexes[2 * block] +
                                   group + 1] -
              environment
                .positions_indexes[environment.blocks_indexes[2 * block] +
                                   group]);

          x = environment
                .positions[environment.positions_indexes
                             [environment.blocks_indexes[2 * block] + group] +
                           position]
                .x;
          y = environment
                .positions[environment.positions_indexes
                             [environment.blocks_indexes[2 * block] + group] +
                           position]
                .y;
        }

        auto assymptomatic =
          (state == Human::State::recovered &&
           random_probability() <=
             util::random_value_in_range<double>(
               parameters.table
                 .at_path("humans.initialization.asymptomatic_probability")
                 .as_table()));

        if ((state == Human::State::infectious ||
             state == Human::State::recovered) &&
            random_probability() <=
              util::random_value_in_range<double>(
                parameters.table
                  .at_path(
                    "humans.initialization.predominant_serotype_probability")
                  .as_table())) {

          serotype = static_cast<Human::Serotype>(
            parameters.table
              .at_path("humans.initialization.predominant_serotype")
              .as_integer()
              ->value_or(1));
        } else {
          serotype =
            static_cast<Human::Serotype>(util::random_value_between(1, 4));
        }

        humans.emplace_back(Human { .id = i,
                                    .route = 0ll,
                                    .path = path,
                                    .has_moved_this_cycle = false,
                                    .movement_count = 0ll,
                                    .movement_type = movement_type,
                                    .repast_count = 0ll,
                                    .gender = gender,
                                    .age_group = age_group,
                                    .state = state,
                                    .serotype = serotype,
                                    .serotypes_contracted = { serotype },
                                    .is_assymptomatic = assymptomatic,
                                    .state_transition_count = 0ll,
                                    .vaccination_count = 0ll,
                                    .x = x,
                                    .y = y,
                                    .block = block,
                                    .group = group });
      }
    }
  }
} // namespace simulator
