// Лабораторная №1. Сборка: c++ -O2 -std=c++17 -pthread main.cpp -o lab1
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>
#if defined(_WIN32)
#define NOMINMAX
#include <windows.h>
#elif defined(__APPLE__) || defined(__linux__)
#include <cerrno>
#include <sys/resource.h>
#include <unistd.h>
#ifdef __APPLE__
#include <pthread.h>
#include <pthread/qos.h>
#else
#include <sys/syscall.h>
#endif
#endif

using Matrix = std::vector<std::int32_t>;
using Result = std::vector<std::int64_t>;
using Clock = std::chrono::steady_clock;

// level: -1 = low, 0 = normal, 1 = high. Меняется только текущий процесс/поток.
bool set_priority(int level, bool process) {
#ifdef _WIN32
    if (process) {
        if (level == 0) return true;
        DWORD value = level < 0 ? BELOW_NORMAL_PRIORITY_CLASS : ABOVE_NORMAL_PRIORITY_CLASS;
        return SetPriorityClass(GetCurrentProcess(), value) && GetPriorityClass(GetCurrentProcess()) == value;
    }
    int value = level < 0 ? THREAD_PRIORITY_BELOW_NORMAL : level > 0 ? THREAD_PRIORITY_ABOVE_NORMAL : THREAD_PRIORITY_NORMAL;
    return SetThreadPriority(GetCurrentThread(), value) && GetThreadPriority(GetCurrentThread()) == value;
#elif defined(__APPLE__) || defined(__linux__)
    id_t id = static_cast<id_t>(getpid());
#ifdef __APPLE__
    if (!process) {
        qos_class_t wanted = level < 0 ? QOS_CLASS_UTILITY : level > 0 ? QOS_CLASS_USER_INITIATED : QOS_CLASS_DEFAULT;
        qos_class_t actual = QOS_CLASS_UNSPECIFIED;
        int relative = 0;
        return pthread_set_qos_class_self_np(wanted, 0) == 0 &&
            pthread_get_qos_class_np(pthread_self(), &actual, &relative) == 0 && actual == wanted && relative == 0;
    }
#else
    if (!process) id = static_cast<id_t>(syscall(SYS_gettid));
#endif
    errno = 0;
    int old = getpriority(PRIO_PROCESS, id);
    if (errno) return false;
    if (level == 0) return true; // Сохраняем унаследованный nice.
    int wanted = std::clamp(old - level * 5, -20, 19);
    if (wanted == old || setpriority(PRIO_PROCESS, id, wanted) != 0) return false;
    errno = 0;
    int actual = getpriority(PRIO_PROCESS, id);
    return errno == 0 && actual == wanted;
#else
    (void)process;
    return level == 0;
#endif
}

// Обычный i-j-k; границы задают прямоугольник результата конкретного потока.
void multiply_block(const Matrix& a, const Matrix& b, Result& c, int n,
                    int r0, int r1, int c0, int c1) {
    for (int i = r0; i < r1; ++i)
        for (int j = c0; j < c1; ++j) {
            std::int64_t sum = 0;
            for (int k = 0; k < n; ++k)
                sum += std::int64_t(a[i * n + k]) * b[k * n + j];
            c[i * n + j] = sum;
        }
}

// Те же элементы C, но обход по столбцам: j-i-k.
void multiply_columns(const Matrix& a, const Matrix& b, Result& c, int n) {
    for (int j = 0; j < n; ++j)
        for (int i = 0; i < n; ++i) {
            std::int64_t sum = 0;
            for (int k = 0; k < n; ++k)
                sum += std::int64_t(a[i * n + k]) * b[k * n + j];
            c[i * n + j] = sum;
        }
}

// Близкая к квадратной сетка: 4 потока -> 2x2, 8 -> 2x4.
int grid_rows(int workers) {
    int rows = 1;
    for (int r = 1; r <= workers / r; ++r)
        if (workers % r == 0) rows = r;
    return rows;
}

bool multiply_parallel(const Matrix& a, const Matrix& b, Result& c, int n,
                       int workers, int level) {
    int rows = grid_rows(workers), cols = workers / rows;
    std::vector<std::thread> threads;
    std::vector<int> priority_ok(workers, 0); // Не vector<bool>: потоки пишут раздельно.
    threads.reserve(workers);
    try {
        for (int t = 0; t < workers; ++t) {
            int r = t / cols, col = t % cols;
            threads.emplace_back([&, t, r, col] {
                priority_ok[t] = set_priority(level, false);
                // Деление с остатком: размеры соседних блоков отличаются не более чем на 1.
                multiply_block(a, b, c, n, r * n / rows, (r + 1) * n / rows,
                               col * n / cols, (col + 1) * n / cols);
            });
        }
    } catch (...) {
        for (auto& thread : threads) thread.join();
        throw;
    }
    // Завершение потока сигнализирует join; главный ждёт всех работников.
    for (auto& thread : threads) thread.join();
    return std::all_of(priority_ok.begin(), priority_ok.end(), [](int ok) { return ok != 0; });
}

