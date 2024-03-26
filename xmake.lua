--[[ Project definitions ]]
set_project("simulator")
set_description("A disease spreading simulator")
set_languages("c++latest")


--[[ Project settings ]]
set_toolchains("cuda")
add_rules("mode.debug", "mode.release", "mode.releasedbg", "plugin.compile_commands.autoupdate")
set_defaultmode("release")
set_warnings("all", "error", "allextra")
set_optimize("fastest")
add_includedirs("include")
add_cxxflags("-std=c++23", "-stdpar", { force = true })
add_ldflags("-L/usr/local/lib", "-L/usr/lib", "-stdpar", { force = true })

set_policy("build.optimization.lto", true)
set_policy("build.warning", true)
-- set_policy("build.merge_archive", true)
set_policy("package.requires_lock", true)


-- [[ Project dependencies and repositories ]]
local simulator_deps = { "toml++ 1f7884e59165e517462f922e7b6de131bd9844f3" }
local simulator_cli_deps = { "cxxopts", "toml++ 1f7884e59165e517462f922e7b6de131bd9844f3" }
-- local test_deps = { "gtest" }
-- local bench_deps = { "benchmark" }

-- https://github.com/marzer/tomlplusplus/issues/213
add_defines("TOML_RETURN_BOOL_FROM_FOR_EACH_BROKEN=1")
add_defines("TOML_RETURN_BOOL_FROM_FOR_EACH_BROKEN_ACKNOWLEDGED=1")

add_requires(table.unpack(simulator_deps))
add_requires(table.unpack(simulator_cli_deps))
-- add_requires(table.unpack(test_deps))
-- add_requires(table.unpack(bench_deps))


-- [[ Project targets ]]
target("simulator", function()
  set_kind("static")
  add_files("src/simulator/*.cpp", "src/simulator/**/*.cpp")
  add_packages(table.unpack(simulator_deps))
  add_packages("toml++")
end)


target("simulator_cli", function()
  set_kind("binary")
  add_files("src/simulator_cli/*.cpp")
  add_packages(table.unpack(simulator_cli_deps))
  add_deps("simulator")
  add_packages("toml++")
end)

-- target("test", function() end)
--
-- target("bench", function() end)
