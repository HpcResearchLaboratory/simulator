#include <simulator/agents/human.hpp>

namespace simulator {
  auto Human::operator==(const Human& other) const -> bool {
    return id == other.id;
  }
} // namespace simulator

auto std::hash<simulator::Human>::operator()(
  const simulator::Human& human) const -> std::size_t {
  return std::hash<std::size_t> {}(human.id);
}
