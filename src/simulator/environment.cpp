#include <cstddef>
#include <iostream>
#include <iterator>
#include <set>
#include <simulator/environment.hpp>

#include <optional>
#include <ranges>
#include <string_view>
#include <unordered_map>

#include <nlohmann/json.hpp>

namespace simulator {

  using json = nlohmann::json;

  auto Environment::print() const -> void {

    for (const auto& [id, point] : points) {
      std::cout << "ID: " << id << " - Point: (" << point.first << ", "
                << point.second << ")\n";
    }
  }

  auto Environment::size() const -> std::size_t {
    return points.size();
  }

  auto Environment::get_nth_point_id(std::size_t id) const -> std::size_t {
    // return the id-nth key, not use id as key
    return std::next(points.begin(), static_cast<std::ptrdiff_t>(id))->first;
  }

  auto Environment::get_points() const
    -> const std::unordered_map<std::size_t, Point>& {
    return points;
  }

  auto Environment::get_edges(std::size_t point_id) const
    -> const std::set<std::size_t>& {
    return edges.at(point_id);
  }

  // TODO: Support "Polygon" type
  auto Environment::from_geojson(const std::string_view data) -> Environment {
    std::unordered_map<std::size_t, Point> points;
    std::unordered_map<std::size_t, std::set<std::size_t>> edges;

    const auto environment = json::parse(data);

    for (const auto& feature : environment["features"]) {
      const auto& type = feature["geometry"]["type"].get<std::string>();
      if (type == "Point") {
        const auto& point = feature["geometry"]["coordinates"].get<Point>();
        const auto& id = feature["id"].get<std::size_t>();

        points.emplace(id, point);
      } else if (type == "LineString") {
        const auto coordinates =
          feature["geometry"]["coordinates"].get<std::vector<Point>>();

        for (std::size_t i = 0; i < coordinates.size() - 1; ++i) {
          const auto& start = coordinates[i];
          const auto& end = coordinates[i + 1];

          const auto start_id = [&] {
            for (const auto& [id, point] : points) {
              const auto distance = std::pow(point.first - start.first, 2) +
                std::pow(point.second - start.second, 2);

              if (distance < distance_threshold)
                return std::optional { id };
            }
            return std::optional<std::size_t> {};
          }();

          const auto end_id = [&] {
            for (const auto& [id, point] : points) {
              const auto distance = std::pow(point.first - end.first, 2) +
                std::pow(point.second - end.second, 2);

              if (distance < distance_threshold)
                return std::optional { id };
            }
            return std::optional<std::size_t> {};
          }();

          if (start_id && end_id && start_id != end_id) {
            edges[start_id.value()].insert(end_id.value());
            edges[end_id.value()].insert(start_id.value());
          }
        }
      }
    }

    return { points, edges };
  }
} // namespace simulator
