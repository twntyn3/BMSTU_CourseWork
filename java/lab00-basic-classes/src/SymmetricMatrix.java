public class SymmetricMatrix {
    private int size;
    private int[] data;

    public SymmetricMatrix(int size) {
        this.size = size;
        this.data = new int[(size * (size + 1)) / 2];
    }
    private int index(int row, int col) {
        if (row < col) {
            int placeholder = row;
            row = col;
            col = placeholder;
        }
        return (row * (row + 1)) / 2 + col;
    }
    public void setElement(int row, int col, int value) {
        data[index(row, col)] = value;
    }
    public int getElement(int row, int col) {
        return data[index(row, col)];
    }
    public String toString() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                sb.append(getElement(i, j)).append(" ");
            }
            sb.append("\n");
        }
        return sb.toString();
    }
}
