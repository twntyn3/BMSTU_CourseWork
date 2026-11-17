#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <mutex>
#include <random>
#include <string>
#include <thread>
#include <vector>

using namespace std;
using Clock = chrono::steady_clock;
using Ms = chrono::milliseconds;

// общие данные программы
int n = 5;
double seconds = 10;
string folder = "run5";
vector<timed_mutex> forks;
vector<string> fellow;
vector<int> meals;
mutex log_mutex, wait_mutex;
condition_variable wake;
atomic<bool> stop{false};
bool started = false;
int ready = 0, sequence = 0;
Clock::time_point start_time, deadline;
ofstream log_file;

// время и журнал событий
long long elapsed() {
    return chrono::duration_cast<chrono::nanoseconds>(Clock::now() - start_time).count();
}


long long record(int p, const string& event, int fork = -1) {
    auto time = elapsed();
    log_file << sequence++ << ',' << time << ',' << p << ','
             << (p < 0 ? "" : fellow[p]) << ',' << event << ',' << fork << '\n';
    return time;
}

void change(int p, const string& state) {
    lock_guard<mutex> guard(log_mutex);
    fellow[p] = state;
    record(p, "state");
}

// проверка остановки и задержки
bool running() {
    return !stop && Clock::now() < deadline;
}

// Все задержки заканчиваются не позже дедлайна
bool pause(int milliseconds) {
    unique_lock<mutex> guard(wait_mutex);
    wake.wait_until(guard, min(deadline, Clock::now() + Ms(milliseconds)), [] { return stop.load(); });
    return running();
}

// взятие одной вилки
bool take(int p, int fork, unique_lock<timed_mutex>& lock, int delay) {
    if (!running()) return false;
    change(p, fork == p ? "taking_left" : "taking_right");
    while (running()) {
        // блокируем только одну вилку
        if (lock.try_lock_until(min(deadline, Clock::now() + Ms(2)))) {
            {
                lock_guard<mutex> guard(log_mutex);
                record(p, "acquire", fork);
            }
            return pause(delay);
        }
    }
    return false;
}

// подготовка потока философа
void philosopher(int p) {
    {
        unique_lock<mutex> guard(wait_mutex);
        ++ready;
        wake.notify_all();
        wake.wait(guard, [] { return started || stop.load(); });
        if (stop) return;
    }
    mt19937 random(42 + p);
    auto delay = [&](int low, int high) {
        return uniform_int_distribution<int>(low, high)(random);
    };
    int left = p, right = (p + 1) % n;
    int a = min(left, right), b = max(left, right);

    // основной цикл философа: размышление, взятие вилок и еда
    while (running()) {
        if (!pause(delay(20, 80))) break;
        unique_lock<timed_mutex> first(forks[a], defer_lock);
        unique_lock<timed_mutex> second(forks[b], defer_lock);
        
        if (take(p, a, first, delay(2, 8)) && take(p, b, second, delay(2, 8)) && running()) {
            change(p, "eating");
            if (pause(delay(20, 60))) {
                lock_guard<mutex> guard(log_mutex);
                ++meals[p];
                record(p, "meal");
            }
        }
        // возврат вилок и завершение философа
        if (first.owns_lock() || second.owns_lock()) {
            change(p, "putting");
            pause(delay(2, 5));
            lock_guard<mutex> guard(log_mutex);
            if (second.owns_lock()) second.unlock();
            if (first.owns_lock()) first.unlock();
            record(p, "release");
        }
        change(p, "thinking");
    }
    lock_guard<mutex> guard(log_mutex);
    record(p, "finished");
}

