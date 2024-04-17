#pragma once

#include <simulator/agent/human.hpp>
#include <simulator/agent/mosquito.hpp>
#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>
#include <simulator/state.hpp>

#include <cstddef>
#include <memory>
#include <vector>

#include <exec/on.hpp>
#include <exec/static_thread_pool.hpp>
#include <nvexec/multi_gpu_context.cuh>
#include <stdexec/execution.hpp>

namespace simulator {
  class Simulation {
    std::size_t iteration = 0;

    std::shared_ptr<const Environment> environment;
    std::unique_ptr<const Parameters> parameters;

    nvexec::multi_gpu_stream_scheduler gpu;
    exec::static_thread_pool::scheduler cpu;

    std::unique_ptr<std::vector<agent::Human>> humans;
    std::unique_ptr<std::vector<agent::Mosquito>> mosquitos;
    std::unique_ptr<std::vector<
      std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>>
      agents_in_position;

    auto insertion() noexcept -> void;
    auto movement() noexcept -> void;
    auto contact() noexcept -> void;
    auto transition() noexcept -> void;
    [[nodiscard]] auto output() noexcept -> State;

  public:
    Simulation(std::shared_ptr<const Environment> environment,
               std::unique_ptr<const Parameters> parameters,
               nvexec::multi_gpu_stream_scheduler&& gpu_ctx,
               exec::static_thread_pool::scheduler&& cpu_ctx) noexcept;
    /**
     * @brief Run the simulation
     *
     * This method runs all the simulation steps until the end of the simulation
     */
    auto run() noexcept -> void;

    /**
     * @brief Prepare the simulation
     *
     * This method prepares the simulation for the first iteration
     */
    auto prepare() noexcept -> void;

    /**
     * @brief Iterate the simulation
     *
     * This method runs one iteration of the simulation and returns the state
     */
    [[nodiscard]] auto iterate() noexcept -> std::optional<State>;
  };
} // namespace simulator
