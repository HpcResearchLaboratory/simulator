#include <simulator/environment.hpp>
#include <simulator/mosquito/mosquito.hpp>
#include <simulator/mosquito/mosquitos.hpp>
#include <simulator/parameters.hpp>

#include <string_view>

namespace simulator {
  Mosquitos::Mosquitos(const Parameters& parameters,
                       const Environment& environment)
    : parameters(parameters), environment(environment) {

    const auto mosquitos_distribution =
      *parameters.table.at_path("mosquitos.initialization.distribution")
         .as<toml::array>();

    for (const auto& m : mosquitos_distribution) {
      const auto& mosquito_entry = *m.as_table();
      const auto gender = static_cast<Mosquito::Gender>(
        mosquito_entry["gender"].value_or("m")[0]);
      const auto phase =
        static_cast<Mosquito::Phase>(mosquito_entry["phase"].value_or("a")[0]);
      const auto state =
        static_cast<Mosquito::State>(mosquito_entry["state"].value_or("s")[0]);
      const auto serotype =
        static_cast<Mosquito::Serotype>(mosquito_entry["serotype"].value_or(1));

      const auto quantity = util::random_value_in_range<std::int64_t>(
        mosquito_entry.at_path("quantity").as_table());

      const auto random_probability =
        util::make_random_generator_in_range(0.0, 1.0);

      std::int64_t x = 0;
      std::int64_t y = 0;
      std::int64_t block = 0;
      std::int64_t group = 0;
      std::int64_t age = 0;

      for (auto i = 0; i < quantity; i++) {
        if (phase == Mosquito::Phase::egg) {
          auto focus_id = util::random_value_between(
            0ul, environment.strategic_points.size() - 1);
          auto position_index = environment.strategic_points[focus_id];
          auto position = environment.positions[position_index];

          x = position.x;
          y = position.y;
          block = position.block;
          group = position.group;
          age = util::random_value_in_range<std::int64_t>(
            parameters.table["mosquitos"]["transition"]["ages"]["e"]
              .as_table());

        } else {
          if (random_probability() <=
              util::random_value_in_range<double>(
                parameters.table
                  .at_path(
                    "mosquitos.initialization.random_distribution_probability")
                  .as_table())) {
            auto position = util::random_value_between(
              0ul, environment.strategic_points.size() / 2 - 1);

            block = environment.strategic_points[2 * position];
            group = environment.strategic_points[2 * position + 1];
          } else {
            auto position = util::random_value_between(
              environment.position_region_indexes[1],
              environment.position_region_indexes[2]);
            block = environment.positions[position].block;
            group = environment.positions[position].group;
          }

          auto position = util::random_value_between<std::int64_t>(
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

          age = util::random_value_in_range<std::int64_t>(
            parameters
              .table["mosquitos"]["transition"]["ages"]
                    [std::string(1, static_cast<char>(phase))]
              .as_table());
        }

        mosquitos.emplace_back(Mosquito {
          .id = i,
          .gender = gender,
          .phase = phase,
          .age = age,
          .state = state,
          .serotype = serotype,
          .is_dead = false,
          .counter = 0,
          .should_lay_eggs = false,
          .should_search_for_mate = false,
          .should_search_for_strategic_point = false,
          .should_do_long_distance_flight = false,
          .gestation_count = 0,
          .cycles_between_lay = 0,
          .is_fed = false,
          .mating_state = std::nullopt,
          .lay_count = 0,
          .x = x,
          .y = y,
          .block = block,
          .group = group,

        });
      }
    }
  }

} // namespace simulator
