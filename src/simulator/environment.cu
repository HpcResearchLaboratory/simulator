#include <simulator/environment.hpp>

#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <vector>

#include <toml++/toml.hpp>

namespace simulator {
  namespace fs = std::filesystem;

  auto Environment::from_dir(const fs::path input_path) -> Environment {
    auto table = util::parse_toml(input_path);

    // ================================Environment===========================================
    // blocks/groups
    auto blocks_groups_count_toml =
      *table.at_path("environment.blocks.groups_count").as_array();
    std::vector<std::int64_t> blocks_groups_count;
    blocks_groups_count.reserve(blocks_groups_count_toml.size());
    std::transform(
      std::begin(blocks_groups_count_toml), std::end(blocks_groups_count_toml),
      std::back_inserter(blocks_groups_count), [](auto const& block_index) {
        return block_index.as_integer()->value_or(0);
      });

    auto blocks_indexes_toml =
      *table.at_path("environment.blocks.indexes").as_array();
    std::vector<std::int64_t> blocks_indexes;
    blocks_indexes.reserve(blocks_indexes_toml.size());
    std::transform(
      std::begin(blocks_indexes_toml), std::end(blocks_indexes_toml),
      std::back_inserter(blocks_indexes), [](auto const& block_index) {
        return block_index.as_integer()->value_or(0);
      });

    // neighbors
    auto neighbors_indexes_toml =
      *table.at_path("environment.neighbors.indexes").as_array();
    std::vector<std::int64_t> neighbors_indexes;
    neighbors_indexes.reserve(neighbors_indexes_toml.size());
    std::transform(
      std::begin(neighbors_indexes_toml), std::end(neighbors_indexes_toml),
      std::back_inserter(neighbors_indexes), [](auto const& neighbor_index) {
        return neighbor_index.as_integer()->value_or(0);
      });

    auto neighbors_array_toml =
      *table.at_path("environment.neighbors.array").as_array();
    std::vector<Neighbor> neighbors_array;
    neighbors_array.reserve(neighbors_array_toml.size() / 6);
    for (std::size_t i = 0; i < neighbors_array_toml.size(); i += 6)
      neighbors_array.push_back({
        neighbors_array_toml[i + 0].as_integer()->value_or(0),
        neighbors_array_toml[i + 1].as_integer()->value_or(0),
        neighbors_array_toml[i + 2].as_integer()->value_or(0),
        neighbors_array_toml[i + 3].as_integer()->value_or(0),
        neighbors_array_toml[i + 4].as_integer()->value_or(0),
        neighbors_array_toml[i + 5].as_integer()->value_or(0),
      });

    // positions
    auto positions_indexes_toml =
      *table.at_path("environment.positions.indexes").as_array();
    std::vector<std::int64_t> positions_indexes;
    positions_indexes.reserve(positions_indexes_toml.size());
    std::transform(
      std::begin(positions_indexes_toml), std::end(positions_indexes_toml),
      std::back_inserter(positions_indexes), [](auto const& position_index) {
        return position_index.as_integer()->value_or(0);
      });

    auto positions_array_toml =
      *table.at_path("environment.positions.array").as_array();
    std::vector<Position> positions_array;
    positions_array.reserve(positions_array_toml.size() / 4);
    for (std::size_t i = 0; i < positions_array_toml.size(); i += 4)
      positions_array.push_back({
        positions_array_toml[i + 0].as_integer()->value_or(0),
        positions_array_toml[i + 1].as_integer()->value_or(0),
        positions_array_toml[i + 2].as_integer()->value_or(0),
        positions_array_toml[i + 3].as_integer()->value_or(0),
      });

    auto position_region_indexes =
      *table.at_path("environment.positions.position_region_indexes")
         .as_array();
    std::vector<std::int64_t> position_region_indexes_array;
    position_region_indexes_array.reserve(position_region_indexes.size());
    std::transform(std::begin(position_region_indexes),
                   std::end(position_region_indexes),
                   std::back_inserter(position_region_indexes_array),
                   [](auto const& position_region_index) {
                     return position_region_index.as_integer()->value_or(0);
                   });

    // frontiers
    auto frontiers_indexes_toml =
      *table.at_path("environment.frontiers.indexes").as_array();
    std::vector<std::int64_t> frontiers_indexes;
    frontiers_indexes.reserve(frontiers_indexes_toml.size());
    std::transform(
      std::begin(frontiers_indexes_toml), std::end(frontiers_indexes_toml),
      std::back_inserter(frontiers_indexes), [](auto const& frontier_index) {
        return frontier_index.as_integer()->value_or(0);
      });

    auto frontiers_array_toml =
      *table.at_path("environment.frontiers.array").as_array();
    std::vector<Frontier> frontiers_array;
    frontiers_array.reserve(frontiers_array_toml.size() / 3);
    for (std::size_t i = 0; i < frontiers_array_toml.size(); i += 3)
      frontiers_array.push_back({
        frontiers_array_toml[i + 0].as_integer()->value_or(0),
        frontiers_array_toml[i + 1].as_integer()->value_or(0),
        frontiers_array_toml[i + 2].as_integer()->value_or(0),
      });

    // corners
    auto corners_indexes_toml =
      *table.at_path("environment.corners.indexes").as_array();
    std::vector<std::int64_t> corners_indexes;
    corners_indexes.reserve(corners_indexes_toml.size());
    std::transform(
      std::begin(corners_indexes_toml), std::end(corners_indexes_toml),
      std::back_inserter(corners_indexes), [](auto const& corner_index) {
        return corner_index.as_integer()->value_or(0);
      });

    auto corners_array_toml =
      *table.at_path("environment.corners.array").as_array();
    std::vector<Corner> corners_array;
    corners_array.reserve(corners_array_toml.size() / 3);
    for (std::size_t i = 0; i < corners_array_toml.size(); i += 3)
      corners_array.push_back({
        corners_array_toml[i + 0].as_integer()->value_or(0),
        corners_array_toml[i + 1].as_integer()->value_or(0),
        corners_array_toml[i + 2].as_integer()->value_or(0),
      });

    // corner_centers
    auto corner_center_indexes_toml =
      *table.at_path("environment.corner_centers.indexes").as_array();
    std::vector<std::int64_t> corner_center_indexes;
    corner_center_indexes.reserve(corner_center_indexes_toml.size());
    std::transform(std::begin(corner_center_indexes_toml),
                   std::end(corner_center_indexes_toml),
                   std::back_inserter(corner_center_indexes),
                   [](auto const& corner_center_index) {
                     return corner_center_index.as_integer()->value_or(0);
                   });

    auto corner_centers_array_toml =
      *table.at_path("environment.corner_centers.array").as_array();
    std::vector<Corner> corner_centers_array;
    corner_centers_array.reserve(corner_centers_array_toml.size() / 3);
    for (std::size_t i = 0; i < corner_centers_array_toml.size(); i += 3)
      corner_centers_array.push_back({
        corner_centers_array_toml[i + 0].as_integer()->value_or(0),
        corner_centers_array_toml[i + 1].as_integer()->value_or(0),
        corner_centers_array_toml[i + 2].as_integer()->value_or(0),
      });

    // ===============================Movement============================================
    // routes
    auto routes_indexes_toml =
      *table.at_path("movement.routes.indexes").as_array();
    std::vector<std::int64_t> routes_indexes;
    routes_indexes.reserve(routes_indexes_toml.size());
    std::transform(
      std::begin(routes_indexes_toml), std::end(routes_indexes_toml),
      std::back_inserter(routes_indexes), [](auto const& route_index) {
        return route_index.as_integer()->value_or(0);
      });

    auto routes_array_toml = *table.at_path("movement.routes.array").as_array();
    std::vector<std::int64_t> routes_array;
    routes_array.reserve(routes_array_toml.size());
    std::transform(std::begin(routes_array_toml), std::end(routes_array_toml),
                   std::back_inserter(routes_array), [](auto const& route) {
                     return route.as_integer()->value_or(0);
                   });

    // paths
    auto paths_indexes_toml =
      *table.at_path("movement.paths.indexes").as_array();
    std::vector<std::int64_t> paths_indexes;
    paths_indexes.reserve(paths_indexes_toml.size());
    std::transform(std::begin(paths_indexes_toml), std::end(paths_indexes_toml),
                   std::back_inserter(paths_indexes),
                   [](auto const& path_index) {
                     return path_index.as_integer()->value_or(0);
                   });

    // periods
    auto periods_indexes_toml =
      *table.at_path("movement.periods.indexes").as_array();
    std::vector<std::int64_t> periods_indexes;
    periods_indexes.reserve(periods_indexes_toml.size());
    std::transform(
      std::begin(periods_indexes_toml), std::end(periods_indexes_toml),
      std::back_inserter(periods_indexes), [](auto const& period_index) {
        return period_index.as_integer()->value_or(0);
      });

    // paths age_groups
    auto paths_age_groups_indexes_toml =
      *table.at_path("movement.paths_age_groups.indexes").as_array();
    std::vector<std::int64_t> paths_age_groups_indexes;
    paths_age_groups_indexes.reserve(paths_age_groups_indexes_toml.size());
    std::transform(std::begin(paths_age_groups_indexes_toml),
                   std::end(paths_age_groups_indexes_toml),
                   std::back_inserter(paths_age_groups_indexes),
                   [](auto const& path_age_group_index) {
                     return path_age_group_index.as_integer()->value_or(0);
                   });

    // ===============================Control============================================

    // strategic points
    auto strategic_points_indexes_toml =
      *table.at_path("control.strategic_points.indexes").as_array();
    std::vector<std::int64_t> strategic_points_indexes;
    strategic_points_indexes.reserve(strategic_points_indexes_toml.size());
    std::transform(std::begin(strategic_points_indexes_toml),
                   std::end(strategic_points_indexes_toml),
                   std::back_inserter(strategic_points_indexes),
                   [](auto const& strategic_point_index) {
                     return strategic_point_index.as_integer()->value_or(0);
                   });

    // focus points
    auto focus_points_indexes_toml =
      *table.at_path("control.focus_points.indexes").as_array();
    std::vector<std::int64_t> focus_points_indexes;
    focus_points_indexes.reserve(focus_points_indexes_toml.size());
    std::transform(std::begin(focus_points_indexes_toml),
                   std::end(focus_points_indexes_toml),
                   std::back_inserter(focus_points_indexes),
                   [](auto const& focus_point_index) {
                     return focus_point_index.as_integer()->value_or(0);
                   });

    auto focus_points_array_toml =
      *table.at_path("control.focus_points.array").as_array();
    std::vector<std::int64_t> focus_points_array;
    focus_points_array.reserve(focus_points_array_toml.size());
    std::transform(
      std::begin(focus_points_array_toml), std::end(focus_points_array_toml),
      std::back_inserter(focus_points_array), [](auto const& focus_point) {
        return focus_point.as_integer()->value_or(0);
      });

    // complement
    auto complement_toml = *table.at_path("control.complement").as_array();
    std::vector<double> complement;
    complement.reserve(complement_toml.size());
    std::transform(std::begin(complement_toml), std::end(complement_toml),
                   std::back_inserter(complement), [](auto const& complement) {
                     return complement.as_floating_point()->value_or(0.0l);
                   });

    // cases
    auto cases_toml = *table.at_path("control.cases").as_array();
    std::vector<std::int64_t> cases;
    cases.reserve(cases_toml.size());
    std::transform(
      std::begin(cases_toml), std::end(cases_toml), std::back_inserter(cases),
      [](auto const& case_) { return case_.as_integer()->value_or(0); });

    // control
    auto control_toml = *table.at_path("control.control_array").as_array();
    std::vector<Control> control;
    control.reserve(control_toml.size());
    std::transform(
      std::begin(control_toml), std::end(control_toml),
      std::back_inserter(control), [](auto const& control) {
        auto control_table = *control.as_table();
        return Control {
          .block = control_table.at_path("block").as_integer()->value_or(0),
          .cycle = control_table.at_path("cycle").as_integer()->value_or(0),
          .type = static_cast<Control::Type>(
            control_table.at_path("type").as_string()->value_or("r")[0]),
          .mechanical_rates = { control_table.at_path("min_mechanic_rate")
                                  .as_floating_point()
                                  ->value_or(0.0l),
                                control_table.at_path("max_mechanic_rate")
                                  .as_floating_point()
                                  ->value_or(0.0l) },
          .chemical_rates = { control_table.at_path("min_chemical_rate")
                                .as_floating_point()
                                ->value_or(0.0l),
                              control_table.at_path("max_chemical_rate")
                                .as_floating_point()
                                ->value_or(0.0l) },
        };
      });

    // control points
    auto control_points_indexes_toml =
      *table.at_path("control.control_points.indexes").as_array();
    std::vector<std::int64_t> control_points_indexes;
    control_points_indexes.reserve(control_points_indexes_toml.size());
    std::transform(std::begin(control_points_indexes_toml),
                   std::end(control_points_indexes_toml),
                   std::back_inserter(control_points_indexes),
                   [](auto const& control_point_index) {
                     return control_point_index.as_integer()->value_or(0);
                   });
    auto control_points_array_toml =
      *table.at_path("control.control_points.array").as_array();
    std::vector<Position> control_points_array;
    control_points_array.reserve(control_points_array_toml.size() / 4);
    for (std::size_t i = 0; i < control_points_array_toml.size(); i += 4)
      control_points_array.push_back({
        control_points_array_toml[i + 0].as_integer()->value_or(0),
        control_points_array_toml[i + 1].as_integer()->value_or(0),
        control_points_array_toml[i + 2].as_integer()->value_or(0),
        control_points_array_toml[i + 3].as_integer()->value_or(0),
      });

    // radius
    auto radius_indexes_toml =
      *table.at_path("control.radius.indexes").as_array();
    std::vector<std::int64_t> radius_indexes;
    radius_indexes.reserve(radius_indexes_toml.size());
    std::transform(
      std::begin(radius_indexes_toml), std::end(radius_indexes_toml),
      std::back_inserter(radius_indexes), [](auto const& radius_index) {
        return radius_index.as_integer()->value_or(0);
      });
    auto radius_array_toml = *table.at_path("control.radius.array").as_array();
    std::vector<Position> radius_array;
    radius_array.reserve(radius_array_toml.size() / 4);
    for (std::size_t i = 0; i < radius_array_toml.size(); i += 4)
      radius_array.push_back({
        radius_array_toml[i + 0].as_integer()->value_or(0),
        radius_array_toml[i + 1].as_integer()->value_or(0),
        radius_array_toml[i + 2].as_integer()->value_or(0),
        radius_array_toml[i + 3].as_integer()->value_or(0),
      });

    // ===============================Climatic============================================
    auto climatic_toml = *table.at_path("climatic").as_array();
    std::vector<Climatic> climatic;
    for (auto const& climatic_table : climatic_toml) {
      auto table = *climatic_table.as_table();
      climatic.push_back(Climatic {
        .not_winged_rates = { table.at_path("not_winged_min_rate")
                                .as_floating_point()
                                ->value_or(0.0l),
                              table.at_path("not_winged_max_rate")
                                .as_floating_point()
                                ->value_or(0.0l) },
        .winged_rates = { table.at_path("winged_min_rate")
                            .as_floating_point()
                            ->value_or(0.0l),
                          table.at_path("winged_max_rate")
                            .as_floating_point()
                            ->value_or(0.0l) },
      });
    }

    // ===============================HumanCases=================================
    auto humans_cases_distribution_toml =
      *table.at_path("humans_cases_distribution").as_array();
    std::vector<HumanCase> humans_cases_distribution;
    for (auto const& human_case_table : humans_cases_distribution_toml) {
      auto table = *human_case_table.as_table();
      humans_cases_distribution.push_back(HumanCase {
        .block = table.at_path("block").as_integer()->value_or(0),
        .group = table.at_path("group").as_integer()->value_or(0),
        .x = table.at_path("x").as_integer()->value_or(0),
        .y = table.at_path("y").as_integer()->value_or(0),
        .gender = static_cast<Human::Gender>(
          table.at_path("gender").as_string()->value_or("m")[0]),
        .age_group = static_cast<Human::AgeGroup>(
          table.at_path("age_group").as_string()->value_or("a")[0]),
        .state = static_cast<Human::State>(
          table.at_path("state").as_string()->value_or("s")[0]),
        .serotype = static_cast<Human::Serotype>(
          table.at_path("serotype").as_integer()->value_or(0)),
        .cycle = table.at_path("cycle").as_integer()->value_or(0),
      });
    }

    return {
      .blocks_groups_count = blocks_groups_count,
      .blocks_indexes = blocks_indexes,
      .neighbors_indexes = neighbors_indexes,
      .neighbors = neighbors_array,
      .positions_indexes = positions_indexes,
      .positions = positions_array,
      .position_region_indexes = position_region_indexes_array,
      .frontiers_indexes = frontiers_indexes,
      .frontiers = frontiers_array,
      .corners_indexes = corners_indexes,
      .corners = corners_array,
      .corner_centers_indexes = corner_center_indexes,
      .corner_centers = corner_centers_array,
      .routes_indexes = routes_indexes,
      .routes = routes_array,
      .paths_indexes = paths_indexes,
      .periods_indexes = periods_indexes,
      .path_age_groups_indexes = paths_age_groups_indexes,
      .strategic_points = strategic_points_indexes,
      .focus_points_indexes = focus_points_indexes,
      .focus_points = focus_points_array,
      .complement = complement,
      .cases = cases,
      .controls = control,
      .control_points_indexes = control_points_indexes,
      .control_points = control_points_array,
      .radius_indexes = radius_indexes,
      .radius = radius_array,
      .climatic = climatic,
      .human_cases = humans_cases_distribution,
    };
  }

} // namespace simulator
