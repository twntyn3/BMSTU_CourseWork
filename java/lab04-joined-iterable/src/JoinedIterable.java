import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;

public class JoinedIterable<T> implements Iterable<T> {
    private final List<Iterable<T>> iterables;

    public JoinedIterable(List<Iterable<T>> iterables) {
        this.iterables = iterables;
    }

    public Iterator<T> iterator() {
        return new JoinedIterator();
    }

    private class JoinedIterator implements Iterator<T> {
        private int currentIterableIndex = 0;
        private Iterator<T> currentIterator;

        public JoinedIterator() {
            if (!iterables.isEmpty()) {
                currentIterator = iterables.get(0).iterator();
            }
        }
        public boolean hasNext() {
            while (currentIterableIndex < iterables.size()) {
                if (currentIterator.hasNext()) {
                    return true;
                } else {
                    currentIterableIndex++;
                    if (currentIterableIndex < iterables.size()) {
                        currentIterator = iterables.get(currentIterableIndex).iterator();
                    }
                }
            }
            return false;
        }
        public T next() {
            if (!hasNext()) {
                throw new NoSuchElementException();
            }
            return currentIterator.next();
        }
    }
}
