#include <iostream>
#include "TriangleContainer.h"

int main() {
    TriangleContainer container;

    //добавляем отрезки через метод
    container.addSegment(3);
    container.addSegment(4);
    container.addSegment(5);
    container.addSegment(6);
    container.addSegment(10);
    // вывожу все отрезки
    std::cout << "Отрезки: ";
    for (size_t i = 0; i < container.size(); ++i) {
        std::cout << container[i] << " ";
    }
    // прохожу по тройкам отрезков
    std::cout << "\nПериметры треугольников: ";
    for (auto it = container.begin(); it != container.end(); ++it) {
        double perim = *it;
        if (perim > 0)
            std::cout << perim << " ";
        else
            std::cout << "[не треугольник] ";
    }

    //изменения периметра
    auto it = container.begin(); // выбираем первый треугольник: 3,4,5
    it.operator=(24.0); // новый периметр, будет масштабировано (теперь 6,8,10)

    std::cout << "\n\nПосле изменения периметра первого треугольника на 24:\n";

    std::cout << "Новые отрезки: ";
    for (size_t i = 0; i < container.size(); ++i) {
        std::cout << container[i] << " ";
    }

    std::cout << "\nНовые периметры треугольников: ";
    for (auto it2 = container.begin(); it2 != container.end(); ++it2) {
        double perim = *it2;
        if (perim > 0)
            std::cout << perim << " ";
        else
            std::cout << "[не треугольник] ";
    }

    return 0;
}
