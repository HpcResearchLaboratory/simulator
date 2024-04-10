#pragma once

#include <chrono>
#include <cstddef>
#include <ctime>
#include <functional>
#include <random>
#include <type_traits>

#include <thrust/random.h>

namespace simulator::util {

  template <typename T>
    requires std::is_arithmetic_v<T>
  auto make_cpu_rng(T min, T max) noexcept -> std::function<T()> {
    if constexpr (std::is_integral_v<T>) {
      return [=] {
        std::mt19937 rng(std::random_device {}());
        return std::uniform_int_distribution<T>(min, max)(rng);
      };
    } else {
      return [=] {
        std::mt19937 rng(std::random_device {}());
        return std::uniform_real_distribution<T>(min, max)(rng);
      };
    }
  }

  template <typename T>
    requires std::is_arithmetic_v<T>
  auto make_gpu_rng(T min, T max, std::size_t seed) noexcept
    -> std::function<T(std::size_t)> {

    if constexpr (std::is_integral_v<T>) {
      return [=](std::size_t idx) mutable {
        thrust::default_random_engine rng(seed);
        thrust::uniform_int_distribution<T> dist(min, max);
        rng.discard(idx);
        return dist(rng);
      };
    } else {
      return [=](std::size_t idx) mutable {
        thrust::default_random_engine rng(seed);
        thrust::uniform_real_distribution<T> dist(min, max);
        rng.discard(idx);
        return dist(rng);
      };
    }
  }
} // namespace simulator::util
