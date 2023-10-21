--[[ Project definitions ]]
set_project("simulator")
set_version("0.1.0")
set_description("A disease spreading simulator")
set_languages("c++23")
set_license("MIT")
set_xmakever("2.8.2")

--[[ Project settings ]]
add_rules("mode.debug", "mode.release", "mode.releasedbg", "plugin.compile_commands.autoupdate")
set_defaultmode("releasedbg")
-- set_allowedplats("linux", "macosx", "windows")
-- set_allowedarchs("x64", "x86")
set_allowedmodes("release", "debug", "releasedbg")
-- set_warnings("all", "error")
-- set_optimize("fastest")
add_includedirs("include", "/usr/local/include", "/usr/include")
-- add_cxxflags("-Wall", "-Wextra", "-Werror", "-Wpedantic", { force = true })
-- add_asflags("")
-- add_ldflags("-L/usr/local/lib", "-L/usr/lib")
-- add_shflags("")
-- add_arflags(""
-- set_policy("build.optimization.lto", true)
-- set_policy("build.warning", true)
-- set_warnings("allextra")
-- set_policy("build.merge_archive", true)
set_policy("package.requires_lock", true)

-- platform specific settings
-- if is_plat("linux") then
-- 	set_toolchains("clang")
-- elseif is_plat("macosx") then
-- 	set_toolchains("clang")
-- elseif is_plat("windows") then
-- 	set_toolchains("msvc")
-- end

-- [[ Project dependencies and repositories ]]
-- add_repositories("hpc_research_laboratory  https://github.com/HpcResearchLaboratory/repo.git main")

local simulator_deps = { "thrust" }
-- local test_deps = { "gtest" }
-- local bench_deps = { "benchmark" }

-- add_requires(table.unpack(shared_lib_deps))
-- add_requires(table.unpack(static_lib_deps))
-- add_requires(table.unpack(app_deps))
-- add_requires(table.unpack(test_deps))
-- add_requires(table.unpack(bench_deps))

-- [[ Project targets ]]
target("gpu", function()
	set_kind("binary")
	add_files("src/simulator/*.cu", "src/simulator/**/*.cu", "src/main.cu")

	-- compatibility
	add_cugencodes("native")
	add_cugencodes("compute_50")
end)

-- target("cpu", function()
--   set_kind("binary")
--   add_files("src/main.cpp")
-- end)

-- target("test", function() end)
--
-- target("bench", function() end)
