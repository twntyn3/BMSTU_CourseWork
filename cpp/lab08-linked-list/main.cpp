#include <iostream>
#include "list_int.h"
using namespace std;

int main() {
    List<int> myList;

    cout << "Добавляем элементы:" << endl;
    myList.insert(5, 0);
    myList.insert(10, 1);
    myList.insert(15, 1); // вставка на позицию 1
    myList.print();

    cout << "Поиск элементов:" << endl;
    cout << (myList.find(10) ? "Найдено" : "Не найдено") << endl;
    cout << (myList.find(100) ? "Найдено" : "Не найдено") << endl;

    cout << "Удаление элемента 10:" << endl;
    myList.remove(10);
    myList.print();

    cout << "Сумма элементов:" << endl;
    cout << myList.sum() << endl;

    return 0;
}
