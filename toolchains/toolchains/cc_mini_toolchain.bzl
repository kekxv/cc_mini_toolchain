# cc_mini_toolchain.bzl

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    #"compiler_executable",  # Added for potential future flexibility
    "artifact_name_pattern",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")  # If needed for auto-detection

# --- Action Name Constants (Copied from your original file) ---
all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]
dynamic_link_actions = [
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]
executable_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    # ACTION_NAMES.objc_executable, # Removed unless you specifically need Objective-C
]

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    # ACTION_NAMES.clif_match, # Removed unless specifically needed
    ACTION_NAMES.lto_backend,
]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    # ACTION_NAMES.clif_match, # Removed unless specifically needed
]

windows_artifact_name_patterns = [
    artifact_name_pattern(
        category_name = "object_file",
        prefix = "",
        extension = ".obj",
    ),
    artifact_name_pattern(
        category_name = "static_library",
        prefix = "",
        extension = ".lib",
    ),
    artifact_name_pattern(
        category_name = "alwayslink_static_library",
        prefix = "",
        extension = ".lo.lib",
    ),
    artifact_name_pattern(
        category_name = "executable",
        prefix = "",
        extension = ".exe",
    ),
    artifact_name_pattern(
        category_name = "dynamic_library",
        prefix = "lib",
        extension = ".dll",
    ),
    artifact_name_pattern(
        category_name = "interface_library",
        prefix = "",
        extension = ".if.lib",
    ),
]
# --- Private Rule Implementation for cc_toolchain_config ---

def _cc_mini_toolchain_config_impl(ctx):
    """Implementation function for the cc_toolchain_config rule."""

    tool_paths = [
        tool_path(name = name, path = path)
        for name, path in ctx.attr.tool_paths_dict.items()
    ]

    # Optional Sysroot Flags
    sysroot_flags = []
    if ctx.attr.sysroot:
        sysroot_flags = ["--sysroot=" + ctx.attr.sysroot]

    # Feature: Default Compiler Flags (C and C++)
    compiler_flags_feature = feature(
        name = "default_compiler_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(flags = sysroot_flags + ctx.attr.compiler_flags),
                ],
            ),
        ],
    )

    # Feature: Default C++ Compiler Flags
    cpp_flags_feature = feature(
        name = "default_cpp_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = [
                    flag_group(flags = sysroot_flags + ctx.attr.cpp_flags),
                ],
            ),
        ],
    )

    features_flag_sets = []
    if ctx.attr.linker_flags:
        features_flag_sets.append(flag_set(
            actions = all_link_actions,
            flag_groups = ([
                flag_group(flags = sysroot_flags + ctx.attr.linker_flags),
            ]),
        ))
    if ctx.attr.executable_linking_flags:
        features_flag_sets.append(
            flag_set(
                actions = executable_link_actions,
                flag_groups = ([
                    flag_group(flags = ctx.attr.executable_linking_flags),
                ]),
            ),
        )
    if ctx.attr.dynamic_library_linking_flags:
        features_flag_sets.append(
            flag_set(
                actions = dynamic_link_actions,
                flag_groups = ([
                    flag_group(flags = ctx.attr.dynamic_library_linking_flags),
                ]),
                # Ensure this doesn't conflict if dynamic_library_linking_flags is empty
                #enabled = bool(ctx.attr.dynamic_library_linking_flags),
            ),
        )

    # Feature: Default Linker Flags
    linker_flags_feature = feature(
        name = "default_linker_flags",
        enabled = True,
        flag_sets = features_flag_sets,
    )

    features = [
        compiler_flags_feature,
        cpp_flags_feature,
        linker_flags_feature,
    ]

    # Add features based on attributes
    if ctx.attr.supports_pic:
        features.append(feature(name = "supports_pic", enabled = True))

    # TODO: Add more features based on attributes as needed (e.g., static_linking_mode, dynamic_linking_mode)

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        artifact_name_patterns = windows_artifact_name_patterns if ctx.attr.target_system_name == "windows" else [],
        # Assume includes are handled by sysroot or compiler wrappers for simplicity now
        cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = ctx.attr.host_system_name,
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.target_cpu,
        target_libc = ctx.attr.target_libc,
        compiler = ctx.attr.compiler,
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        tool_paths = tool_paths,
        # Optional: Add compiler_executable attribute if needed
        # compiler_executable = compiler_executable(path=ctx.executable.compiler_executable.path), # Example
    )

