#include <simulator/output.hpp>

namespace simulator {
  auto Output::from_dir(const fs::path output_path) -> Output {
    // NOTE: dummy implementation for now, just make sure the directory exists
    fs::create_directories(output_path);
    return { output_path };
  }
} // namespace simulator
