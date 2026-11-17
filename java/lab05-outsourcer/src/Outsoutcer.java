import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;
class Outsourcer {
    String surname;
    String name;
    String patronymic;
    int hourlyRate;
    int weeklyHours;
    Outsourcer(String surname, String name, String patronymic, int hourlyRate, int weeklyHours) {
        this.surname = surname;
        this.name = name;
        this.patronymic = patronymic;
        this.hourlyRate = hourlyRate;
        this.weeklyHours = weeklyHours;
    }
    public String getFullName() {
        return surname + " " + name + " " + patronymic;
    }
    public int getHourlyRate() {
        return hourlyRate;
    }

    public int getWeeklyHours() {
        return weeklyHours;
    }

    public String getSurname() {
        return surname;
    }

}
class OutsourcerTable {
    private final List<Outsourcer> outsourcers = new ArrayList<>();
    public void add(Outsourcer o) {
        outsourcers.add(o);
    }

    public void add(String surname, String name, String patronymic, int hourlyRate, int weeklyHours) {
        outsourcers.add(new Outsourcer(surname, name, patronymic, hourlyRate, weeklyHours));
    }
    public Stream<String> expensiveOutsourcers(int rateThreshold) {
        return outsourcers.stream()
                .filter(o -> o.getHourlyRate() > rateThreshold)
                .map(Outsourcer::getFullName);
    }
    public Optional<Outsourcer> mostAvailableOutsourcer() {
        int totalHours = outsourcers.stream()
                .mapToInt(Outsourcer::getWeeklyHours)
                .sum();
        return outsourcers.stream()
                .filter(o -> o.getWeeklyHours() > totalHours - o.getWeeklyHours())
                .findFirst();
    }
}