# --- Private Rule Definition for cc_toolchain_config ---

_cc_mini_toolchain_config = rule(
    implementation = _cc_mini_toolchain_config_impl,
    attrs = {
        "tool_paths_dict": attr.string_dict(mandatory = True),
        "toolchain_identifier": attr.string(mandatory = True),
        "host_system_name": attr.string(mandatory = True),
        "target_system_name": attr.string(mandatory = True),
        "target_cpu": attr.string(mandatory = True),
        "target_libc": attr.string(mandatory = True),
        "compiler": attr.string(mandatory = True),
        "abi_version": attr.string(mandatory = True),
        "abi_libc_version": attr.string(mandatory = True),
        "sysroot": attr.string(),  # Optional path to the sysroot
        "compiler_flags": attr.string_list(),
        "cpp_flags": attr.string_list(),
        "linker_flags": attr.string_list(),
        "executable_linking_flags": attr.string_list(),
        "dynamic_library_linking_flags": attr.string_list(),
        "cxx_builtin_include_directories": attr.string_list(),
        "supports_pic": attr.bool(default = True),  # Default based on your original flags
        # "_compiler_executable": attr.label( # Example if using compiler_executable
        #     executable = True,
        #     cfg = "exec",
        #     allow_files = True,
        # ),
    },
    provides = [CcToolchainConfigInfo],
)

# --- Public Macro to define the toolchain ---

