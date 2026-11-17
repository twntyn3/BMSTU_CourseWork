/*public class Test {
    public static void main(String[] args) {
        System.out.println("Тест 1 (Матрица 3x3)");
        SymmetricMatrix matrix1 = new SymmetricMatrix(3);
        matrix1.setElement(0, 0, 1);
        matrix1.setElement(1, 0, 2);
        matrix1.setElement(1, 1, 3);
        matrix1.setElement(2, 0, 4);
        matrix1.setElement(2, 1, 5);
        matrix1.setElement(2, 2, 6);
        System.out.println(matrix1);
        System.out.println("Тест 2 (Матрица 5x5)");
        SymmetricMatrix matrix2 = new SymmetricMatrix(5);
        java.util.Random rand = new java.util.Random();
        int value = 1;
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j <= i; j++) {
                matrix2.setElement(i, j, rand.nextInt(100));
            }
        }
        System.out.println(matrix2);
        System.out.println("Тест 3 (Матрица 6x6)");
        SymmetricMatrix matrix3 = new SymmetricMatrix(6);
        for (int i = 0; i < 6; i++) {
            for (int j = 0; j <= i; j++) {
                matrix3.setElement(i, j, rand.nextInt(100));
            }
        }
        System.out.println(matrix3);
    }
}
*/
import java.util.Scanner;

public class Test {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.print("Введите максимальное значение множества: ");
        int maxSize = scanner.nextInt();

        IntSet set1 = new IntSet(maxSize);
        IntSet set2 = new IntSet(maxSize);

        System.out.println("Введите элементы для множества 1 (введите -1 для завершения):");
        while (true) {
            int num = scanner.nextInt();
            if (num == -1) break;
            set1.add(num);
        }

        System.out.println("Введите элементы для множества 2 (введите -1 для завершения):");
        while (true) {
            int num = scanner.nextInt();
            if (num == -1) break;
            set2.add(num);
        }

        System.out.println("Множество 1: " + set1);
        System.out.println("Множество 2: " + set2);

        IntSet result = set1.symmetricDifference(set2);
        System.out.println("Симметрическая разность: " + result);
    }
}