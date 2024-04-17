#pragma once

#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>

#include <cstddef>
#include <functional>

namespace simulator::agent {
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
    mutable std::size_t counter;

    auto operator==(const Human& other) const -> bool;
  };
} // namespace simulator::agent

template <>
struct std::hash<simulator::agent::Human> {
  auto operator()(const simulator::agent::Human& human) const -> std::size_t;
};
