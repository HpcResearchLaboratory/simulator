#pragma once

#include <simulator/util/random.hpp>

#include <filesystem>
#include <toml++/toml.hpp>

namespace simulator::util {
  namespace fs = std::filesystem;

  auto parse_toml(fs::path input_path) -> toml::table;
  auto merge_toml(toml::array& lhs, toml::array&& rhs) -> void;
  auto merge_toml(toml::table& lhs, toml::table&& rhs) -> void;
} // namespace simulator::util
