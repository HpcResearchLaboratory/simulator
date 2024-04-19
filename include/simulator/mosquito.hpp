#pragma once

#include <cstddef>
#include <functional>

#include <nlohmann/json.hpp>

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
    mutable std::size_t counter;

    auto operator==(const Mosquito& other) const -> bool;
  };

  NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE_WITH_DEFAULT(Mosquito, state, id, position,
                                                  counter);

} // namespace simulator

template <>
struct std::hash<simulator::Mosquito> {
  auto operator()(const simulator::Mosquito& mosquito) const -> std::size_t;
};
