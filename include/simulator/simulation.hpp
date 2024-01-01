#pragma once

#include <cstdint>

namespace simulator {
  class Simulation {
    std::uint32_t number_simulations;

  public:
    auto run() const -> void;
    [[nodiscard]] auto get_number_simulations() const -> std::uint32_t {
      return number_simulations;
    }
  };
} // namespace simulator
