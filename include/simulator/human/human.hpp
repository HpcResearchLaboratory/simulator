#pragma once

#include <cstdint>
#include <optional>
#include <set>

namespace simulator {
  struct Human {
    enum class MovementType : char {
      random = 'r',
      local = 'l',
      path = 'p',
    };
    enum class Gender : char {
      male = 'm',
      female = 'f',
    };
    enum class AgeGroup : char {
      baby = 'b',
      child = 'c',
      teenager = 't',
      young_adult = 'y',
      adult = 'a',
      senior = 's',
    };
    enum class State : char {
      susceptible = 's',
      exposed = 'e',
      infectious = 'i',
      recovered = 'r',
    };
    enum class Serotype : uint8_t {
      type1 = 1,
      type2,
      type3,
      type4
    };

    MovementType movement_type;
    Gender gender;
    AgeGroup age_group;
    State state;
    std::optional<Serotype> serotype;

    std::uint64_t route_id;
    std::uint64_t path_id;
    bool has_moved_this_cycle;
    std::uint64_t movement_count;
    std::uint64_t repast_count;
    std::set<Serotype> serotypes_contracted;
    bool assintomatic;
    std::uint64_t state_transition_count;
    std::uint64_t vaccination_count;
    std::uint64_t latitudinal_index;
    std::uint64_t longitudinal_index;
    std::uint64_t block_id;
    std::uint64_t location_id;
  };

} // namespace simulator
