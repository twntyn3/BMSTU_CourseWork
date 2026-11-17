import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

class Product {
    int cost, count;
    String name;

    Product(String name, int count, int cost) {
        this.name = name;
        this.count = count;
        this.cost = cost;
    }

    public String getName() {
        return name;
    }

    public int totalValue() {
        return cost * count;
    }

    public int getCount() {
        return count;
    }
}

class ProductTable {
    private final HashMap<String, Product> table = new HashMap<>();

    public void add(Product p) {
        table.put(p.name, p);
    }

    public void add(String name, int cost, int count) {
        table.put(name, new Product(name, count, cost));
    }

    // Метод 1: Возвращает поток названий товаров, стоимость запасов которых превышает заданное значение
    public Stream<String> nameStream(int valueThreshold) {
        return table.values().stream()
                .filter(p -> p.totalValue() > valueThreshold)
                .map(Product::getName);
    }

    // Метод 2: Возвращает Optional с товаром, количество которого превышает сумму всех остальных
    public Optional<Product> getProduct() {
        int total = table.values().stream()
                .mapToInt(Product::getCount)
                .sum();

        return table.values().stream()
                .filter(p -> p.getCount() > (total - p.getCount()))
                .findFirst();
    }
}
