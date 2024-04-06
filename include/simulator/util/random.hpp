#pragma once

#include <functional>
#include <random>
#include <type_traits>

namespace simulator::util {

  template <typename T>
    requires std::is_arithmetic_v<T>
  auto make_random_generator_in_range(T min, T max) -> std::function<T()> {
    static std::mt19937 rng(std::random_device {}());
    if constexpr (std::is_integral_v<T>) {
      return [=] {
        return std::uniform_int_distribution<T>(min, max)(rng);
      };
    } else {
      return [=] {
        return std::uniform_real_distribution<T>(min, max)(rng);
      };
    }
  }
} // namespace simulator::util
