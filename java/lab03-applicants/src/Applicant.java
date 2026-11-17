import java.util.Arrays;

class Applicant implements Comparable<Applicant> {
    private String name;
    private int informaticsScore;
    private int mathScore;
    private int russianScore;

    public Applicant(String name, int informaticsScore, int mathScore, int russianScore) {
        this.name = name;
        this.informaticsScore = informaticsScore;
        this.mathScore = mathScore;
        this.russianScore = russianScore;

    }

    public int getTotalScore() {
        return informaticsScore + mathScore + russianScore;
    }
    public int compareTo(Applicant other) {
        if (this.getTotalScore() != other.getTotalScore()) {
            return Integer.compare(other.getTotalScore(), this.getTotalScore());
        }
        if (this.informaticsScore != other.informaticsScore) {
            return Integer.compare(other.informaticsScore, this.informaticsScore);
        }
        if (this.mathScore != other.mathScore) {
            return Integer.compare(other.mathScore, this.mathScore);
        }
        return Integer.compare(other.getTotalScore(), this.getTotalScore());
    }
    public String toString() {
        return String.format("{Имя: %s, Инфа: %d, Математика: %d, Русский: %d, Сумма: %d}",
                name, informaticsScore, mathScore, russianScore, getTotalScore());
    }
}

