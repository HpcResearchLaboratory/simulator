#include <simulator/environment.hpp>

#include <cstddef>
#include <iostream>
#include <optional>
#include <ranges>
#include <set>
#include <string_view>
#include <unordered_map>

#include <nlohmann/json.hpp>

namespace simulator {

  using json = nlohmann::json;

  // TODO: Support "Polygon" type
  auto Environment::from_geojson(const std::string_view data) -> Environment {
    std::vector<Point> points;
    std::vector<std::vector<std::size_t>> edges;

    const auto environment = json::parse(data);

    for (const auto& feature : environment["features"]) {
      const auto& type = feature["geometry"]["type"].get<std::string>();
      if (type == "Point") {
        const auto& point = feature["geometry"]["coordinates"].get<Point>();
        /*const auto& id = feature["id"].get<std::size_t>();*/

        points.emplace_back(point);
        edges.emplace_back();
      } else if (type == "LineString") {
        const auto coordinates =
          feature["geometry"]["coordinates"].get<std::vector<Point>>();

        for (std::size_t i = 0; i < coordinates.size() - 1; ++i) {
          const auto& start = coordinates[i];
          const auto& end = coordinates[i + 1];

          const auto start_id = [&] {
            for (auto id = 0UL; id < points.size(); id++) {
              const auto& point = points[id];
              const auto distance = std::pow(point.first - start.first, 2) +
                std::pow(point.second - start.second, 2);

              if (distance < distance_threshold) {
                return std::optional { id };
              }
            }
            return std::optional<std::size_t> {};
          }();

          const auto end_id = [&] {
            for (auto id = 0UL; id < points.size(); id++) {
              const auto& point = points[id];
              const auto distance = std::pow(point.first - end.first, 2) +
                std::pow(point.second - end.second, 2);

              if (distance < distance_threshold) {
                return std::optional { id };
              }
            }
            return std::optional<std::size_t> {};
          }();

          if (start_id && end_id && start_id != end_id) {
            edges[start_id.value()].push_back(end_id.value());
            edges[end_id.value()].push_back(start_id.value());
          }
        }
      }
    }

    return { points, edges, points.size() };
  }
} // namespace simulator
