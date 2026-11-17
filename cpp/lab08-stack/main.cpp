#include <iostream>
#include "stack.h"
using namespace std;

int main() {
    Stack<int, 5> s;

    cout << "добавляю элементы" << endl;
    for (int i = 1; i <= 6; ++i) {
        cout << "добавляем.... " << i << endl;
        s.push(i);
    }

    cout << "\nтоп элемент: " << s.top() << endl;
    cout << "стэк сайз: " << s.size() << endl;

    cout << "\nизвлечение элементов из стека:" << endl;
    while (!s.empty()) {
        cout << "ТОп: " << s.top() << " -> извлекаем...." << endl;
        s.pop();
    }

    cout << "\nпытаемся извлечь из пустого стека:" << endl;
    s.pop();

    return 0;
}
