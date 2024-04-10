#pragma once

#include <simulator/agent/human.hpp>
#include <simulator/agent/mosquito.hpp>

#include <variant>

namespace simulator {
  using Agent = std::variant<agent::Human, agent::Mosquito>;
} // namespace simulator

template <>
struct std::hash<simulator::Agent> {
  auto operator()(const simulator::Agent& agent) const -> std::size_t;
};
