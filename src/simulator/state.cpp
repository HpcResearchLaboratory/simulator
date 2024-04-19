#include <simulator/state.hpp>

#include <nlohmann/json.hpp>

namespace simulator {
  auto State::to_json() const noexcept -> const std::string {
    return to_json(*this);
  }
} // namespace simulator
