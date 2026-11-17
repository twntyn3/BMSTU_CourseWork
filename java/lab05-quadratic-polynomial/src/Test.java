import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

class Test {
    public static void main(String[] args) {
        List<QuadraticPolynomial> polynomials = Arrays.asList(
                new QuadraticPolynomial(1, -3, 2),  // x^2 - 3x + 2
                new QuadraticPolynomial(1, -2, 1),  // x^2 - 2x + 1
                new QuadraticPolynomial(1, 2, 1),   // x^2 + 2x + 1
                new QuadraticPolynomial(2, -4, 2)   // 2x^2 - 4x + 2
        );

        Stream<Double> rootSums = QuadraticPolynomial.streamOfRootSums(polynomials);
        Map<Boolean, Long> countBySign = rootSums
                .collect(Collectors.partitioningBy(sum -> sum < 0, Collectors.counting()));

        System.out.println("Количество отрицательных сумм корней: " + countBySign.get(true));
        System.out.println("Количество неотрицательных сумм корней: " + countBySign.get(false));

        Optional<QuadraticPolynomial> maxProductPolynomial = QuadraticPolynomial.maxProductOfRoots(polynomials);

        maxProductPolynomial.ifPresent(p ->
                System.out.println("Трехчлен с максимальным произведением корней: " +
                        p.getA() + "x² + " + p.getB() + "x + " + p.getC())
        );
    }
}
