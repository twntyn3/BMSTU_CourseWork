public class SimpleFraction {
    private int numerator;
    private int denominator;
    public SimpleFraction(int numerator, int denominator) {
        if (denominator == 0) {
            throw new IllegalArgumentException("знаменатель не может быть равен нулю");

        }
        int gcd = gcd(numerator, denominator);
        this.numerator = numerator / gcd;
        this.denominator = denominator / gcd;
    }

    private int gcd(int a, int b) {
        while (b != 0) {
            int t = b;
            b = a % b;
            a = t;
        }
        return Math.abs(a);
    }
    // Метод сложения дробей
    public SimpleFraction add(SimpleFraction other) {
        int newNumerator = this.numerator * other.denominator + this.denominator * other.numerator;
        int newDenominator = this.denominator * other.denominator;
        return new SimpleFraction(newNumerator, newDenominator);
    }

    // Метод умножения дробей
    public SimpleFraction multiply(SimpleFraction other) {
        int newNumerator = this.numerator * other.numerator;
        int newDenominator = this.denominator * other.denominator;
        return new SimpleFraction(newNumerator, newDenominator);
    }

    public String toString() {
        return numerator + "/" + denominator;
    }
}



