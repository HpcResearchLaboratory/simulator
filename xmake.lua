--[[ Project definitions ]]
set_project("simulator")
set_description("A disease spreading simulator")
set_languages("c++latest")


--[[ Project settings ]]
set_toolchains("cuda", "clang")
add_rules("mode.debug", "mode.release", "mode.releasedbg", "plugin.compile_commands.autoupdate")
set_defaultmode("release")
set_warnings("all", "error", "allextra")
set_optimize("fastest")
add_includedirs("include")
add_cxxflags("-std=c++23", "-stdpar", { force = true })
add_ldflags("-L/usr/local/lib", "-L/usr/lib", "-stdpar", { force = true })

set_policy("build.optimization.lto", true)
set_policy("build.warning", true)
--set_policy("build.merge_archive", true)
--set_policy("package.requires_lock", true)


-- [[ Project dependencies and repositories ]]
local simulator_deps = { "nlohmann_json" }
local simulator_cli_deps = {}

add_requires(table.unpack(simulator_deps))
add_requires(table.unpack(simulator_cli_deps))
-- add_requires(table.unpack(test_deps))
-- add_requires(table.unpack(bench_deps))


-- [[ Project targets ]]
target("simulator", function()
  set_kind("static")
  add_files("src/simulator/*.cpp", "src/simulator/**/*.cpp")
  add_packages(table.unpack(simulator_deps))
end)


target("simulator_cli", function()
  set_kind("binary")
  add_files("src/simulator_cli/*.cpp")
  add_packages(table.unpack(simulator_cli_deps))
  add_deps("simulator")
end)
