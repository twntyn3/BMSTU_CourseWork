import java.util.Arrays;
import java.util.Scanner;

public class Test {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.print("Введите количество абитуриентов: ");
        int count = scanner.nextInt();
        scanner.nextLine();

        Applicant[] applicants = new Applicant[count];

        for (int i = 0; i < count; i++) {
            System.out.println("Введите данные абитуриента " + (i + 1) + ":");

            System.out.print("Имя: ");
            String name = scanner.nextLine();

            System.out.print("Баллы по информатике: ");
            int inf = scanner.nextInt();

            System.out.print("Баллы по математике: ");
            int math = scanner.nextInt();

            System.out.print("Баллы по русскому языку: ");
            int rus = scanner.nextInt();
            scanner.nextLine();

            applicants[i] = new Applicant(name, inf, math, rus);
        }
        Arrays.sort(applicants);
        System.out.println("\nСписок абитуриентов:");
        for (Applicant a : applicants) {
            System.out.println(a);
        }

        scanner.close();
    }
}
