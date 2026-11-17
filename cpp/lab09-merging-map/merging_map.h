#include <map>
#include <iostream>

template <typename K, typename V>
class MergingMap {
private:
    std::map<K, V> data;
//конструктор с целым числом
public:
    explicit MergingMap(int predictedSize = 0) {
        (void)predictedSize;
    }

    V& operator[](const K& key) {// перегрузка нахождения значения по ключу
        if (data.find(key) == data.end()) {
            data[key] = V(0); //инициализируем ноль
        }
        return data[key];//vernuli ssblku na zna4 po klu4u
    }

    MergingMap<K, V> operator+(const MergingMap<K, V>& other) const {
        MergingMap<K, V> result;

        for (const auto& [key, value] : data) {
            result.data[key] = value + (other.data.count(key) ? other.data.at(key) : V(0));
        }
        //полное объединение ключей, как требует задача
        for (const auto& [key, value] : other.data) {
            if (!result.data.count(key)) {
                result.data[key] = value + V(0);
            }
        }

        return result;
    }

    bool operator==(const MergingMap<K, V>& other) const {
        return data == other.data;
    }

    bool operator!=(const MergingMap<K, V>& other) const {
        return !(*this == other);
    }

    void print(const std::string& title = "") const {
        for (const auto& [key, value] : data) { //проходим по всем парам ключ -> значение
            std::cout << "  " << key << " => " << value << "\n";
        }
        std::cout << "\n";
    }
    //для перебора итераторов как контейнеров (иначе не скомпилируется)
    //для перебора не const
    auto begin() { return data.begin(); }
    auto end() { return data.end(); }
    //для перебора const
    auto begin() const { return data.begin(); }
    auto end() const { return data.end(); }
};


