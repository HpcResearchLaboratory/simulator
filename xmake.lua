--[[ Project definitions ]]
set_project("simulator")
set_description("A disease spreading simulator")
set_languages("c++20")


--[[ Project settings ]]
set_toolchains("cuda", "clang")
add_rules("mode.debug", "mode.release", "mode.releasedbg", "plugin.compile_commands.autoupdate")
set_defaultmode("release")
-- set_warnings("all", "error", "allextra")
set_optimize("fastest")
add_includedirs(
  "include",
  "/opt/nvidia/hpc_sdk/Linux_x86_64/2024/cuda/include",
  "/opt/nvidia/hpc_sdk/Linux_x86_64/2024/math_libs/include",
  "/opt/nvidia/hpc_sdk/Linux_x86_64/2024/compilers/include-stdpar/",
  "/opt/nvidia/hpc_sdk/Linux_x86_64/2024/compilers/include-stdexec",
  "./lib/stdexec/include"
)
add_cxxflags("-std=c++20", "-stdpar=gpu", { force = true })
add_ldflags("-L/usr/local/lib", "-L/usr/lib", "-stdpar", { force = true })
add_cugencodes("native")

set_policy("build.optimization.lto", true)
--set_policy("build.warning", true)
-- set_policy("build.merge_archive", true)
--set_policy("package.requires_lock", true)

--add_requires("cmake::NVHPC",
--  {
--    system = true,
--    configs = {
--      envs = {
--        CMAKE_PREFIX_PATH = "/opt/nvidia/hpc_sdk/Linux_x86_64/24.3/cmake/",
--        CMAKE_CXX_FLAGS = "-std=c++23 -stdpar --experimental-stdpar"
--      },
--      components = {
--        "CUDA",
--        "MATH",
--        "HOSTUTILS",
--        "NVSHMEM",
--        "NCCL",
--        "MPI",
--        "PROFILER"
--      },
--      link_libraries = {
--        "NVHPC::CUDA",
--        "NVHPC::MATH",
--        "NVHPC::HOSTUTILS",
--        "NVHPC::NVSHMEM",
--        "NVHPC::NCCL",
--        "NVHPC::MPI",
--        "NVHPC::PROFILER"
--      }
--    }
--  }
--)
--
--add_packages("cmake::NVHPC")


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
