#pragma once

#include <cstddef>
#include <functional>

namespace simulator {
  struct Human {
    enum struct State : char {
      Susceptible = 's',
      Exposed = 'e',
      Infected = 'i',
      Recovered = 'r'
    };

    mutable State state;
    std::size_t id;
    mutable std::size_t position;

    auto operator==(const Human& other) const -> bool;
  };
} // namespace simulator

template <>
struct std::hash<simulator::Human> {
  auto operator()(const simulator::Human& human) const -> std::size_t;
};
