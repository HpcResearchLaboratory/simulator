#pragma once

#include <cstddef>
#include <tuple>
#include <utility>

namespace simulator {
  using Result =
    std::pair<std::tuple<std::size_t, std::size_t, std::size_t, std::size_t>,
              std::tuple<std::size_t, std::size_t, std::size_t>>;
} // namespace simulator
