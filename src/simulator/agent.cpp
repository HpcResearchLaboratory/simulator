#include <simulator/agent.hpp>

#include <functional>

namespace simulator {}

auto std::hash<simulator::Agent>::operator()(
  const simulator::Agent& agent) const -> size_t {
  return std::visit(
    [](const auto& agent) { return std::hash<std::size_t> {}(agent.id); },
    agent);
}
