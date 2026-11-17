import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class Test {
    public static void main(String[] args) {
        ProductTable t = new ProductTable();
        t.add("apple", 10, 10);
        t.add("banana", 6, 10);
        t.add("cherry", 2, 5);
        t.add("date", 7, 110);

        // Группировка названий товаров по первой букве
        Map<Character, List<String>> grouped = t.nameStream(90)
                .collect(Collectors.groupingBy(s -> s.charAt(0)));

        grouped.forEach((k, v) -> System.out.println(k + ": " + v));

        // Поиск товара, количество которого превышает сумму остальных
        t.getProduct().ifPresent(p ->
                System.out.println("Product with majority stock: " + p.name));
    }
}
