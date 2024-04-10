#pragma once

#include <cstddef>
#include <string_view>
#include <vector>

namespace simulator {

  struct Environment {
    /**
     * Distance threshold for two points to be considered connected.
     */
    static constexpr auto distance_threshold = 1e-7;

    using Point = std::pair<double, double>;

    std::vector<Point> points;
    std::vector<std::vector<std::size_t>> edges;
    std::size_t size = 0UL;

    static auto from_geojson(const std::string_view) noexcept -> Environment;
  };

} // namespace simulator
