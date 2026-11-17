import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Lexer {
    public List<Token> tokenize(Scanner scanner) {
        List<Token> tokens = new ArrayList<>();//vse naidennble tokenbl
        int line = 1;//otsl polozh
        int col = 1;

        while (scanner.hasNextLine()) {//udalau probelbl v konce i na4ale
            String input = scanner.nextLine().trim();
            if (input.isEmpty()) {
                line++;
                col = 1;
                continue;
            }

            String[] parts = input.split("(?<=\\*|\\[|\\]|\\(|\\))|(?=\\*|\\[|\\]|\\(|\\))");//otdel'no kak tokenbl
            for (String part : parts) {
                part = part.trim();
                if (part.isEmpty()) continue;//obrabatblvau kazhduy 4ast'

                String type;
                //определяю тип токена
                if (part.matches("\\d+")) {
                    type = "NUMBER";
                } else if (part.matches("[a-zA-Z]+")) {
                    type = "IDENT";
                } else {
                    type = part;
                }
                //создал токен
                tokens.add(new Token(type, part, line, col));
                col += part.length();
            }

            line++;
            col = 1;
        }

        tokens.add(new Token("EOF", "", line, col));//добавляю конец
        return tokens;
    }
}