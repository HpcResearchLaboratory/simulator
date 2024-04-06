#pragma once

#include <cstddef>

namespace simulator {
  struct Agent {
    enum struct State {
      SUSCEPTIBLE,
      EXPOSED,
      INFECTED,
      RECOVERED
    };

    State state;

    std::size_t x;
    std::size_t y;
    std::size_t l;
    // std::size_t c;
  };
} // namespace simulator
