#include <simulator/environment.hpp>
#include <simulator/monte_carlo.hpp>
#include <simulator/output.hpp>
#include <simulator/parameters.hpp>

#include <cuda_runtime.h>
#include <curand.h>

#include <cstddef>
#include <cstdlib>
#include <iostream>

#include <cxxopts.hpp>

auto main(int argc, char** argv) -> int {
  cxxopts::Options options("simulator",
                           "Command line disease spread simulator");
  // clang-format off
  options.add_options()
    ("d,device", "CUDA device to run", cxxopts::value<int>()->default_value("0"))
    ("n,number_of_mc_simulations", "Number of simulations to run in the monte carlo strategy", cxxopts::value<int>()->default_value("1"))
    ("s,subcycle_output", "Wheather to print or not data in every subcycle", cxxopts::value<bool>()->default_value("false"))
    ("h,help", "Print help")
  ;
  // clang-format on

  const auto result = options.parse(argc, argv);
  if (result.count("help")) {
    std::cout << options.help() << std::endl;
    std::exit(0);
  }

  const auto device = result["device"].as<int>();
  const auto number_of_simulations =
    result["number_of_mc_simulations"].as<int>();
  // auto subcycle_output = result["subcycle_output"].as<bool>();

  cudaSetDevice(device);
  for (int i = 0; i < number_of_simulations; ++i) {
    const auto parameters = simulator::Parameters::from_dir(
      "assets/input/mc" + std::to_string(i) + "/parameters");
    const auto environment = simulator::Environment::from_dir(
      "assets/input/mc" + std::to_string(i) + "/environment");
    const auto output =
      simulator::Output::from_dir("assets/output/mc" + std::to_string(i));

    simulator::MonteCarlo { parameters, environment, output }.run();
  }
}
