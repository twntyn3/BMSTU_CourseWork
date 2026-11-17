#ifndef GCDCONTAINER_H
#define GCDCONTAINER_H

#include <vector>
#include <stdexcept>

class GCDContainer {
public:
    using value_type = int; // тип хран знач

    void add(value_type val);
    size_t size() const;
    value_type operator[](size_t index) const; //перегрузка чттб как с массивом

    class Iterator {
    public:
        Iterator(GCDContainer* container, size_t index);//указ на конт + идх
        int operator*() const; // нод тек пары
        void operator=(int newGCD); // нов нод не изм знач
        Iterator& operator++();
        bool operator!=(const Iterator& other) const;

    private:
        GCDContainer* container_;
        size_t index_;
        int computeGCD(int a, int b) const;
    };

    Iterator begin();
    Iterator end();

private:
    std::vector<value_type> data_; // вектор хранения
};

#endif // GCDCONTAINER_H
