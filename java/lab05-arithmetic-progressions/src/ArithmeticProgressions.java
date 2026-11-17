import java.util.Iterator;
import java.util.List;
import java.util.ArrayList;
import java.util.PriorityQueue;
import java.util.Comparator;
import java.util.NoSuchElementException;

public class ArithmeticProgressions implements Iterable<Integer> {
    private final List<Progression> progressions;

    public ArithmeticProgressions() {
        this.progressions = new ArrayList<>();
    }
    public void addProgression(int start, int step) {
        progressions.add(new Progression(start, step));
    }

    public Iterator<Integer> iterator() {
        return new ProgressionIterator();
    }
    private class Progression {
        int current;
        final int step;

        Progression(int start, int step) {
            this.current = start;
            this.step = step;
        }

        int next() {
            int value = current;
            current += step;
            return value;
        }
    }

    private class ProgressionIterator implements Iterator<Integer> {
        private PriorityQueue<Element> pq;

        public ProgressionIterator() {
            pq = new PriorityQueue<>(Comparator.comparingInt(e -> e.value));
            for (Progression p : progressions) {
                pq.add(new Element(p.next(), p));
            }
        }

        public boolean hasNext() {
            return !pq.isEmpty();
        }
        public Integer next() {
            if (!hasNext()) throw new NoSuchElementException();

            Element e = pq.poll();
            int value = e.value;
            e.value = e.progression.next();
            pq.add(e);
            return value;
        }
    }

    private static class Element {
        int value;
        final Progression progression;

        Element(int value, Progression progression) {
            this.value = value;
            this.progression = progression;
        }
    }
}
