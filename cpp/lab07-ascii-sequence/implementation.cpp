#include "declaration.h"
#include <iostream>
#include <cstring>

ASCIISequence::ASCIISequence() : sequence(nullptr), size(0) {} //кнстрк умлч
ASCIISequence::ASCIISequence(const ASCIISequence& other) : size(other.size) { //коп кнстрк
    sequence = new char[size];
    std::memcpy(sequence, other.sequence, size); // новая память под массив
}
ASCIISequence& ASCIISequence::operator=(const ASCIISequence& other) {
    if (this == &other) return *this; // защаита от самоприсваивания

    delete[] sequence;

    size = other.size;
    sequence = new char[size];
    std::memcpy(sequence, other.sequence, size);

    return *this;
}
//деструктор
ASCIISequence::~ASCIISequence() {
    delete[] sequence;
}
// получение размера
size_t ASCIISequence::getSize() const {
    return size;
}// к символу по indx
char& ASCIISequence::getChar(size_t index) {
    if (index >= size) {
        throw std::out_of_range("idx out of range");
    }
    return sequence[index];
}
//вствка по индексу
void ASCIISequence::insertChar(size_t index, char c) {
    if (index > size) {
        throw std::out_of_range("idx out of range");
    }

    char* newSequence = new char[size + 1];
    std::memcpy(newSequence, sequence, index);
    newSequence[index] = c;
    std::memcpy(newSequence + index + 1, sequence + index, size - index); // Копируем вторую часть

    delete[] sequence;
    sequence = newSequence;
    ++size;
}
//проверка полиндрома
bool ASCIISequence::isPalindrome() const {
    for (size_t i = 0; i < size / 2; ++i) {
        if (sequence[i] != sequence[size - i - 1]) {
            return false;
        }
    }
    return true;
}
