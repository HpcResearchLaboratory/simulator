#pragma once

#include <functional>
#include <random>
#include <type_traits>

#include <toml++/toml.hpp>

namespace simulator::util {
  template <typename T>
    requires std::is_arithmetic_v<T>
  auto make_random_generator_in_range(const T min,
                                      const T max) -> std::function<T()> {
    static std::mt19937 rng(std::random_device {}());
    if constexpr (std::is_integral_v<T>) {
      return [&]() {
        return std::uniform_int_distribution<T>(min, max)(rng);
      };
    } else {
      return [&]() {
        return std::uniform_real_distribution<T>(min, max)(rng);
      };
    }
  }

  template <typename T>
    requires std::is_arithmetic_v<T>
  auto random_value_in_range(const toml::table* table) -> T {
    return make_random_generator_in_range<T>(table->at("min").value_or(T {}),
                                             table->at("max").value_or(T {}))();
  }

} // namespace simulator::util
