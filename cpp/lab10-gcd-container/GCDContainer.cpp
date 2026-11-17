#include "GCDContainer.h"
#include <numeric>
//добавялем эл в дату
void GCDContainer::add(value_type val) {
    data_.push_back(val);
}

size_t GCDContainer::size() const {
    return data_.size();
}
// безопасное обрщ к эл по идх
GCDContainer::value_type GCDContainer::operator[](size_t index) const {
    if (index >= data_.size()) throw std::out_of_range("Index out of range");
    return data_[index];
}


GCDContainer::Iterator::Iterator(GCDContainer* container, size_t index)
    : container_(container), index_(index) {}

int GCDContainer::Iterator::computeGCD(int a, int b) const {
    return std::gcd(a, b); // НОД
}
// возвращаем НОД
int GCDContainer::Iterator::operator*() const {
    if (index_ + 1 >= container_->data_.size())
        throw std::out_of_range("не сушествует такой пары");
    return computeGCD(container_->data_[index_], container_->data_[index_ + 1]);
}
// мутища с изменением НОД
void GCDContainer::Iterator::operator=(int newGCD) {
    if (index_ + 1 >= container_->data_.size())
        throw std::out_of_range("не существует такой пары");

    int& a = container_->data_[index_];
    int& b = container_->data_[index_ + 1];
    int oldGCD = computeGCD(a, b);

    if (oldGCD == 0 || newGCD == 0) return;

    a = (a / oldGCD) * newGCD;
    b = (b / oldGCD) * newGCD;
}
// к следущему
GCDContainer::Iterator& GCDContainer::Iterator::operator++() {
    ++index_;
    return *this;
}

bool GCDContainer::Iterator::operator!=(const Iterator& other) const {
    return index_ != other.index_;
}

GCDContainer::Iterator GCDContainer::begin() {
    return Iterator(this, 0);
}
// посл допуст пара
GCDContainer::Iterator GCDContainer::end() {
    if (data_.size() < 2)
        return Iterator(this, 0);
    return Iterator(this, data_.size() - 1); // Последняя пара начинается на size - 2
}
