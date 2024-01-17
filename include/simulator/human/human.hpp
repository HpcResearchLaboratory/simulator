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

    std::int64_t id;
    std::int64_t route;
    std::int64_t path;
    bool has_moved_this_cycle;
    std::int64_t movement_count;
    MovementType movement_type;
    std::int64_t repast_count;
    Gender gender;
    AgeGroup age_group;
    State state;
    std::optional<Serotype> serotype;
    std::set<Serotype> serotypes_contracted;
    bool is_assymptomatic;
    std::int64_t state_transition_count;
    std::int64_t vaccination_count;
    std::int64_t x;
    std::int64_t y;
    std::int64_t block;
    std::int64_t group;
  };

} // namespace simulator
