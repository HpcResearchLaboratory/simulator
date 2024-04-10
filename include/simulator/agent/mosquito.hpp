#pragma once

#include <cstddef>
#include <functional>

namespace simulator::agent {
  struct Mosquito {
    enum struct State {
      Susceptible = 's',
      Infected = 'i',
      Recovered = 'r'
    };
    mutable State state;
    std::size_t id;
    mutable std::size_t position;
    mutable std::size_t counter;

    auto operator==(const Mosquito& other) const -> bool;
  };

} // namespace simulator::agent

template <>
struct std::hash<simulator::agent::Mosquito> {
  auto operator()(const simulator::agent::Mosquito& mosquito) const
    -> std::size_t;
};
