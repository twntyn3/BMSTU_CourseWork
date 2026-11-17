public class Test {
    public static void main(String[] args) {
        ArithmeticProgressions ap = new ArithmeticProgressions();

        ap.addProgression(1, 3);
        ap.addProgression(2, 2);
        ap.addProgression(5, 5);

        System.out.println("Числа из прогрессий в порядке возрастания:");
        for (int num : ap) {
            if (num > 20) break;
            System.out.print(num + " ");
        }
    }
}

