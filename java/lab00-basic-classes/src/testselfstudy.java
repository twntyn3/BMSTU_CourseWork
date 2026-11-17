import java.util.ArrayList;
import java.util.Scanner;

public class testselfstudy {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        ArrayList<SimpleFraction> fractions1 = new ArrayList<>();
        ArrayList<SimpleFraction> fractions2 = new ArrayList<>();

        System.out.println("Введите дроби для множества 1 (в формате 'числитель знаменатель', 0 0 для завершения):");
        while (true) {
            int num = scanner.nextInt();
            int den = scanner.nextInt();
            if (num == 0 && den == 0) break;
            fractions1.add(new SimpleFraction(num, den));
        }

        System.out.println("Введите дроби для множества 2 (в формате 'числитель знаменатель', 0 0 для завершения):");
        while (true) {
            int num = scanner.nextInt();
            int den = scanner.nextInt();
            if (num == 0 && den == 0) break;
            fractions2.add(new SimpleFraction(num, den));
        }

        // Вывод множеств
        System.out.println("Множество 1: " + fractions1);
        System.out.println("Множество 2: " + fractions2);

        // Выполним операции сложения и умножения между первой дробью из каждого множества
        if (!fractions1.isEmpty() && !fractions2.isEmpty()) {
            SimpleFraction sum = fractions1.get(0).add(fractions2.get(0));
            SimpleFraction product = fractions1.get(0).multiply(fractions2.get(0));

            System.out.println("Сумма первой дроби из каждого множества: " + sum);
            System.out.println("Произведение первой дроби из каждого множества: " + product);
        } else {
            System.out.println("Оба множества пустые, невозможно выполнить операции.");
        }

        scanner.close();
    }
}
