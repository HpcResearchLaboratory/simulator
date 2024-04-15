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

  auto Environment::from_geojson(const std::string_view data) noexcept
    -> Environment {
    std::vector<Point> points;
    std::vector<std::vector<std::size_t>> edges;

    const auto environment = json::parse(data);

    for (const auto& feature : environment["features"]) {
      const auto& type = feature["geometry"]["type"].get<std::string>();
      if (type == "Point") {
        const auto& point = feature["geometry"]["coordinates"].get<Point>();
        const auto& id = feature["id"].get<std::size_t>();

        points.emplace_back(point);
        edges.emplace_back();
      } else if (type == "LineString") {
        const auto src = feature["src"].get<std::size_t>();
        const auto tgt = feature["tgt"].get<std::size_t>();

        // NOTE: Points ids begin at 1, but point indices begin at 0
        edges[src - 1].push_back(tgt - 1);
        edges[tgt - 1].push_back(src - 1);
      }
    }

    return { points, edges, points.size() };
  }
} // namespace simulator
