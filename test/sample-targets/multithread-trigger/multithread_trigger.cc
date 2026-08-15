#include <chrono>
#include <iostream>
#include <thread>

extern "C" {
void __attribute__((noinline)) __attribute__((used))
magic_trace_stop_indicator() {}
}

int main() {
  std::cout << "ready" << std::endl;

  // Give magic-trace time to attach before creating the worker thread.
  std::this_thread::sleep_for(std::chrono::milliseconds(500));

  std::thread worker([] {
    // Keep the thread alive long enough for /proc/<pid>/task rescanning
    // to discover it and arm a breakpoint.
    std::this_thread::sleep_for(std::chrono::milliseconds(250));
    magic_trace_stop_indicator();
    std::this_thread::sleep_for(std::chrono::milliseconds(250));
  });

  worker.join();
  return 0;
}
