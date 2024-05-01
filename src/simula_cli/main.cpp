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
    auto progress_bars = indicators::DynamicProgress<indicators::ProgressBar>();
    program.parse_args(argc, argv);
    progress_bars.set_option(indicators::option::HideBarWhenComplete { false });

    const auto input_path = program.get<std::string>("--input");
    const auto output_path = program.get<std::string>("--output");

    std::vector<std::future<void>> futures;
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

      futures.emplace_back(std::async(
        std::launch::async,
        [environment, parameters, &progress_bars, simulation_path,
         output_path] {
          auto simulation = simulator::Simulation(
            std::make_shared<simulator::Environment>(environment),
            std::make_shared<simulator::Parameters>(parameters));

          std::string agents_in_states_text = " [Humans{S:" +
            std::to_string(parameters.human_initial_susceptible) +
            ",E:" + std::to_string(parameters.human_initial_exposed) +
            ",I:" + std::to_string(parameters.human_initial_infected) +
            ",R:" + std::to_string(parameters.human_initial_recovered) +
            "}/Mosquitos{S:" +
            std::to_string(parameters.mosquito_initial_susceptible) +
            ",I:" + std::to_string(parameters.mosquito_initial_infected) +
            ",R:" + std::to_string(parameters.mosquito_initial_recovered) +
            "};";
          std::string progress_text =
            "[0/" + std::to_string(parameters.cycles) + "]";
          std::string simulation_name_text =
            "[" + simulation_path.filename().string() + "]";
          std::string simulation_state = "[running] ";

          auto bar = new indicators::ProgressBar(
            indicators::option::BarWidth { 80 },
            indicators::option::ForegroundColor {
              static_cast<indicators::Color>(
                simulator::util::make_cpu_rng<int>(0, 9)()) },
            indicators::option::Start { "[" }, indicators::option::Fill { "■" },
            indicators::option::Lead { "■" },
            indicators::option::Remainder { " " },
            indicators::option::End { " ]" },
            indicators::option::ShowElapsedTime { true },
            indicators::option::PrefixText { simulation_name_text + " -> " +
                                             simulation_state },
            indicators::option::PostfixText { progress_text +
                                              agents_in_states_text },
            indicators::option::ShowPercentage { true },
            indicators::option::MaxPostfixTextLen { 80 },
            indicators::option::MaxPostfixTextLen { 80 },
            indicators::option::MaxProgress { parameters.cycles - 1 },
            indicators::option::FontStyles {
              std::vector<indicators::FontStyle> {
                indicators::FontStyle::bold } });

          auto i = progress_bars.push_back(*bar);

          simulation.prepare();
          std::optional<simulator::State const*> state;
          while ((state = simulation.iterate()).has_value()) {
            const auto [actual, total] = state.value()->progress;
            const auto [humans_s, humans_e, humans_i, humans_r] =
              state.value()->humans_in_states;
            const auto [mosquitos_s, mosquitos_i, mosquitos_r] =
              state.value()->mosquitos_in_states;

            progress_text =
              "[" + std::to_string(actual) + "/" + std::to_string(total) + "]";
            agents_in_states_text = " [Humans{S:" + std::to_string(humans_s) +
              ",E:" + std::to_string(humans_e) +
              ",I:" + std::to_string(humans_i) +
              ",R:" + std::to_string(humans_r) +
              "}/Mosquitos{S:" + std::to_string(mosquitos_s) +
              ",I:" + std::to_string(mosquitos_i) +
              ",R:" + std::to_string(mosquitos_r) + "}]";

            progress_bars[i].set_option(indicators::option::PrefixText {
              simulation_name_text + " -> " + simulation_state });
            progress_bars[i].set_option(indicators::option::PostfixText {
              progress_text + agents_in_states_text });

            progress_bars[i].tick();
          }
          simulation_state = "[generating results] ";
          progress_bars[i].set_option(indicators::option::PrefixText {
            simulation_name_text + " -> " + simulation_state });
          progress_bars[i].set_option(indicators::option::PostfixText {
            progress_text + agents_in_states_text });
          progress_bars[i].set_option(
            indicators::option::ForegroundColor { indicators::Color::yellow });

          // get the simulation results and save them
          const auto& results = simulation.get_states();
          nlohmann::json json_results = results;

          auto output_path_simulation =
            output_path / simulation_path.filename() / "results.json";

          fs::create_directories(output_path_simulation.parent_path());
          std::ofstream output_file(output_path_simulation);
          output_file << json_results.dump(2);
          output_file.close();

          simulation_state = "[completed] ";
          progress_bars[i].set_option(indicators::option::PrefixText {
            simulation_name_text + " -> " + simulation_state });
          progress_bars[i].set_option(
            indicators::option::ForegroundColor { indicators::Color::green });
          progress_bars[i].mark_as_completed();
        }));
    }
    for (auto& fut : futures) {
      fut.wait();
    }
  } catch (const std::exception& e) {
    std::cerr << e.what() << std::endl;
    std::exit(EXIT_FAILURE);
  }
}
