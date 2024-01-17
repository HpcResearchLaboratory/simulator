#pragma once

#include <simulator/human/human.hpp>
#include <simulator/util/toml.hpp>

#include <cstdint>
#include <filesystem>

#include <toml++/toml.hpp>
#include <utility>

namespace simulator {
  namespace fs = std::filesystem;

  struct Environment {
    struct Position {
      std::int64_t x;
      std::int64_t y;
      std::int64_t block;
      std::int64_t group;
    };

    struct Neighbor {
      std::int64_t src_x;
      std::int64_t src_y;
      std::int64_t dst_x;
      std::int64_t dst_y;
      std::int64_t dst_group;
      std::int64_t dst_block;
    };

    struct Frontier {
      std::int64_t dst_x;
      std::int64_t dst_y;
      std::int64_t dst_group;
    };

    struct Corner {
      std::int64_t x;
      std::int64_t y;
      std::int64_t group;
    };

    struct Control {
      enum class Type : char {
        Radius = 'r',
        Block = 'b',
        StrategicPoint = 'p',
        Frontier = 'f',
        Treatment = 't',
      };

      std::int64_t block;
      std::int64_t cycle;
      Type type;
      std::pair<double, double> mechanical_rates;
      std::pair<double, double> chemical_rates;
    };

    struct Climatic {
      std::pair<double, double> not_winged_rates;
      std::pair<double, double> winged_rates;
    };

    struct HumanCase {
      std::int64_t block;
      std::int64_t group;
      std::int64_t x;
      std::int64_t y;
      Human::Gender gender;
      Human::AgeGroup age_group;
      Human::State state;
      Human::Serotype serotype;
      std::int64_t cycle;
    };

    // ============================Environment============================
    //  blocks/groups
    std::vector<std::int64_t> blocks_groups_count;
    std::vector<std::int64_t> blocks_indexes;
    // neighbors
    std::vector<std::int64_t> neighbors_indexes;
    std::vector<Neighbor> neighbors;
    // positions
    std::vector<std::int64_t> positions_indexes;
    std::vector<Position> positions;
    std::vector<std::int64_t> position_region_indexes;
    // frontiers
    std::vector<std::int64_t> frontiers_indexes;
    std::vector<Frontier> frontiers;
    // corners
    std::vector<std::int64_t> corners_indexes;
    std::vector<Corner> corners;
    // corner_centers
    std::vector<std::int64_t> corner_centers_indexes;
    std::vector<Corner> corner_centers;

    // ============================Movement============================
    // routes
    std::vector<std::int64_t> routes_indexes;
    std::vector<std::int64_t> routes;
    // paths
    std::vector<std::int64_t> paths_indexes;
    // periods
    std::vector<std::int64_t> periods_indexes;
    // path_age_groups
    std::vector<std::int64_t> path_age_groups_indexes;

    // ============================Control===========================
    // strategic_points
    std::vector<std::int64_t> strategic_points;
    // focal_points
    std::vector<std::int64_t> focus_points_indexes;
    std::vector<std::int64_t> focus_points;
    // complement
    std::vector<double> complement;
    // cases
    std::vector<std::int64_t> cases;
    // controls
    std::vector<Control> controls;
    // control points
    std::vector<std::int64_t> control_points_indexes;
    std::vector<Position> control_points;
    // radius
    std::vector<std::int64_t> radius_indexes;
    std::vector<Position> radius;

    // ============================Climatic=============
    std::vector<Climatic> climatic;

    // ============================HumanCases=============
    std::vector<HumanCase> human_cases;

    static auto from_dir(const fs::path input_path) -> Environment;
  };
} // namespace simulator