template<class F> double measure(F work) {
    auto start = Clock::now();
    work();
    return std::chrono::duration<double>(Clock::now() - start).count();
}

int integer(const char* text) {
    std::size_t end;
    int value = std::stoi(text, &end);
    if (text[end] != '\0') throw std::invalid_argument("Invalid integer");
    return value;
}

int main(int argc, char** argv) {
    try {
        if (argc > 4) throw std::invalid_argument("Usage: lab1 [auto|size] [max_threads] [process_priority: -1/0/1]");
        bool automatic = argc < 2 || std::string(argv[1]) == "auto";
        int n = automatic ? 1025 : integer(argv[1]);
        int max_threads = argc > 2 ? integer(argv[2]) : std::max(1u, std::thread::hardware_concurrency());
        int process_priority = argc > 3 ? integer(argv[3]) : 0;
        if (n < 1 || n > 8192 || max_threads < 1 || max_threads > 256 || process_priority < -1 || process_priority > 1)
            throw std::invalid_argument("size: 1..8192; max_threads: 1..256; priority: -1/0/1");
        if (!set_priority(process_priority, true)) throw std::runtime_error("Process priority unavailable");
        Matrix a, b;
        Result reference, result;
        double base;
        for (;;) {
            std::size_t count = std::size_t(n) * n;
            a.resize(count); b.resize(count); reference.resize(count);
            std::mt19937 random(42);
            for (std::size_t i = 0; i < count; ++i) {
                a[i] = int(random() % 21) - 10;
                b[i] = int(random() % 21) - 10;
            }
            std::cout << "Computing sequential reference, n=" << n << "..." << std::endl;
            base = measure([&] { multiply_block(a, b, reference, n, 0, n, 0, n); });
            std::cout << "Sequential time: " << base << " s" << std::endl;
            if (!automatic || base >= 180.0) break;
            if (n == 8192) throw std::runtime_error("180 s not reached at maximum N; no final results saved");
            n = std::min(8192, n + n / 5 + 1); // Увеличиваем матрицу на 20%, проверяем реальное время.
        }
        result.resize(reference.size());
        std::ofstream csv("results.csv");
        if (!csv) throw std::runtime_error("Cannot write results.csv");
        csv << "n,algorithm,threads,grid,thread_priority,process_priority,seconds,speedup,correct,priority_applied,trial\n";
        csv << std::setprecision(10);
        std::cout << "n=" << n << ", hardware threads=" << std::thread::hardware_concurrency()
                  << ", process priority=" << process_priority << '\n' << std::fixed << std::setprecision(6);
        auto report = [&](const char* name, int workers, int level, double seconds, bool applied) {
            if (result != reference) throw std::runtime_error("Matrix verification failed"); // ВНЕ таймера.
            const char* priority = level < 0 ? "low" : level > 0 ? "high" : "normal";
            int rows = grid_rows(workers);
            std::cout << name << ", threads=" << workers << ", grid=" << rows << 'x' << workers / rows
                      << ", priority=" << priority << ": " << seconds << " s, speedup=" << base / seconds
                      << ", OK" << (applied ? "" : ", PRIORITY NOT APPLIED") << std::endl;
            csv << n << ',' << name << ',' << workers << ',' << rows << 'x' << workers / rows << ','
                << priority << ',' << process_priority << ',' << seconds << ',' << base / seconds
                << ",true," << (applied ? "true" : "false") << ',' << (base < 180.0 ? "true" : "false") << '\n';
        };
        result = reference; // Первый замер задаёт эталон; независимая проверка начинается со следующего.
        report("rows", 1, 0, base, true);
        if (base < 180.0) std::cout << "TRIAL ONLY: below 3 minutes. Run 'lab1 auto' for the lab measurements.\n";
        double seconds = measure([&] { multiply_columns(a, b, result, n); });
        report("columns", 1, 0, seconds, true);
        int last = 1;
        auto parallel_run = [&](int workers, int level) {
            bool applied = false;
            std::cout << "Computing: threads=" << workers << ", priority=" << level << std::endl;
            double time = measure([&] { applied = multiply_parallel(a, b, result, n, workers, level); });
            report("parallel", workers, level, time, applied);
        };
        for (int workers = 1; workers <= std::min(max_threads, n); workers *= 2) {
            parallel_run(workers, 0);
            last = workers;
        }
        parallel_run(last, -1);
        parallel_run(last, 1);
        csv.close();
        if (!csv) throw std::runtime_error("Failed to save results.csv");
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Error: " << error.what() << '\n';
        return 1;
    }
}
