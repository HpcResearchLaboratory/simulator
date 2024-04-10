#pragma once

#include <simulator/agent.hpp>
#include <simulator/agent/human.hpp>
#include <simulator/agent/mosquito.hpp>
#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>

#include <memory>
#include <vector>

namespace simulator {
  class Simulation {
    std::unique_ptr<const Environment> environment;
    std::unique_ptr<const Parameters> parameters;

    std::unique_ptr<std::vector<agent::Human>> humans;
    std::unique_ptr<std::vector<agent::Mosquito>> mosquitos;

    std::unique_ptr<std::vector<
      std::pair<std::vector<std::size_t>, std::vector<std::size_t>>>>
      agents_in_position;

    auto insertion() noexcept -> void;
    auto movement() noexcept -> void;
    auto contact() noexcept -> void;
    auto transition() noexcept -> void;
    auto output() noexcept -> void;

  public:
    Simulation(std::unique_ptr<const Environment> environment,
               std::unique_ptr<const Parameters> parameters) noexcept;
    auto run() noexcept -> void;
  };
} // namespace simulator
