#include "TriangleContainer.h"

void TriangleContainer::addSegment(value_type length) {
    if (length <= 0) {
        throw std::invalid_argument("Length must be positive");//защита от некорректного занчения
    }
    segments_.push_back(length);
}
//возвр колво отрезков
size_t TriangleContainer::size() const {
    return segments_.size();
}
//безопасное обращение по индексу
TriangleContainer::value_type TriangleContainer::operator[](size_t index) const {
    if (index >= segments_.size()) {
        throw std::out_of_range("Index out of range");
    }
    return segments_[index];
}


//инициализирую поля и создаю тройку индексовскую
TriangleContainer::ConstIterator::ConstIterator(const TriangleContainer* container, size_t index)
    : container_(container), index_(index) {}
//разыменовываем звездочку (хотя бы 3 отр)
double TriangleContainer::ConstIterator::operator*() const {
    if (index_ + 2 >= container_->segments_.size()) {
        throw std::out_of_range("Not enough segments for triangle");//проверка на 3 индекса (хотя бы)
    }
    double a = container_->segments_[index_];
    double b = container_->segments_[index_ + 1];
    double c = container_->segments_[index_ + 2];

    // проверка на существование треугольника
    if (a + b <= c || a + c <= b || b + c <= a) {
        return 0.0; //не образует треугольник
    }

    return a + b + c;
}

//новая функция: масштабируем стороны треугольника
void TriangleContainer::ConstIterator::operator=(double newPerimeter) {
    if (index_ + 2 >= container_->segments_.size()) {
        throw std::out_of_range("Not enough segments for triangle");
    }

    double& a = const_cast<double&>(container_->segments_[index_]);
    double& b = const_cast<double&>(container_->segments_[index_ + 1]);
    double& c = const_cast<double&>(container_->segments_[index_ + 2]);

    if (a + b <= c || a + c <= b || b + c <= a) {
        throw std::logic_error("Cannot scale: not a valid triangle");
    }

    double oldPerimeter = a + b + c;
    double scale = newPerimeter / oldPerimeter;

    a *= scale;
    b *= scale;
    c *= scale;
}

//переход к след позиции
TriangleContainer::ConstIterator& TriangleContainer::ConstIterator::operator++() {
    ++index_;
    return *this;
}

bool TriangleContainer::ConstIterator::operator!=(const ConstIterator& other) const {
    return index_ != other.index_;
}

TriangleContainer::ConstIterator TriangleContainer::begin() const {
    return ConstIterator(this, 0);
}
//заканчиваю процесс
TriangleContainer::ConstIterator TriangleContainer::end() const {
    if (segments_.size() < 3)
        return ConstIterator(this, 0);
    return ConstIterator(this, segments_.size() - 2); // Последний допустимый треугольник
}
