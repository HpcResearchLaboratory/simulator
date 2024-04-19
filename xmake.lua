--[[ Project definitions ]]
set_project("simulator")
set_description("A disease spreading simulator")
set_languages("c++latest")


--[[ Project settings ]]
set_toolchains("cuda")
add_rules("mode.debug", "mode.release", "mode.releasedbg", "plugin.compile_commands.autoupdate")
set_defaultmode("release")
-- set_warnings("all", "error", "allextra")
set_optimize("fastest")
add_includedirs("include")
add_cxxflags("-std=c++23", "-stdpar=gpu", { force = true })
add_ldflags("-stdpar=gpu", { force = true })
add_defines("_NVHPC_CUDA", "__NVCOMPILER_CUDA_ARCH__=600", "__pgnu_vsn=130000", "GLFW_USE_WAYLAND=ON") -- sm60 is pascal arch

set_policy("build.optimization.lto", false)
set_policy("build.ccache", true)
set_policy("build.warning", false)


-- [[ Project dependencies and repositories ]]
local simulator_deps = { "cmake::NVHPC", "nlohmann_json", "stdexec" }
local simula_cli_deps = { "stdexec", "argparse", "indicators" };
local simula_gui_deps = { "imgui" };

add_requireconfs("cmake::NVHPC",
  {
    system = true,
    configs = {
      envs = {
        CMAKE_PREFIX_PATH = "/opt/nvidia/hpc_sdk/Linux_x86_64/24.3/cmake/",
        CMAKE_CXX_FLAGS = "-std=c++23 -stdpar --experimental-stdpar"
      },
      components = {
        "CUDA",
        -- "MATH",
        "HOSTUTILS",
        -- "NVSHMEM",
        -- "NCCL",
        -- "MPI",
        -- "PROFILER"
      },
      link_libraries = {
        "NVHPC::CUDA",
        -- "NVHPC::MATH",
        "NVHPC::HOSTUTILS",
        -- "NVHPC::NVSHMEM",
        -- "NVHPC::NCCL",
        -- "NVHPC::MPI",
        -- "NVHPC::PROFILER"
      }
    }
  }
)


add_requireconfs("glfw", { configs = { glfw_include = "vulkan", wayland = true } })

add_requireconfs("imgui",
  { configs = { defines = { "GLFW_USE_WAYLAND=ON" }, vulkan = true, sdl2 = true, glfw = true, opengl3 = true, wgpu = true, freetype = false }, })

add_requires(table.unpack(simulator_deps))
add_requires(table.unpack(simula_cli_deps))
add_requires(table.unpack(simula_gui_deps))
-- add_requires(table.unpack(test_deps))
-- add_requires(table.unpack(bench_deps))


-- [[ Project targets ]]
target("simulator", function()
  set_kind("static")
  add_files("src/simulator/*.cpp", "src/simulator/**/*.cpp")
  add_packages(table.unpack(simulator_deps))
  -- set_targetdir("./simulator")
  -- set_installdir("./simulator")
end)


target("simula_cli", function()
  set_kind("binary")
  add_files("src/simula_cli/*.cpp")
  add_packages(table.unpack(simula_cli_deps))
  add_deps("simulator")
  -- set_targetdir("./simulator")
  -- set_installdir("./simulator")
end)

target("simula_gui", function()
  set_kind("binary")
  add_files("src/simula_gui/*.cpp")
  add_packages(table.unpack(simula_gui_deps))
  add_deps("simulator")
  -- set_targetdir("./simulator")
  -- set_installdir("./simulator")
end)
