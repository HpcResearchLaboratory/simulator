--[[ Project definitions ]]
set_project("simulator")
set_version("0.1.0")
set_description("A disease spreading simulator")
set_languages("c++latest")
set_license("MIT")
set_xmakever("2.8.5")

--[[ Project settings ]]
set_toolchains("cuda")
add_rules("mode.debug", "mode.release", "mode.releasedbg", "plugin.compile_commands.autoupdate")
set_defaultmode("release")
-- set_allowedplats("linux", "macosx", "windows")
-- set_allowedarchs("x64", "x86")
set_allowedmodes("release", "debug", "releasedbg")
-- set_warnings("all", "error", "allextra")
set_optimize("fastest")
add_includedirs("include", "/usr/local/include", "/usr/include")
add_cxxflags("-Wall", "-Wextra", "-Werror", "-Wpedantic", "-std=c++20", "-stdpar", { force = true })
-- add_asflags("")
add_ldflags("-L/usr/local/lib", "-L/usr/lib", "-ltbb", { force = true })
-- add_shflags("")
-- add_arflags(""
set_policy("build.optimization.lto", true)
set_policy("build.warning", true)
set_policy("build.merge_archive", true)
set_policy("package.requires_lock", true)

-- [[ Project dependencies and repositories ]]
local simulator_deps = { "thrust", "toml++" }
local simulator_cli_deps = { "cxxopts", "toml++" }
-- local test_deps = { "gtest" }
-- local bench_deps = { "benchmark" }

add_requires(table.unpack(simulator_deps))
add_requires(table.unpack(simulator_cli_deps))
-- add_requires(table.unpack(static_lib_deps))
-- add_requires(table.unpack(app_deps))
-- add_requires(table.unpack(test_deps))
-- add_requires(table.unpack(bench_deps))

-- [[ Project targets ]]
target("simulator", function()
	set_kind("static")
	add_files("src/simulator/*.cu", "src/simulator/**/*.cu")
	add_packages(table.unpack(simulator_deps))
	-- https://github.com/marzer/tomlplusplus/issues/213
	add_defines("TOML_RETURN_BOOL_FROM_FOR_EACH_BROKEN=1")
	add_defines("TOML_RETURN_BOOL_FROM_FOR_EACH_BROKEN_ACKNOWLEDGED=1")

	-- compatibility
	-- add_cugencodes("native")
	-- add_cugencodes("compute_50")
end)

-- xmake config --use_openmp=false
option("use_openmp", function()
	set_default(false)
	set_showmenu(true)
	set_description("Use OpenMP for the simulator_cli target")
end)

target("simulator_cli", function()
	set_kind("binary")
	add_files("src/simulator_cli/*.cu", "src/simulator_cli/**/*.cu")
	add_deps("simulator")
	add_packages(table.unpack(simulator_cli_deps))

	-- I want a way to specify an option to add this line conditionally
	-- add_cxxflags("-Xcompiler -fopenmp -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_OMP -lgomp")
	if has_config("use_openmp") then
		add_cxxflags("-Xcompiler -fopenmp -DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_OMP -lgomp")
	end
end)

-- target("test", function() end)
--
-- target("bench", function() end)
