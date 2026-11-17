#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <dirent.h>
#include <algorithm>
#include <random>
#include <cctype>

using namespace std;

// перемешиваем средние буквы
string shuffleMiddle(string word) {
    if (word.length() <= 3) return word;

    //удаляем небуквенные символы с начала и конца
    string prefix = "", suffix = "";
    while (!word.empty() && !isalnum(word.front())) {
        prefix += word.front();
        word.erase(word.begin());
    }
    while (!word.empty() && !isalnum(word.back())) {
        suffix = word.back() + suffix;
        word.pop_back();
    }

    if (word.length() <= 3) return prefix + word + suffix;
    //перемешивание средней части
    string middle = word.substr(1, word.length() - 2);
    static random_device rd;
    static mt19937 g(rd());
    shuffle(middle.begin(), middle.end(), g);
    //билдим слово
    return prefix + word.front() + middle + word.back() + suffix;
}

// проверка на  .txt
bool isTxtFile(const string& name) {
    return name.size() > 4 && name.substr(name.size() - 4) == ".txt";
}
// открываем и выводим содержимое файла на экран
void printFile(const string& filename) {
    ifstream f(filename);
    if (!f.is_open()) {
        cerr << "Ошибка открытия файла " << filename << " для чтения.\n";
        return;
    }

    cout << "\n" << filename << " (результат)\n";
    string line;
    while (getline(f, line)) {
        cout << line << endl;
    }
    f.close();
}

int main(int argc, char* argv[]) {

    //открытие директории
    string folder = argv[1];
    DIR* dir = opendir(folder.c_str());
    if (!dir) {
        cerr << "Не удалось открыть каталог: " << folder << endl;
        return 1;
    }

    dirent* entry;
    //обходим все файлы
    while ((entry = readdir(dir)) != nullptr) {
        string filename = entry->d_name;
        if (isTxtFile(filename)) {//если тхт то читаем и записываем
            string fullpath = folder + "/" + filename;
            ifstream in(fullpath);
            ofstream out(filename);

            if (!in.is_open() || !out.is_open()) {
                cerr << "Ошибка открытия файла: " << filename << endl;
                continue;
            }

            string line;
            while (getline(in, line)) {
                istringstream iss(line);
                string word;
                while (iss >> word) {
                    out << shuffleMiddle(word) << " ";
                }
                out << endl;
            }
            // закрытие и вывод
            in.close();
            out.close();

            printFile(filename);
        }
    }
    //закрыли каталаг
    closedir(dir);
    return 0;
}


//./lab12 test_texts
