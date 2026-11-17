#include <iostream>
#include "linear_ineq.h"

int main() {
    using Ineq = LinearIneq<double, 3>;

    Ineq ineq1({1, 2, -1}, 4, Relation::LessEq);
    Ineq ineq2({0, 1, 1}, 3, Relation::LessEq);

    std::cout << "Изначальные неравенства:\n";
    ineq1.print("ineq1");
    ineq2.print("ineq2");

    auto sum = ineq1 + ineq2;
    sum.print("Сумма (ineq1 + ineq2)");

    auto scaled = ineq1 * -2;
    scaled.print("Масштабированное ineq1 * -2");

    auto negated = !ineq1;
    negated.print("Отрицание ineq1");

    std::array<double, 3> values = {10, 0, 1};
    std::cout << "\nПроверка ineq1 на {10, 0, 1}: "
              << (ineq1(values) ? "Выполняется" : "Не выполняется") << "\n";

    return 0;
}
