# Load the new macro
load("//toolchains/toolchains:cc_mini_toolchain.bzl", "cc_mini_toolchain")

filegroup(
    name = "wrappers",
    srcs = glob(["wrappers/**"]),
)

filegroup(
    name = "toolchain_all_files",  # Renamed for clarity
    srcs = [
        ":wrappers",
        "@gcc-armv7l-linux-ulibc-luckfox//:toolchain",  # Assuming this provides headers/libs/sysroot components
    ],
)

cc_mini_toolchain(
    # Base name for the toolchain rules (toolchain, cc_toolchain, config)
    name = "toolchains",  # Choose a descriptive name
    # --- File Dependencies ---
    all_files = ":toolchain_all_files",
    compiler = "gcc",  # Assuming wrappers ultimately call gcc
    # sysroot = "external/glibc-linux-gnu-x86_64/x86_64-buildroot-linux-gnu/sysroot", # Example if needed

    # --- Flags (Extracted from your original features) ---
    compiler_flags = [
        "-no-canonical-prefixes",
        "-fno-canonical-system-headers",
        "-Wno-builtin-macro-redefined",
        "-D__DATE__=\"redacted\"",
        "-D__TIMESTAMP__=\"redacted\"",
        "-D__TIME__=\"redacted\"",
        "-fPIC",
    ],
    cpp_flags = [
        # C++ specific flags (will be appended to compiler_flags for C++ actions)
        "-std=c++17",
    ],
    dynamic_library_linking_flags = [
        "-shared",
    ],
    executable_linking_flags = [
        "-static",
    ],
    linker_flags = [
        "-lstdc++",
    ],
    platform = {
        "host_cpu": "x86_64",
        "host_os": "linux",
        "target_cpu": "armv7",  # Adjusted to a more standard Bazel CPU value
        "target_os": "linux",
    },
    supports_pic = True,  # Based on your -fPIC flag
    target_libc = "glibc",  # Be more specific if known, else keep "unknown"

    # --- Tool Paths (Relative to this package) ---
    tool_paths_dict = {
        "gcc": "wrappers/gcc",
        "ld": "wrappers/ld",
        "cpp": "wrappers/g++",  # Often same as gcc, but separate entry is fine
        "ranlib": "wrappers/ranlib",
        "nm": "wrappers/nm",
        "objdump": "wrappers/objdump",
        "objcopy": "wrappers/objcopy",
        "ar": "wrappers/ar",
        "strip": "wrappers/strip",
        # Add "gcov" or other toolchains if needed
    },

    # Pass visibility if needed for the final 'toolchain' rule
    visibility = ["//visibility:public"],
)
