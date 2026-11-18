import java.util.*;

public class Main {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        int numStates = Integer.parseInt(readLineSkippingEmpty(scanner));
        int[][] transitions = new int[numStates][];
        for (int i = 0; i < numStates; i++) {
            transitions[i] = Arrays.stream(readLineSkippingEmpty(scanner).split(" "))
                    .filter(s -> !s.isEmpty())
                    .mapToInt(Integer::parseInt)
                    .toArray();
        }

        String[][] outputs = new String[numStates][];
        for (int i = 0; i < numStates; i++) {
            outputs[i] = Arrays.stream(readLineSkippingEmpty(scanner).split(" "))
                    .filter(s -> !s.isEmpty())
                    .toArray(String[]::new);
        }

        int startState = Integer.parseInt(readLineSkippingEmpty(scanner));
        int maxLength = Integer.parseInt(readLineSkippingEmpty(scanner));

        Set<String> result = new TreeSet<>();
        Queue<Node> queue = new ArrayDeque<>();
        queue.offer(new Node(startState, ""));

        while (!queue.isEmpty()) {
            Node current = queue.poll();

            if (current.word.length() > maxLength) continue;
            if (!current.word.isEmpty()) {
                result.add(current.word);
            }

            int inputsCount = transitions[current.state].length;
            for (int input = 0; input < inputsCount; input++) {
                int nextState = transitions[current.state][input];
                String out = outputs[current.state][input];
                String nextWord = out.equals("-") ? current.word : current.word + out;
                queue.offer(new Node(nextState, nextWord));
            }
        }

        for (String word : result) {
            System.out.println(word);
        }
    }

    static String readLineSkippingEmpty(Scanner scanner) {
        String line;
        do {
            line = scanner.nextLine().trim();
        } while (line.isEmpty());
        return line;
    }

    static class Node {
        int state;
        String word;

        Node(int state, String word) {
            this.state = state;
            this.word = word;
        }
    }
}
