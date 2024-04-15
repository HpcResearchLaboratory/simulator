#pragma once

#include <simulator/agent.hpp>
#include <simulator/agent/human.hpp>
#include <simulator/agent/mosquito.hpp>
#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>

#include <memory>
#include <vector>

#include <exec/on.hpp>
#include <exec/static_thread_pool.hpp>
#include <nvexec/multi_gpu_context.cuh>
#include <stdexec/execution.hpp>

namespace simulator {
  class Simulation {
    std::unique_ptr<const Environment> environment;
    std::unique_ptr<const Parameters> parameters;

    std::unique_ptr<std::vector<agent::Human>> humans;
    std::unique_ptr<std::vector<agent::Mosquito>> mosquitos;

    std::unique_ptr<std::vector<
      std::pair<std::vector<std::int64_t>, std::vector<std::int64_t>>>>
      agents_in_position;

    nvexec::multi_gpu_stream_context gpu_ctx;
    exec::static_thread_pool cpu_ctx;

    nvexec::multi_gpu_stream_scheduler gpu;
    exec::static_thread_pool::scheduler cpu;

    auto insertion() noexcept;
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
