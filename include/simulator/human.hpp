#pragma once

#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>

#include <cstddef>

#include <nlohmann/json.hpp>

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
    mutable std::size_t counter;

    auto operator==(const Human& other) const -> bool;
  };

  NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE_WITH_DEFAULT(Human, state, id, position,
                                                  counter);
} // namespace simulator

template <>
struct std::hash<simulator::Human> {
  auto operator()(const simulator::Human& human) const -> std::size_t;
};
