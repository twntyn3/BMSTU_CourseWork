import java.util.List;
import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        Lexer lexer = new Lexer();//создаем лексер и разбиваем входной текст на токены
        List<Token> tokens = lexer.tokenize(scanner);

        Parser parser = new Parser(tokens);//передаю токены парсеру
        try {//запускаю разбор
            parser.parseDecl();
            for (String rule : parser.getRules()) {
                System.out.println(rule);//esli vse good to prosto postro4no vivodim
            }
        } catch (RuntimeException e) {
            System.out.println(e.getMessage());//esli owibka (((
        }
    }
}