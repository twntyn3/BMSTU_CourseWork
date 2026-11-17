#include <array>
#include <iostream>
#include <cassert>

enum class Relation { // типы отношений в нервах
    Less,
    LessEq,
    Greater,
    GreaterEq
};

inline std::string relationToStr(Relation r) {//релэйшен в строку
    switch (r) {
        case Relation::Less: return "<";
        case Relation::LessEq: return "<=";
        case Relation::Greater: return ">";
        case Relation::GreaterEq: return ">=";
    }
    return "?";// esli neizvesten to "?"
}

template <typename T, std::size_t N>
class LinearIneq {
private: //nelz9 isp napr9muy vne klassa
    std::array<T, N> a{};
    T b{};
    Relation rel;
public:
    //const std::array<T, N>& a_ — константная ссылка на массив коэффициентов
    LinearIneq(const std::array<T, N>& a_, T b_, Relation r)
        : a(a_), b(b_), rel(r) {} // инициализирует поля значениями

    // умножение на число
    LinearIneq<T, N> operator*(T scalar) const {
        assert(scalar != 0 && "нельзя");
        std::array<T, N> newA;
        for (std::size_t i = 0; i < N; ++i) {
            newA[i] = a[i] * scalar;
        }
        Relation newRel = rel;
        if (scalar < 0) { // инверсируем

            switch (rel) {
                case Relation::Less: newRel = Relation::Greater; break;
                case Relation::LessEq: newRel = Relation::GreaterEq; break;
                case Relation::Greater: newRel = Relation::Less; break;
                case Relation::GreaterEq: newRel = Relation::LessEq; break;
            }
        }
        return LinearIneq(newA, b * scalar, newRel);
    }
    //знак отрицания и др инверсия
    LinearIneq<T, N> operator!() const {
        Relation invRel;
        switch (rel) {
            case Relation::Less: invRel = Relation::GreaterEq; break;
            case Relation::LessEq: invRel = Relation::Greater; break;
            case Relation::Greater: invRel = Relation::LessEq; break;
            case Relation::GreaterEq: invRel = Relation::Less; break;
        }
        return LinearIneq(a, b, invRel);
    }
    LinearIneq<T, N> operator+(const LinearIneq<T, N>& other) const {
        assert(rel == other.rel && "Нельзя складывать неравенства с разными знаками");
        //cкладываем коэффициенты поэлементно
        std::array<T, N> newA;
        for (std::size_t i = 0; i < N; ++i) {
            newA[i] = a[i] + other.a[i];
        }
        return LinearIneq(newA, b + other.b, rel);
    }

    //proverka na istinnost'
    bool operator()(const std::array<T, N>& x) const {
        T lhs = 0;
        for (std::size_t i = 0; i < N; ++i) {
            lhs += a[i] * x[i];
        }
        //cравнение с b по нужному знаку
        switch (rel) {
            case Relation::Less: return lhs < b;
            case Relation::LessEq: return lhs <= b;
            case Relation::Greater: return lhs > b;
            case Relation::GreaterEq: return lhs >= b;
        }
        return false;
    }


    void print(const std::string& label = "") const {
        if (!label.empty()) std::cout << label << ": ";

        for (std::size_t i = 0; i < N; ++i) {
            std::cout << a[i] << "*x" << i + 1;
            if (i < N - 1) std::cout << " + ";
        }
        std::cout << " " << relationToStr(rel) << " " << b << "\n";
    }
};

