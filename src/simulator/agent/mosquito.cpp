#include <simulator/agent/mosquito.hpp>

namespace simulator::agent {
  auto Mosquito::operator==(const Mosquito& other) const -> bool {
    return id == other.id;
  }
} // namespace simulator::agent

auto std::hash<simulator::agent::Mosquito>::operator()(
  const simulator::agent::Mosquito& mosquito) const -> std::size_t {
  return std::hash<std::size_t> {}(mosquito.id);
}
