public class Token {
    public final String type;
    public final String value;
    public final int line;
    public final int col;

    public Token(String type, String value, int line, int col) {
        this.type = type;
        this.value = value;
        this.line = line;
        this.col = col;
    }
}