def cc_mini_toolchain(
        name,
        platform,  # A dictionary mapping tool names (target_cpu, target_os, host_os, host_cpu.)
        compiler = "gcc",  # Common default, adjust as needed
        target_libc = "unknown",  # Default from your original code
        abi_version = "unknown",  # Default from your original code
        abi_libc_version = "unknown",  # Default from your original code
        exec_constraints = None,  # e.g., ["@platforms//os:linux", "@platforms//cpu:x86_64"]
        target_constraints = None,  # e.g., ["@platforms//os:linux", "@platforms//cpu:x86_64"]
        tool_paths_dict = None,  # Mandatory: Dict like {"gcc": "path/to/gcc", "ld": "path/to/ld", ...}
        all_files = None,  # Mandatory: Label pointing to a filegroup with all toolchain files
        compiler_files = None,  # Optional: defaults to all_files
        linker_files = None,  # Optional: defaults to all_files
        strip_files = None,  # Optional: defaults to all_files
        objcopy_files = None,  # Optional: defaults to all_files
        ar_files = None,  # Optional: defaults to all_files
        dwp_files = ":empty",  # Often empty
        coverage_files = None,  # Optional: defaults to all_files
        sysroot = None,  # Optional: Path to sysroot relative to execution root (e.g., "external/my_sysroot")
        compiler_flags = [],
        cpp_flags = [],
        linker_flags = [],
        executable_linking_flags = [],
        dynamic_library_linking_flags = [],
        cxx_builtin_include_directories = [],
        supports_pic = False,
        **kwargs):  # Pass extra arguments to native.toolchain if needed
    """
    Defines a C/C++ toolchain using a simplified configuration.

    Args:
      name: The base name for the toolchain rules.
      platform: A dictionary mapping tool names (target_cpu, target_os, host_os, host_cpu.)
                target_cpu: The target CPU architecture (e.g., "k8", "x86_64", "aarch64").
                target_os: The target operating system (e.g., "linux", "macos", "windows").
                host_os: The host operating system (e.g., "linux", "macos", "windows").
                host_cpu: The host CPU architecture (e.g., "k8", "x86_64", "aarch64").
      compiler: The compiler type (e.g., "gcc", "clang").
      target_libc: The target C library (e.g., "glibc", "musl", "unknown").
      abi_version: The ABI version (often "unknown").
      abi_libc_version: The ABI's libc version (often "unknown").
      exec_constraints: Execution platform constraints for the toolchain rule.
      target_constraints: Target platform constraints for the toolchain rule.
      tool_paths_dict: A dictionary mapping tool names (gcc, ld, ar, etc.) to their
                       paths relative to the package (or absolute labels).
      all_files: A label pointing to a filegroup containing all necessary toolchain files
                 (compiler, linker, libraries, headers, wrappers, sysroot parts, etc.).
      compiler_files: Label for compiler-specific files (defaults to all_files).
      linker_files: Label for linker-specific files (defaults to all_files).
      strip_files: Label for strip files (defaults to all_files).
      objcopy_files: Label for objcopy files (defaults to all_files).
      ar_files: Label for ar files (defaults to all_files).
      dwp_files: Label for dwp files (defaults to ":empty"). Use ":empty" from //toolchains/cpp:empty_filegroup if needed globally.
      coverage_files: Label for coverage files (defaults to all_files).
      sysroot: Optional path to the sysroot, relative to the execution root.
               Flags like --sysroot=<path> will be added automatically.
      compiler_flags: List of flags applied to all C/C++ compile actions.
      cpp_flags: List of flags applied specifically to C++ compile actions.
      linker_flags: List of flags applied to all link actions.
      executable_linking_flags: List of flags applied only when linking executables.
      dynamic_library_linking_flags: List of flags applied only when linking dynamic libraries.
      cxx_builtin_include_directories: List of C++ built-in include directories. Usually
                                      handled by sysroot or compiler wrappers.
      supports_pic: Whether the toolchain supports Position Independent Code (PIC).
      **kwargs: Additional arguments passed to the native.toolchain rule.
    """

    if not tool_paths_dict:
        fail("Parameter 'tool_paths_dict' is mandatory.")
    if not all_files:
        fail("Parameter 'all_files' is mandatory.")
    if not platform:
        fail("Parameter 'platform' is mandatory.")

    target_cpu = platform.get("target_cpu", "x86_64")
    host_os = platform.get("host_os", "linux")
    host_cpu = platform.get("host_cpu", "x86_64")
    target_os = platform.get("target_os", "linux")
    if not exec_constraints:
        #fail("Parameter 'exec_constraints' is mandatory for platform-based toolchain resolution.")
        exec_constraints = []
        if host_os == "linux":
            exec_constraints.append("@platforms//os:linux")
        elif host_os == "macos":
            exec_constraints.append("@platforms//os:macos")
        elif host_os == "windows":
            exec_constraints.append("@platforms//os:windows")
        if host_cpu == "arm":
            exec_constraints.append("@platforms//cpu:arm")
        elif host_cpu == "x86_64":
            exec_constraints.append("@platforms//cpu:x86_64")
        elif host_cpu == "mips64":
            exec_constraints.append("@platforms//cpu:mips64")
        elif host_cpu == "arm64":
            exec_constraints.append("@platforms//cpu:arm64")
        elif host_cpu == "s390x":
            exec_constraints.append("@platforms//cpu:s390x")
        elif host_cpu == "riscv64":
            exec_constraints.append("@platforms//cpu:riscv64")
        elif host_cpu == "riscv32":
            exec_constraints.append("@platforms//cpu:riscv32")
        elif host_cpu == "aarch32":
            exec_constraints.append("@platforms//cpu:aarch32")
        elif host_cpu == "aarch64":
            exec_constraints.append("@platforms//cpu:aarch64")
        elif host_cpu == "armv7":
            exec_constraints.append("@platforms//cpu:armv7")
        elif host_cpu == "i386":
            exec_constraints.append("@platforms//cpu:i386")
        elif host_cpu == "x86_32":
            exec_constraints.append("@platforms//cpu:x86_32")
        elif host_cpu == "wasm32":
            exec_constraints.append("@platforms//cpu:wasm32")
        elif host_cpu == "wasm64":
            exec_constraints.append("@platforms//cpu:wasm64")

        # 判断 target_constraints 是否是空数组
        if exec_constraints == []:
            fail("Parameter 'exec_constraints' is mandatory for platform-based toolchain resolution.")

    if not target_constraints:
        #fail("Parameter 'target_constraints' is mandatory for platform-based toolchain resolution.")
        target_constraints = []
        if target_os == "linux":
            target_constraints.append("@platforms//os:linux")
        elif target_os == "macos":
            target_constraints.append("@platforms//os:macos")
        elif target_os == "windows":
            target_constraints.append("@platforms//os:windows")
        elif target_os == "android":
            target_constraints.append("@platforms//os:android")
        elif target_os == "ios":
            target_constraints.append("@platforms//os:ios")
        elif target_os == "freebsd":
            target_constraints.append("@platforms//os:freebsd")
        elif target_os == "openbsd":
            target_constraints.append("@platforms//os:openbsd")
        if target_cpu == "arm":
            target_constraints.append("@platforms//cpu:arm")
        elif target_cpu == "x86_64":
            target_constraints.append("@platforms//cpu:x86_64")
        elif target_cpu == "mips64":
            target_constraints.append("@platforms//cpu:mips64")
        elif target_cpu == "arm64":
            target_constraints.append("@platforms//cpu:arm64")
        elif target_cpu == "s390x":
            target_constraints.append("@platforms//cpu:s390x")
        elif target_cpu == "riscv64":
            target_constraints.append("@platforms//cpu:riscv64")
        elif target_cpu == "riscv32":
            target_constraints.append("@platforms//cpu:riscv32")
        elif target_cpu == "aarch32":
            target_constraints.append("@platforms//cpu:aarch32")
        elif target_cpu == "aarch64":
            target_constraints.append("@platforms//cpu:aarch64")
        elif target_cpu == "armv7":
            target_constraints.append("@platforms//cpu:armv7")
        elif target_cpu == "i386":
            target_constraints.append("@platforms//cpu:i386")
        elif target_cpu == "x86_32":
            target_constraints.append("@platforms//cpu:x86_32")
        elif target_cpu == "wasm32":
            target_constraints.append("@platforms//cpu:wasm32")
        elif target_cpu == "wasm64":
            target_constraints.append("@platforms//cpu:wasm64")

        # 判断 target_constraints 是否是空数组
        if target_constraints == []:
            fail("Parameter 'target_constraints' is mandatory for platform-based toolchain resolution.")

    config_name = name + "_config"
    cc_toolchain_name = name + "_cc_toolchain"
    cc_toolchain_identifier_name = name + "_cc-toolchain_identifier"

    # Create an empty filegroup if needed in the current package
    native.filegroup(
        name = "empty",
        srcs = [],
        visibility = ["//visibility:private"],  # Keep it private to this package
    )

    # Instantiate the private rule to create the CcToolchainConfigInfo provider
    _cc_mini_toolchain_config(
        name = config_name,
        tool_paths_dict = tool_paths_dict,
        toolchain_identifier = cc_toolchain_identifier_name,
        host_system_name = host_os,
        target_system_name = target_os,
        target_cpu = target_cpu,
        target_libc = target_libc,
        compiler = compiler,
        abi_version = abi_version,
        abi_libc_version = abi_libc_version,
        sysroot = sysroot,
        compiler_flags = compiler_flags,
        cpp_flags = cpp_flags,
        linker_flags = linker_flags,
        executable_linking_flags = executable_linking_flags,
        dynamic_library_linking_flags = dynamic_library_linking_flags,
        cxx_builtin_include_directories = cxx_builtin_include_directories,
        supports_pic = supports_pic,
    )

    # Define the cc_toolchain rule
    native.cc_toolchain(
        name = cc_toolchain_name,
        toolchain_identifier = cc_toolchain_identifier_name,  # Must match the config
        toolchain_config = ":" + config_name,
        all_files = all_files,
        compiler_files = compiler_files if compiler_files else all_files,
        linker_files = linker_files if linker_files else all_files,
        strip_files = strip_files if strip_files else all_files,
        objcopy_files = objcopy_files if objcopy_files else all_files,
        ar_files = ar_files if ar_files else all_files,
        dwp_files = dwp_files,
        coverage_files = coverage_files if coverage_files else all_files,
        # Add other attributes like static_runtime_libs, dynamic_runtime_libs if needed
    )

    # Define the toolchain rule for platform mapping
    native.toolchain(
        name = name,
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
        exec_compatible_with = exec_constraints,
        target_compatible_with = target_constraints,
        toolchain = ":" + cc_toolchain_name,
        **kwargs  # Pass visibility, licenses, etc.
    )
