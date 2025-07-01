#include "indicators/setting.hpp"
#include <memory>
#include <simulator/environment.hpp>
#include <simulator/parameters.hpp>
#include <simulator/simulation.hpp>
#include <simulator/util/random.hpp>

#include <filesystem>
#include <fstream>
#include <future>
#include <iostream>
#include <string>
#include <vector>

#include <argparse/argparse.hpp>
#include <indicators/dynamic_progress.hpp>
#include <indicators/progress_bar.hpp>

namespace fs = std::filesystem;

auto main(int argc, char* argv[]) -> int {
  argparse::ArgumentParser program("simula", "v1.0.0");

  program.add_argument("-i", "--input")
    .help("Input directory")
    .default_value(std::string("./assets/input"))
    .action([](const std::string& value) -> fs::path { return value; });

  program.add_argument("-o", "--output")
    .help("Output directory")
    .default_value(std::string("./assets/output"))
    .action([](const std::string& value) -> fs::path { return value; });

  try {
    program.parse_args(argc, argv);

    const auto input_path = program.get<std::string>("--input");
    const auto output_path = program.get<std::string>("--output");

    for (fs::path simulation_path : fs::directory_iterator(input_path)) {
      auto environment_input_file =
        std::ifstream { simulation_path / "environment.json" };
      auto parameters_input_file =
        std::ifstream { simulation_path / "parameters.json" };

      const auto environment_data =
        std::string { std::istreambuf_iterator<char> { environment_input_file },
                      std::istreambuf_iterator<char> {} };
      const auto parameters_data =
        std::string { std::istreambuf_iterator<char> { parameters_input_file },
                      std::istreambuf_iterator<char> {} };

      const auto parameters = simulator::Parameters::from_json(parameters_data);

      const auto environment =
        simulator::Environment::from_geojson(environment_data);

          auto simulation = simulator::Simulation(
            std::make_shared<simulator::Environment>(environment),
            std::make_shared<simulator::Parameters>(parameters));


          simulation.run();

          // get the simulation results and save them
          const auto& results = simulation.get_states();
          nlohmann::json json_results = results;

          auto output_path_simulation =
            output_path / simulation_path.filename() / "results.json";

          fs::create_directories(output_path_simulation.parent_path());
          std::ofstream output_file(output_path_simulation);
          output_file << json_results.dump(2);
          output_file.close();

    }
  } catch (const std::exception& e) {
    std::cerr << e.what() << std::endl;
    std::exit(EXIT_FAILURE);
  }
}
