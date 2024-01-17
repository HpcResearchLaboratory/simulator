#pragma once

#include <cstdint>
#include <optional>

namespace simulator {
  struct Mosquito {
    enum class Gender : char {
      male = 'm',
      female = 'f',
    };

    enum class Phase : char {
      egg = 'e',
      larva = 'l',
      pupa = 'p',
      adult = 'a',
      decadent = 'd',
    };

    enum class State : char {
      susceptible = 's',
      exposed = 'e',
      infectious = 'i',
    };

    enum class Serotype : uint8_t {
      type1 = 1,
      type2,
      type3,
      type4
    };

    enum class MatingState {
      infected,
      healthy,
    };

    std::int64_t id;
    Gender gender;
    Phase phase;
    std::int64_t age;
    State state;
    Serotype serotype;
    bool is_dead;
    std::int64_t counter;
    bool should_lay_eggs;
    bool should_search_for_mate;
    bool should_search_for_strategic_point;
    bool should_do_long_distance_flight;
    std::int64_t gestation_count;
    std::int64_t cycles_between_lay;
    bool is_fed;
    std::optional<MatingState> mating_state;
    std::int64_t lay_count;

    std::int64_t x;
    std::int64_t y;
    std::int64_t block;
    std::int64_t group;
  };
} // namespace simulator
