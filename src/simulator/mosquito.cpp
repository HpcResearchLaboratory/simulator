#include <simulator/mosquito.hpp>

namespace simulator {
  auto Mosquito::operator==(const Mosquito& other) const -> bool {
    return id == other.id;
  }
} // namespace simulator

auto std::hash<simulator::Mosquito>::operator()(
  const simulator::Mosquito& mosquito) const -> std::size_t {
  return std::hash<std::size_t> {}(mosquito.id);
}
