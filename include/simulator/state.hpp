#pragma once

#include <nlohmann/detail/macro_scope.hpp>
#include <simulator/human.hpp>
#include <simulator/mosquito.hpp>

#include <cstddef>
#include <tuple>
#include <utility>
#include <vector>

#include <nlohmann/json.hpp>

namespace simulator {
  struct State {
    std::pair<std::size_t, std::size_t> progress;
    std::tuple<std::size_t, std::size_t, std::size_t, std::size_t>
      humans_in_states;
    std::tuple<std::size_t, std::size_t, std::size_t> mosquitos_in_states;
    std::vector<Human> humans;
    std::vector<Mosquito> mosquitos;

    [[nodiscard]] auto to_json() const noexcept -> const std::string;
    [[nodiscard]] static auto to_json(const State& state) noexcept
      -> const std::string;
  };

  NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE_WITH_DEFAULT(State, progress,
                                                  humans_in_states,
                                                  mosquitos_in_states, humans,
                                                  mosquitos);
} // namespace simulator
