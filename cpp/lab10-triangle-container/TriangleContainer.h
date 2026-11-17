#ifndef TRIANGLECONTAINER_H
#define TRIANGLECONTAINER_H

#include <vector>
#include <stdexcept>

class TriangleContainer {
public:
    using value_type = double;

    void addSegment(value_type length);
    size_t size() const;
    //перегрузка оператора [],можно обращаться к отрезкам по idx
    value_type operator[](size_t index) const;

    class ConstIterator {
    public:
        ConstIterator(const TriangleContainer* container, size_t index);
        double operator*() const;//разыменование, возвращает периметр треугольника или 0
        void operator=(double newPerimeter); // новинка — установка нового периметра
        ConstIterator& operator++();//переход к некст тройке
        bool operator!=(const ConstIterator& other) const;//сравниваю итераторы (для циклов)

    private:
        const TriangleContainer* container_; //тот контейнер, где идет работа
        size_t index_;
    };
    //первый и последний трекгольник
    ConstIterator begin() const;
    ConstIterator end() const;

private:
    std::vector<value_type> segments_;//внктр хранилище отрезков
};

#endif // TRIANGLECONTAINER_H
