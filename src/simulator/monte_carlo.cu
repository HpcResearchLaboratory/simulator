#include <simulator/environment.hpp>
#include <simulator/monte_carlo.hpp>
#include <simulator/parameters.hpp>

#include <filesystem>

namespace simulator {
  namespace fs = std::filesystem;

  MonteCarlo::MonteCarlo(fs::path input_path, fs::path output_path,
                         bool subcycle_output)
    : input_path(std::move(input_path)), output_path(std::move(output_path)),
      subcycle_output(subcycle_output) {
    fs::create_directories(this->output_path);
    auto parameters = Parameters::from_dir(this->input_path / "parameters");
    auto environment = Environment::from_dir(this->input_path / "environment");
  };

  auto MonteCarlo::run() const -> void {}
} // namespace simulator
