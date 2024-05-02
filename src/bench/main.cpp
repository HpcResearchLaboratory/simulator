#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>
#include <simulator/simulation.hpp>

#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>

#include <argparse/argparse.hpp>

namespace fs = std::filesystem;

auto main(int argc, char* argv[]) -> int {

  argparse::ArgumentParser program("bench", "v1.0.0");

  program.add_argument("-i", "--input")
    .help("Input Simulation directory")
    .default_value(fs::path { "./assets/input/small" })
    .action([](const std::string& value) -> fs::path { return value; });

  program.add_argument("-o", "--output")
    .help("Output directory")
    .default_value(fs::path { "./assets/output/small" })
    .action([](const std::string& value) -> fs::path { return value; });

  program.add_argument("-t", "--threads")
    .help("Number of threads")
    .default_value(
      static_cast<std::size_t>(std::thread::hardware_concurrency()))
    .action([](const std::string& value) -> std::size_t {
      return std::stoul(value);
    });

  try {
    program.parse_args(argc, argv);

    const auto input_path = program.get<fs::path>("--input");
    const auto output_path = program.get<fs::path>("--output");
    const auto threads = program.get<std::size_t>("--threads");

    auto environment_input_file =
      std::ifstream { fs::path { input_path } / "environment.json" };
    auto parameters_input_file =
      std::ifstream { fs::path { input_path } / "parameters.json" };
    const auto environment_data =
      std::string { std::istreambuf_iterator<char> { environment_input_file },
                    std::istreambuf_iterator<char> {} };
    const auto parameters_data =
      std::string { std::istreambuf_iterator<char> { parameters_input_file },
                    std::istreambuf_iterator<char> {} };
    const auto parameters = simulator::Parameters::from_json(parameters_data);
    const auto environment =
      simulator::Environment::from_geojson(environment_data);
    std::cout  << environment.size << std::endl;
    auto simulation = simulator::Simulation(
      std::make_shared<simulator::Environment>(environment),
      std::make_shared<simulator::Parameters>(parameters), threads);
    simulation.run();
  } catch (const std::exception& e) {
    std::cerr << e.what() << std::endl;
    return 1;
  }

  return 0;
}
