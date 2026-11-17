#include <iostream>
#include <vector>
using namespace std;

template <class T, int N = 0>
class Stack {
private:
    vector<T> data;
public:
    void push(T value);
    void pop();
    T top() const;
    bool empty() const;
    int size() const;
};

//realizaci9 metodov

// добавление
template <class T, int N>
void Stack<T, N>::push(T value) {
    if (N != 0 && data.size() >= N) {
        cout << "переполнено, больше нельзя добавить" << endl;
    } else {
        data.push_back(value);
    }
}
//убирание (уборка)
template <class T, int N>
void Stack<T, N>::pop() {
    if (!data.empty()) {
        data.pop_back();
    } else {
        cout << "пусто, нечего удалять" << endl;
    }
}
// пусто?
template <class T, int N>
T Stack<T, N>::top() const {
    if (!data.empty()) {
        return data.back();
    } else {
        cout << "в стеке пусто" << endl;
        return T();
    }
}
//эмпти?
template <class T, int N>
bool Stack<T, N>::empty() const {
    return data.empty();
}
//сайз
template <class T, int N>
int Stack<T, N>::size() const {
    return data.size();
}
