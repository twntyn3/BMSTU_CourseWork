#include <iostream>
#include "GCDContainer.h"

int main() {
    GCDContainer container;
    container.add(12);
    container.add(18);
    container.add(27);
    container.add(36);
    //здесь перешрузка по size (инкапсуляция) и operator (как с массивом работать)
    std::cout << "Исходные числа: ";
    for (size_t i = 0; i < container.size(); ++i)
        std::cout << container[i] << " ";
    std::cout << "\nНОД соседних пар: ";

    for (auto it = container.begin(); it != container.end(); ++it)
        std::cout << *it << " ";
    //перегруженный оператор присваивания (угол останется тот же)
    std::cout << "\nИзменим НОД первой пары на 10:\n";
    auto it = container.begin();
    it.operator = (10);

    std::cout << "Новая последовательность: ";
    for (size_t i = 0; i < container.size(); ++i)
        std::cout << container[i] << " ";

    return 0;
}
