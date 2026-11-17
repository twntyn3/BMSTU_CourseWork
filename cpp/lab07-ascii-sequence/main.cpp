#include <iostream>
#include "declaration.h"
using namespace std;
void testASCIISequence(ASCIISequence seq) {
    cout << "1. Количество символов в последовательности: " << seq.getSize() << std::endl;

    try {
        cout << "2. Символ на 1-й позиции: " << seq.getChar(1) << endl;
    } catch (const std::out_of_range& e) {
        cout << "Ошибка: " << e.what() << endl;
    }
}

int main() {
    ASCIISequence seq1;
    std::cout << "создаем последовательность: \n";

    seq1.insertChar(0, 'a');
    seq1.insertChar(1, 'b');
    seq1.insertChar(2, 'c');
    std::cout << "последовательность после вставки 'a', 'b', 'c': ";
    for (size_t i = 0; i < seq1.getSize(); ++i) {
        std::cout << seq1.getChar(i);
    }
    std::cout << std::endl;

    std::cout << "является ли последовательность палиндромом: "
              << (seq1.isPalindrome() ? "Да" : "Нет") << std::endl;

    testASCIISequence(seq1);

    ASCIISequence seq2;
    seq2 = seq1;
    std::cout << "присваивание seq2 = seq1, последовательность seq2: ";
    for (size_t i = 0; i < seq2.getSize(); ++i) {
        std::cout << seq2.getChar(i);
    }
    std::cout << std::endl;

    seq1.insertChar(1, 'z');
    std::cout << "после вставки 'z' на позицию 1: ";
    for (size_t i = 0; i < seq1.getSize(); ++i) {
        std::cout << seq1.getChar(i);
    }
    std::cout << std::endl;


    std::cout << "является ли последовательность палиндромом после вставки 'z': "
              << (seq1.isPalindrome() ? "Да" : "Нет") << std::endl;

    return 0;
}
