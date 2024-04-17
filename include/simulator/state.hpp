#pragma once

#include <cstddef>
#include <tuple>
#include <utility>

namespace simulator {
  struct State {
    std::pair<std::size_t, std::size_t> progress;
    std::tuple<std::size_t, std::size_t, std::size_t, std::size_t>
      humans_in_states;
    std::tuple<std::size_t, std::size_t, std::size_t> mosquitos_in_states;
  };
} // namespace simulator
