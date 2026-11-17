class IntSet {
    private int[] elements;
    private int size;

    public IntSet(int capacity) {
        elements = new int[capacity];
        size = 0;
    }

    public void add(int value) {
        if (!contains(value)) {
            if (size == elements.length) {
                expand();
            }
            elements[size++] = value;
        }
    }

    public void remove(int value) {
        for (int i = 0; i < size; i++) {
            if (elements[i] == value) {
                elements[i] = elements[size - 1];
                size--;
                return;
            }
        }
    }

    public boolean contains(int value) {
        for (int i = 0; i < size; i++) {
            if (elements[i] == value) {
                return true;
            }
        }
        return false;
    }
    private void expand() {
        int[] newElements = new int[elements.length * 2];
        System.arraycopy(elements, 0, newElements, 0, elements.length);
        elements = newElements;
    }

    public IntSet symmetricDifference(IntSet other) {
        IntSet result = new IntSet(this.size + other.size);

        for (int i = 0; i < this.size; i++) {
            if (!other.contains(this.elements[i])) {
                result.add(this.elements[i]);
            }
        }

        for (int i = 0; i < other.size; i++) {
            if (!this.contains(other.elements[i])) {
                result.add(other.elements[i]);
            }
        }
        return result;
    }

    public String toString() {
        StringBuilder sb = new StringBuilder("{");
        for (int i = 0; i < size; i++) {
            sb.append(elements[i]);
            if (i < size - 1) {
                sb.append(", ");
            }
        }
        sb.append("}");
        return sb.toString();
    }
}

