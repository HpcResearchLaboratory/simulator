#include <numeric>
#include <simulator/util/toml.hpp>

#include <ranges>

#include <toml++/toml.hpp>

namespace simulator::util {

  auto parse_toml(fs::path input_path) -> toml::table {
    if (!fs::exists(input_path)) {
      throw std::runtime_error("Input path does not exist");
    }

    auto is_toml_file = [](auto const& entry) {
      return entry.is_regular_file() && entry.path().extension() == ".toml";
    };

    auto parse_toml_file = [](auto const& entry) {
      return toml::parse_file(entry.path().string());
    };

    auto merge_toml_tables = [](auto acc, auto&& table) {
      merge_toml(acc, std::move(table));
      return acc;
    };

    /* This will recursively iterate over all files in the input directory,
       filter out only .toml files, parse them, and then merge the parsed
       tables into a single table. */
    auto tables = fs::recursive_directory_iterator(input_path) |
      std::views::filter(is_toml_file) | std::views::transform(parse_toml_file);

    return std::accumulate(std::begin(tables), std::end(tables), toml::table {},
                           merge_toml_tables);
  }
  void merge_toml(toml::array& lhs, toml::array&& rhs) {
    rhs.for_each([&](std::size_t index, auto&& rhs_val) {
      // rhs index not found in lhs - direct move
      if (lhs.size() <= index) {
        lhs.push_back(std::move(rhs_val));
        return;
      }

      // both elements were the same container type -  recurse into them
      if constexpr (toml::is_container<decltype(rhs_val)>) {
        using rhs_type =
          std::remove_cv_t<std::remove_reference_t<decltype(rhs_val)>>;
        if (auto lhs_child = lhs[index].as<rhs_type>()) {
          merge_toml(*lhs_child, std::move(rhs_val));
          return;
        }
      }

      // replace lhs element with rhs
      lhs.replace(lhs.cbegin() + static_cast<std::ptrdiff_t>(index),
                  std::move(rhs_val));
    });
  }

  void merge_toml(toml::table& lhs, toml::table&& rhs) {
    rhs.for_each([&](const toml::key& rhs_key, auto&& rhs_val) {
      auto lhs_it = lhs.lower_bound(rhs_key);

      // rhs key not found in lhs - direct move
      if (lhs_it == lhs.cend() || lhs_it->first != rhs_key) {
        using rhs_type =
          std::remove_cv_t<std::remove_reference_t<decltype(rhs_val)>>;
        lhs.emplace_hint<rhs_type>(lhs_it, rhs_key, std::move(rhs_val));
        return;
      }

      // both children were the same container type -  recurse into them
      if constexpr (toml::is_container<decltype(rhs_val)>) {
        using rhs_type =
          std::remove_cv_t<std::remove_reference_t<decltype(rhs_val)>>;
        if (auto lhs_child = lhs_it->second.as<rhs_type>()) {
          merge_toml(*lhs_child, std::move(rhs_val));
          return;
        }
      }

      // replace lhs value with rhs
      lhs.insert_or_assign(rhs_key, std::move(rhs_val));
    });
  }
} // namespace simulator::util
