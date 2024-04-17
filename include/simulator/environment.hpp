#pragma once

#include <cstddef>
#include <string_view>
#include <vector>

namespace simulator {

  struct Environment {
    using Point = std::pair<double, double>;

    std::vector<Point> points;
    std::vector<std::vector<std::size_t>> edges;
    std::size_t size = 0UL;

    static auto from_geojson(const std::string_view) noexcept -> Environment;
  };

} // namespace simulator
