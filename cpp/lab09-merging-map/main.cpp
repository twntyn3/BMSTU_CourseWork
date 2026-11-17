#include <iostream>
#include "merging_map.h"

int main() {
    std::cout << "Пример 1: MergingMap<string, int>\n";

    MergingMap<std::string, int> m1;
    m1["a"] = 10;
    m1["b"] = 20;

    MergingMap<std::string, int> m2;
    m2["b"] = 5;
    m2["c"] = 15;

    auto merged = m1 + m2;

    m1.print("m1");
    m2.print("m2");
    merged.print("merged = m1 + m2");

    std::cout << "\nСравнение m1 и m2: " << (m1 == m2 ? "равны" : "не равны") << "\n";

    std::cout << "\nПример 2: MergingMap<string, MergingMap<string, int>>\n";

    MergingMap<std::string, MergingMap<std::string, int>> table1;
    table1["row1"]["col1"] = 1;
    table1["row1"]["col2"] = 2;

    MergingMap<std::string, MergingMap<std::string, int>> table2;
    table2["row1"]["col1"] = 3;
    table2["row2"]["col1"] = 4;

    auto tableMerged = table1 + table2;

    std::cout << "tableMerged:\n";
    for (const auto& [row, cols] : tableMerged) {
        std::cout << row << ":\n";
        cols.print();
    }

    return 0;
}
