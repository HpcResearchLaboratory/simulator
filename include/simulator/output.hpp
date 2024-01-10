#pragma once

#include <filesystem>

namespace simulator {
  namespace fs = std::filesystem;

  struct Output {
    const fs::path output_path;
    static auto from_dir(const fs::path input_path) -> Output;
  };
} // namespace simulator
