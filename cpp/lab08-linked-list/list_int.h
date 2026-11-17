#include "list.h"

template <>
class List<int> {
private:
    struct Node {
        int data;
        Node* next;
        Node* prev;
    };

    Node* head;
    Node* tail;

public:
    List();
    ~List();

    void insert(int value, int position);
    bool find(int value);
    void remove(int value);
    void print();
    int sum();
};

List<int>::List() {
    head = nullptr;
    tail = nullptr;
}

List<int>::~List() {
    Node* current = head;
    while (current != nullptr) {
        Node* temp = current;
        current = current->next;
        delete temp;
    }
}

void List<int>::insert(int value, int position) {
    Node* newNode = new Node{value, nullptr, nullptr};

    if (head == nullptr) {
        head = tail = newNode;
        return;
    }

    if (position <= 0) {
        newNode->next = head;
        head->prev = newNode;
        head = newNode;
        return;
    }

    Node* current = head;
    int index = 0;
    while (current->next != nullptr && index < position - 1) {
        current = current->next;
        index++;
    }

    if (current->next == nullptr) {
        current->next = newNode;
        newNode->prev = current;
        tail = newNode;
    } else {
        newNode->next = current->next;
        newNode->prev = current;
        current->next->prev = newNode;
        current->next = newNode;
    }
}

bool List<int>::find(int value) {
    Node* current = head;
    while (current != nullptr) {
        if (current->data == value) {
            return true;
        }
        current = current->next;
    }
    return false;
}

void List<int>::remove(int value) {
    Node* current = head;
    while (current != nullptr) {
        if (current->data == value) {
            if (current == head) {
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

void List<int>::print() {
    Node* current = head;
    while (current != nullptr) {
        cout << current->data << " ";
        current = current->next;
    }
    cout << endl;
}

// по бльш счету едиснтвенное отличие листов

int List<int>::sum() {
    int total = 0;
    Node* current = head;
    while (current != nullptr) {
        total += current->data;
        current = current->next;
    }
    return total;
}

