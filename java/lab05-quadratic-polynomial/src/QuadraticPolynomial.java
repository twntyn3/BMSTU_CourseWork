import java.util.*;
import java.util.stream.*;

public class QuadraticPolynomial {
    private final double a;
    private final double b;
    private final double c;

    public QuadraticPolynomial(double a, double b, double c) {
        if (a == 0) {
            throw new IllegalArgumentException("'a' не должен быть равен нулю");
        }
        this.a = a;
        this.b = b;
        this.c = c;
    }

    public static Stream<Double> streamOfRootSums(List<QuadraticPolynomial> polynomials) {
        return polynomials.stream()
                .filter(p -> p.hasRealRoots())
                .map(p -> -p.b / p.a);
    }

    private boolean hasRealRoots() {
        return getDiscriminant() >= 0;
    }

    private double getDiscriminant() {
        return b * b - 4 * a * c;
    }

    public static Optional<QuadraticPolynomial> maxProductOfRoots(List<QuadraticPolynomial> polynomials) {
        return polynomials.stream()
                .filter(p -> p.hasRealRoots())
                .max(Comparator.comparingDouble(p -> p.c / p.a));
    }

    public double getA() { return a; }
    public double getB() { return b; }
    public double getC() { return c; }
}
