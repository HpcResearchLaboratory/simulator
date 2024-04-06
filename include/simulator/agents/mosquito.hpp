#pragma once

#include <cstddef>
#include <functional>

namespace simulator {
  struct Mosquito {
    enum struct State {
      Susceptible = 's',
      Infected = 'i',
      Recovered = 'r'
    };
    mutable State state;
    std::size_t id;
    mutable std::size_t position;

    auto operator==(const Mosquito& other) const -> bool;
  };

} // namespace simulator

template <>
struct std::hash<simulator::Mosquito> {
  auto operator()(const simulator::Mosquito& mosquito) const -> std::size_t;
};
