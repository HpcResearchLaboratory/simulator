#pragma once

#include <set>
#include <string_view>
#include <unordered_map>

namespace simulator {

  class Environment {
    /**
     * Distance threshold for two points to be considered connected.
     */
    static constexpr auto distance_threshold = 1e-7;

    using Point = std::pair<double, double>;

    std::unordered_map<std::size_t, Point> points;
    std::unordered_map<std::size_t, std::set<std::size_t>> edges;

    Environment(std::unordered_map<std::size_t, Point> points,
                std::unordered_map<std::size_t, std::set<std::size_t>> edges)
      : points { std::move(points) }, edges { std::move(edges) } {}

  public:
    auto size() const -> std::size_t;
    auto get_nth_point_id(std::size_t) const -> std::size_t;
    auto get_points() const -> const std::unordered_map<std::size_t, Point>&;
    auto get_edges(std::size_t) const -> const std::set<std::size_t>&;
    auto print() const -> void;

    static auto from_geojson(const std::string_view) -> Environment;
  };

} // namespace simulator
