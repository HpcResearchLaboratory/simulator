--[[ Project definitions ]]
set_project("simulator")
set_description("A disease spreading simulator")
set_languages("c++latest")


--[[ Project settings ]]
set_toolchains("cuda", "gcc")
add_rules("mode.debug", "mode.release", "mode.releasedbg", "plugin.compile_commands.autoupdate")
set_defaultmode("release")
-- set_warnings("all", "error", "allextra")
set_optimize("fastest")
add_includedirs("include")
add_cxxflags("-std=c++23", "-stdpar=gpu", { force = true })
add_ldflags("-stdpar=gpu", { force = true })
add_defines("_NVHPC_CUDA", "__NVCOMPILER_CUDA_ARCH__=600", "__pgnu_vsn=130000") -- sm60 is pascal arch

set_policy("build.optimization.lto", true)
set_policy("build.ccache", true)
-- set_policy("build.warning", false)

add_requires("cmake::NVHPC",
  {
    system = true,
    configs = {
      envs = {
        CMAKE_PREFIX_PATH = "/opt/nvidia/hpc_sdk/Linux_x86_64/24.3/cmake/",
        CMAKE_CXX_FLAGS = "-std=c++23 -stdpar --experimental-stdpar"
      },
      components = {
        "CUDA",
        "MATH",
        "HOSTUTILS",
        "NVSHMEM",
        "NCCL",
        -- "MPI",
        "PROFILER"
      },
      link_libraries = {
        "NVHPC::CUDA",
        "NVHPC::MATH",
        "NVHPC::HOSTUTILS",
        "NVHPC::NVSHMEM",
        "NVHPC::NCCL",
        -- "NVHPC::MPI",
        "NVHPC::PROFILER"
      }
    }
  }
)
add_packages("cmake::NVHPC")


-- [[ Project dependencies and repositories ]]
local simulator_deps = { "nlohmann_json", "stdexec" }
local simula_cli_deps = { "nlohmann_json", "stdexec", "argparse", "indicators" };
local bench_deps = { "nlohmann_json", "stdexec", "argparse" }

add_requires(table.unpack(simulator_deps))
add_requires(table.unpack(simula_cli_deps))
-- add_requires(table.unpack(test_deps))
add_requires(table.unpack(bench_deps))


-- [[ options ]]
option("sync", function()
  set_default(false)
  set_showmenu(true)
  set_description("Enable synchronous execution")
  add_defines("SYNC")
end)

option("gpus", function()
  set_default("0,1")
  set_showmenu(true)
  set_description("CUDA_VISIBLE_DEVICES")
end)

option("insertion_cpu", function()
  set_default(false)
  set_showmenu(true)
  set_description("Insertion on CPU")
  add_defines("INSERTION_CPU")
end)

option("movement_cpu", function()
  set_default(false)
  set_showmenu(true)
  set_description("Movement on CPU")
  add_defines("MOVEMENT_CPU")
end)

option("contact_cpu", function()
  set_default(false)
  set_showmenu(true)
  set_description("Contact on CPU")
  add_defines("CONTACT_CPU")
end)

option("transition_cpu", function()
  set_default(false)
  set_showmenu(true)
  set_description("Transition on CPU")
  add_defines("TRANSITION_CPU")
end)

-- [[ Project targets ]]
target("simulator", function()
  set_kind("static")
  add_files("src/simulator/*.cpp", "src/simulator/**/*.cpp")
  add_packages(table.unpack(simulator_deps))
  set_targetdir("./simulator")
  set_installdir("./simulator")
  add_options("sync", "gpus", "insertion_cpu", "movement_cpu", "contact_cpu", "transition_cpu")
  add_runenvs("CUDA_VISIBLE_DEVICES", "$(gpus)")
end)


target("simula_cli", function()
  set_kind("binary")
  add_files("src/simula_cli/*.cpp")
  add_packages(table.unpack(simula_cli_deps))
  add_deps("simulator")
  set_targetdir("./simulator")
  set_installdir("./simulator")
  add_options("sync", "gpus", "insertion_cpu", "movement_cpu", "contact_cpu", "transition_cpu")
  add_runenvs("CUDA_VISIBLE_DEVICES", "$(gpus)")
end)

target("bench", function()
  set_kind("binary")
  add_files("src/bench/*.cpp")
  add_packages(table.unpack(bench_deps))
  add_deps("simulator")
  set_targetdir("./simulator")
  set_installdir("./simulator")
  add_options("sync", "gpus", "insertion_cpu", "movement_cpu", "contact_cpu", "transition_cpu")
  add_runenvs("CUDA_VISIBLE_DEVICES", "$(gpus)")
end)
