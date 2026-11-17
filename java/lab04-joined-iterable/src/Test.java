import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Test {
    public static void main(String[] args) {
        List<Integer> list1 = Arrays.asList(1, 2, 3);
        List<Integer> list2 = Arrays.asList(4, 5);
        List<Integer> list3 = Arrays.asList(6, 7, 8, 9);

        List<Iterable<Integer>> iterables = new ArrayList<>();
        iterables.add(list1);
        iterables.add(list2);
        iterables.add(list3);

        JoinedIterable<Integer> joined = new JoinedIterable<>(iterables);

        System.out.println("Элементы после конкатенации:");
        for (int x : joined) {
            System.out.print(x + " ");
        }
        System.out.println();
    }
}
