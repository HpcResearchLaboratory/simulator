#include "simulator/simulation.hpp"
#include <iostream>
#include <simulator/environment.hpp>
#include <simulator/monte_carlo.hpp>
#include <simulator/parameters.hpp>

#include <filesystem>
#include <fstream>
#include <string>

using std::move;

namespace fs = std::filesystem;

auto main() -> int {
  const fs::path input_path = "./assets/input";
  const fs::path output_path = "./assets/output";

  auto environment_input_file = std::ifstream { input_path / "cascavel.json" };
  auto parameters_input_file = std::ifstream { input_path / "parameters.json" };

  const auto environment_data =
    std::string { std::istreambuf_iterator<char> { environment_input_file },
                  std::istreambuf_iterator<char> {} };
  const auto parameters_data =
    std::string { std::istreambuf_iterator<char> { parameters_input_file },
                  std::istreambuf_iterator<char> {} };

  const auto environment =
    simulator::Environment::from_geojson(environment_data);
  const auto parameters = simulator::Parameters::from_json(parameters_data);

  auto simulation = simulator::Simulation { environment, parameters };
  simulation.run();

  // const auto simulations =
  //   std::views::all(fs::directory_iterator(input_path / "simulations"));
  // std::vector<std::future<void>> futures;
  // for (const auto& simulation : simulations) {
  //   auto fut = std::async(std::launch::async, [simulation, environment]() {
  //     const auto parameters = simulator::Parameters::from_dir(simulation);
  //     std::cout << parameters.blocks_count << std::endl;
  //     const auto mc =
  //       simulator::MonteCarlo { std::move(environment), std::move(parameters)
  //       };
  //     mc.run();
  //   });
  //   futures.push_back(std::move(fut));
  // }

  // for (auto& fut : futures) {
  //   fut.wait();
  // }
}
