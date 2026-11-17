import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class Test {
    public static void main(String[] args) {
        OutsourcerTable table = new OutsourcerTable();
        table.add("Иванов", "Иван", "Иванович", 1500, 20);
        table.add("Петров", "Петр", "Петрович", 1200, 15);
        table.add("Волков", "Константин", "Аутсорсович", 2000, 50);
        table.add("Алексеев", "Алексей", "Алексеевич", 1800, 5);


        Map<Character, List<String>> grouped = table.expensiveOutsourcers(1300)
                .collect(Collectors.groupingBy(name -> name.charAt(0)));

        grouped.forEach((initial, names) ->
                System.out.println(initial + ": " + names)
        );

        table.mostAvailableOutsourcer().ifPresent(o ->
                System.out.println("Самый свободный аутсорсер: " + o.getFullName())
        );
    }
}
