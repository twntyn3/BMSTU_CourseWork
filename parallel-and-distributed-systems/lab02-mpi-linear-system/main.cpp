// Лабораторная №2, вариант 2: метод минимальных невязок.
// Сборка: mpicxx -O2 -std=c++17 -Wall -Wextra -pedantic main.cpp -o lab2
#include <mpi.h>
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

// У процесса только его строки A, но входной вектор v хранится полностью.
void multiply(const std::vector<double>& a, const std::vector<double>& v,
              std::vector<double>& result, int n, int rows) {
    for (int i = 0; i < rows; ++i) {
        double sum = 0.0;
        for (int j = 0; j < n; ++j)
            sum += a[static_cast<std::size_t>(i) * n + j] * v[j];
        result[i] = sum;
    }
}

double squared_norm(const std::vector<double>& v) {
    double sum = 0.0;
    for (double value : v) sum += value * value;
    return sum;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int rank, processes;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &processes);

    try {
        if (argc == 2 && std::string(argv[1]) == "--help") {
            if (rank == 0)
                std::cout << "Usage: lab2 [N=1024] [epsilon=1e-5] [mixed|ones]\n"
                          << "mixed: u[i] = sin(2*pi*i/N) + 1e-5; ones: u[i] = 1\n";
            MPI_Finalize();
            return 0;
        }
        if (argc > 4) throw std::invalid_argument("Too many arguments; use --help");
        int n = 1024;
        double epsilon = 1e-5;
        std::size_t end = 0;
        if (argc > 1) {
            n = std::stoi(argv[1], &end);
            if (argv[1][end] != '\0') throw std::invalid_argument("Invalid N");
        }
        if (argc > 2) {
            epsilon = std::stod(argv[2], &end);
            if (argv[2][end] != '\0') throw std::invalid_argument("Invalid epsilon");
        }
        std::string problem = argc > 3 ? argv[3] : "mixed";
        // При N=8192 матрица занимает 512 МиБ на одном процессе.
        if (n < 1 || n > 8192) throw std::invalid_argument("N must be in 1..8192");
        if (!std::isfinite(epsilon) || epsilon <= 0.0 || epsilon >= 1.0)
            throw std::invalid_argument("epsilon must be finite and in (0, 1)");
        if (problem != "mixed" && problem != "ones")
            throw std::invalid_argument("problem must be mixed or ones");

        // Первым N % processes процессам достаётся на одну строку больше.
        std::vector<int> counts(processes), offsets(processes);
        for (int p = 0; p < processes; ++p) {
            counts[p] = n / processes + (p < n % processes ? 1 : 0);
            offsets[p] = p == 0 ? 0 : offsets[p - 1] + counts[p - 1];
        }
        int rows = counts[rank];
        int first = offsets[rank];
        std::vector<double> a(static_cast<std::size_t>(rows) * n);
        std::vector<double> x(n, 0.0), b(n), u(n), y(n);
        std::vector<double> local_y(rows), local_ay(rows);

        // Исходные данные зависят только от глобального индекса и N.
        const double pi = std::acos(-1.0);
        double sum_u = 0.0;
        for (int i = 0; i < n; ++i) {
            u[i] = problem == "ones" ? 1.0 : std::sin(2.0 * pi * i / n) + 1e-5;
            sum_u += u[i];
        }
        // Для выбранной матрицы (A*u)[i] = sum(u) + u[i].
        for (int i = 0; i < n; ++i) b[i] = sum_u + u[i];
        for (int i = 0; i < rows; ++i)
            for (int j = 0; j < n; ++j)
                a[static_cast<std::size_t>(i) * n + j] = first + i == j ? 2.0 : 1.0;
        const double b_norm = std::sqrt(squared_norm(b));
        const double u_norm = std::sqrt(squared_norm(u));
        const int max_iterations = 100000;
        int iterations = 0;

        if (rank == 0)
            std::cerr << "Solving N=" << n << ", processes=" << processes
                      << ", epsilon=" << epsilon << ", problem=" << problem << '\n';
        // Все процессы заканчивают подготовку до начала измерения.
        MPI_Barrier(MPI_COMM_WORLD);
        double start = MPI_Wtime();
        while (true) {
            multiply(a, x, local_y, n, rows);
            for (int i = 0; i < rows; ++i) local_y[i] -= b[first + i];
            // Собираем полный y из частей, размеры которых могут различаться.
            MPI_Allgatherv(local_y.data(), rows, MPI_DOUBLE, y.data(),
                           counts.data(), offsets.data(), MPI_DOUBLE, MPI_COMM_WORLD);
            double relative_residual = std::sqrt(squared_norm(y)) / b_norm;
            if (!std::isfinite(relative_residual))
                throw std::runtime_error("Non-finite residual");
            if (relative_residual < epsilon) break;
            if (iterations == max_iterations)
                throw std::runtime_error("Iteration limit reached");

            multiply(a, y, local_ay, n, rows);
            double local_sums[2] = {0.0, 0.0};
            double global_sums[2];
            for (int i = 0; i < rows; ++i) {
                local_sums[0] += y[first + i] * local_ay[i];
                local_sums[1] += local_ay[i] * local_ay[i];
            }
            // Один общий числитель и знаменатель: каждая строка учтена один раз.
            MPI_Allreduce(local_sums, global_sums, 2, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
            if (!std::isfinite(global_sums[0]) || !std::isfinite(global_sums[1]) ||
                global_sums[1] <= 0.0)
                throw std::runtime_error("Invalid step denominator or numerator");
            double tau = global_sums[0] / global_sums[1];
            for (int i = 0; i < n; ++i) x[i] -= tau * y[i];
            ++iterations;
        }
        double local_seconds = MPI_Wtime() - start;
        double seconds = 0.0;
        // Время решения определяется самым медленным процессом.
        MPI_Reduce(&local_seconds, &seconds, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

        // Независимо пересчитываем невязку и ошибку относительно известного u.
        // Эта проверка выполняется после остановки таймера.
        multiply(a, x, local_y, n, rows);
        double local_checks[2] = {0.0, 0.0};
        double global_checks[2];
        double local_max_error = 0.0, max_error = 0.0;
        for (int i = 0; i < rows; ++i) {
            double residual = local_y[i] - b[first + i];
            double error = x[first + i] - u[first + i];
            local_checks[0] += residual * residual;
            local_checks[1] += error * error;
            local_max_error = std::max(local_max_error, std::abs(error));
        }
        MPI_Allreduce(local_checks, global_checks, 2, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
        MPI_Allreduce(&local_max_error, &max_error, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);
        double residual = std::sqrt(global_checks[0]) / b_norm;
        double relative_error = std::sqrt(global_checks[1]) / u_norm;
        // Для A = I + J: ||x-u|| <= ||A*x-b||. Допуск покрывает округление сумм.
        bool verified = std::isfinite(residual) && std::isfinite(relative_error) &&
                        residual <= epsilon * (1.0 + 1e-9) &&
                        relative_error <= epsilon * b_norm / u_norm * (1.0 + 1e-6);
        if (!verified) throw std::runtime_error("Solution verification failed");

        if (rank == 0) {
            std::cout << "n,epsilon,problem,processes,iterations,seconds,relative_residual,"
                         "relative_error,max_abs_error,verified\n" << std::setprecision(17)
                      << n << ',' << epsilon << ',' << problem << ',' << processes << ','
                      << iterations << ',' << seconds << ',' << residual << ','
                      << relative_error << ',' << max_error << ",true\n";
            if (n <= 10) {
                std::cerr << "x:";
                for (double value : x) std::cerr << ' ' << std::setprecision(10) << value;
                std::cerr << '\n';
            }
        }
        MPI_Finalize();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Process " << rank << ": " << error.what() << '\n';
        MPI_Abort(MPI_COMM_WORLD, 1);
        return 1;
    }
}
