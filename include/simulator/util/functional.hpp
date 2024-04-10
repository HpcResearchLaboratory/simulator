#pragma once

namespace simulator::util {
  template <typename... Ts>
  struct overloaded : Ts... {
    using Ts::operator()...;
  };

  template <class... Ts>
  overloaded(Ts...) -> overloaded<Ts...>;
} // namespace simulator::util
