#include <simulator/agent/human.hpp>
#include <simulator/util/random.hpp>

namespace simulator::agent {
  auto Human::operator==(const Human& other) const -> bool {
    return id == other.id;
  }
} // namespace simulator::agent

auto std::hash<simulator::agent::Human>::operator()(
  const simulator::agent::Human& human) const -> std::size_t {
  return std::hash<std::size_t> {}(human.id);
}
