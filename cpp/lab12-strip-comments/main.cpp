#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <dirent.h>
#include <sys/stat.h>

using namespace std;

// удаление сех комментариев
string stripComments(const string& src) {
    string out;
    enum State { NORMAL, SLASH, LINE_C, BLOCK_C, BLOCK_STAR } st = NORMAL;
    //по символам по
    for (size_t i = 0; i < src.size(); ++i) {
        char c = src[i];
        switch (st) {
            case NORMAL:
                if (c == '/') st = SLASH;
                else out += c;
                break;
            case SLASH:
                if (c == '/') {
                    st = LINE_C;
                } else if (c == '*') {
                    st = BLOCK_C;
                } else {
                    // был просто '/', который не открыл комментарий:
                    out += '/';
                    out += c;
                    st = NORMAL;
                }
                break;
            case LINE_C:
                // игнорируем всё до конца строки
                if (c == '\n') {
                    out += '\n';
                    st = NORMAL;
                }
                break;
            case BLOCK_C:
                // игнорируем всё до '*/'
                if (c == '*') {
                    st = BLOCK_STAR;
                }
                break;
            case BLOCK_STAR:
                if (c == '/') {
                    st = NORMAL;
                } else if (c != '*') {
                    // eсли не *, значит всё ещё внутри блока
                    st = BLOCK_C;
                }
                break;
        }
    }
//ewe dop proverka
    if (st == SLASH) {
        out += '/';
    }
    return out;
}

// проверка, что имя файла заканчивается на .c
bool isCFile(const string& name) {
    return name.size() > 2 && name.substr(name.size() - 2) == ".c";
}
//to4ka vxoda v programmu
int main(int argc, char* argv[]) {
    // otkrytie papki
    string folder = argv[1];
    DIR* dir = opendir(folder.c_str());
    if (!dir) {
        cerr << "Не удалось открыть каталог: " << folder << endl;
        return 1;
    }
    struct stat stbuf = {0};
    dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        string name = entry->d_name;
        if (!isCFile(name)) continue;
        // otkrytie vxodnogo i vihodnogo faila
        string fullpath = folder + "/" + name;
        ifstream in(fullpath);
        if (!in.is_open()) {
            cerr << "Ошибка при открытии входного файла: " << fullpath << endl;
            continue;
        }

        string outPath = string("cleaned_files/") + name;
        ofstream out(outPath);
        if (!out.is_open()) {
            cerr << "Ошибка при открытии выходного файла: " << outPath << endl;
            in.close();
            continue;
        }


        stringstream ss;
        ss << in.rdbuf(); // 4itaem
        string src = ss.str();

        out << stripComments(src); // o4iwaem
        //zakryvaem faily i logi
        in.close();
        out.close();

    }

    closedir(dir);
    return 0;
}

//запуск:
/*
./lab12_strip_comments /Users/main/CLionProjects/lab12_strip_comments/c_sources

*/