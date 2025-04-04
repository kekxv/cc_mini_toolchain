// main.cc
#include <iostream>
#include <string>
#include <vector>

int main() {
  std::vector<std::string> messages = {"Hello", "from", "custom", "Bazel", "toolchain!"};
  std::cout << "Compiled with C++ Toolchain:" << std::endl;
  for (const std::string& msg : messages) {
    std::cout << "  " << msg;
  }
  std::cout << std::endl;
#ifdef __clang__
  std::cout << "(Looks like Clang)" << std::endl;
#elif __GNUC__
  std::cout << "(Looks like GCC " << __GNUC__ << "." << __GNUC_MINOR__ << ")" << std::endl;
#endif
  return 0;
}