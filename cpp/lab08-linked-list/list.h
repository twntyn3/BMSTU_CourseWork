#include <iostream>
using namespace std;

template <class T>
class List {
private:
    struct Node {
        T data;
        Node* next;
        Node* prev;
    };

    Node* head;
    Node* tail;

public:
    List();
    ~List();

    void insert(T value, int position);
    bool find(T value);
    void remove(T value);
    void print();
};


// контсруктор

template <class T>
List<T>::List() {
    head = nullptr;
    tail = nullptr;
}

//удаляктор

template <class T>
List<T>::~List() {
    Node* current = head;
    while (current != nullptr) {
        Node* placeholder = current;
        current = current->next;
        delete placeholder;
    }
}

//вставка

template <class T>
void List<T>::insert(T value, int position) {
    Node* newNode = new Node{value, nullptr, nullptr};
// в пустой
    if (head == nullptr) {
        head = tail = newNode;
        return;
    }
// в начало (вставляем перед текущей головой и обновлыяем старую)
    if (position <= 0) {
        newNode->next = head;
        head->prev = newNode;
        head = newNode;
        return;
    }
/// посик позиции для вствки
    Node* current = head;
    int index = 0;
    while (current->next != nullptr && index < position - 1) {
        current = current->next;
        index++;
    }
//в конец
    if (current->next == nullptr) {
        current->next = newNode;
        newNode->prev = current;
        tail = newNode;
    } else { /// в середочку (между кур и кур некст и обновлчяем прев и некст)
        newNode->next = current->next;
        newNode->prev = current;
        current->next->prev = newNode;
        current->next = newNode;
    }
}

// поиск

template <class T>
bool List<T>::find(T value) {
    Node* current = head;
    while (current != nullptr) {
        if (current->data == value) {
            return true;
        }
        current = current->next;
    }
    return false;
}

//удаялтор (идем с головы до нужного валью)

template <class T>
void List<T>::remove(T value) {
    Node* current = head;
    while (current != nullptr) {
        if (current->data == value) {
            if (current == head) { ///сьтираем голову
                head = current->next;
                if (head != nullptr) {
                    head->prev = nullptr;
                } else {
                    tail = nullptr;
                }
            } else if (current == tail) {
                tail = current->prev;
                tail->next = nullptr;
            } else {
                current->prev->next = current->next;
                current->next->prev = current->prev;
            }
            delete current;
            return;
        }
        current = current->next;
    }
}

//вывод всегогого

template <class T>
void List<T>::print() {
    Node* current = head;
    while (current != nullptr) {
        cout << current->data << " ";
        current = current->next;
    }
    cout << endl;
}

