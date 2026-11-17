#include <cstddef>

class ASCIISequence {
private:
    char* sequence;
    size_t size;

public:
    ASCIISequence();
    ASCIISequence(const ASCIISequence& other);
    ASCIISequence& operator=(const ASCIISequence& other);
    virtual ~ASCIISequence();

    //методы упрв пам
    size_t getSize() const;

    char& getChar(size_t index);
    void insertChar(size_t index, char c);
    bool isPalindrome() const;
};