// начало main и параметры запуска
int main(int argc, char** argv) {
    try {
        if (argc == 2 && string(argv[1]) == "--help") {
            cout << "Запуск: ./lab3 [число философов=5] [секунды=10] [папка=run5]\n"
                 << "Пример: ./lab3 8 5 run8\nФайлы в выбранной папке перезаписываются.\n";
            return 0;
        }
        if (argc > 4) throw runtime_error("Слишком много аргументов. Используйте --help.");
        // stod и stoi должны прочитать аргумент целиком
        size_t end;
        if (argc > 1) {
            n = stoi(argv[1], &end);
            if (argv[1][end] != '\0') throw runtime_error("Число философов должно быть целым.");
        }
        if (argc > 2) {
            seconds = stod(argv[2], &end);
            if (argv[2][end] != '\0') throw runtime_error("Неверное время работы.");
        }
        if (n < 2) throw runtime_error("Нужно минимум два философа и две разные вилки.");
        if (!isfinite(seconds) || seconds <= 0 || seconds > 86400)
            throw runtime_error("Время должно быть больше нуля и не больше 86400 секунд.");
        if (argc > 3) folder = argv[3];
        // подготовка файлов и создание потоков
        filesystem::create_directories(folder);
        log_file.open(folder + "/events.csv");
        if (!log_file) throw runtime_error("Не удалось открыть журнал для записи.");
        log_file << "seq,time_ns,philosopher,state,event,fork\n";
        forks = vector<timed_mutex>(n);
        fellow.assign(n, "thinking");
        meals.assign(n, 0);
        vector<thread> threads;
        threads.reserve(n);
        try {
            for (int p = 0; p < n; ++p) threads.emplace_back(philosopher, p);
        } catch (...) {
            { lock_guard<mutex> guard(wait_mutex); stop = true; }
            wake.notify_all();
            for (auto& thread : threads) thread.join();
            throw runtime_error("Не удалось создать потоки. Уменьшите число философов.");
        }
        // общий старт
        {
            unique_lock<mutex> guard(wait_mutex);
            wake.wait(guard, [] { return ready == n; });
            start_time = Clock::now();
            deadline = start_time + chrono::duration_cast<Clock::duration>(chrono::duration<double>(seconds));
            for (int p = 0; p < n; ++p)
                log_file << sequence++ << ",0," << p << ",thinking,initial,-1\n";
            started = true;
        }
        wake.notify_all();
        // остановка и ожидание завершения
        this_thread::sleep_until(deadline);
        long long stop_ns;
        {
            lock_guard<mutex> guard(log_mutex);
            { lock_guard<mutex> wait_guard(wait_mutex); stop = true; }
            stop_ns = record(-1, "stop_requested");
        }
        wake.notify_all();
        for (auto& thread : threads) thread.join();
        long long end_ns = record(-1, "all_joined");
        log_file.close();
        // сохранение итогов
        ofstream info(folder + "/config.csv"), summary(folder + "/meals.csv");
        info << "n,seconds,seed,think_min_ms,think_max_ms,eat_min_ms,eat_max_ms,"
                "take_min_ms,take_max_ms,put_min_ms,put_max_ms,stop_ns,end_ns\n"
             << n << ',' << seconds << ",42,20,80,20,60,2,8,2,5," << stop_ns << ',' << end_ns << '\n';
        summary << "philosopher,completed_meals\n";
        for (int p = 0; p < n; ++p) {
            summary << p << ',' << meals[p] << '\n';
            cout << "Философ " << p << ": закончено приёмов пищи — " << meals[p] << '\n';
        }
        info.close(); summary.close();
        if (!log_file || !info || !summary) throw runtime_error("Ошибка записи результатов на диск.");
        cout << "Все потоки завершены, вилки освобождены. Результаты: " << folder << '\n';
    // обработка ошибок
    } catch (const invalid_argument&) {
        cerr << "Ошибка: вместо числа введён текст. Используйте --help.\n";
        return 1;
    } catch (const out_of_range&) {
        cerr << "Ошибка: введено слишком большое число.\n";
        return 1;
    } catch (const filesystem::filesystem_error&) {
        cerr << "Ошибка: не удалось создать папку результатов.\n";
        return 1;
    } catch (const runtime_error& error) {
        cerr << "Ошибка: " << error.what() << '\n';
        return 1;
    } catch (const exception&) {

        cerr << "Ошибка выполнения. Проверьте параметры, доступность папки и ресурсы компьютера.\n";
        return 1;
    }
}
