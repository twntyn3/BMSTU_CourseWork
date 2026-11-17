import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.ArrayList;
import java.util.Random;

public class SquareRemoverApp extends JFrame {
    private final int SQUARE_SIZE = 50; // Размер квадратов
    private final int SQUARE_COUNT = 20; // Количество квадратов
    private final ArrayList<Rectangle> squares = new ArrayList<>(); // Список квадратов
    private final ArrayList<Color> colors = new ArrayList<>(); // Список цветов

    public SquareRemoverApp() {
        setTitle("Удаление квадратов");
        setSize(600, 600);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null); // Центрируем окно
        generateSquares();

        // Добавляем слушатель мыши для удаления квадратов
        addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                removeSquare(e.getX(), e.getY());
            }
        });

        setVisible(true);
    }

    // Генерация случайных квадратов
    private void generateSquares() {
        squares.clear();
        colors.clear();
        Random rand = new Random();

        for (int i = 0; i < SQUARE_COUNT; i++) {
            int x = rand.nextInt(getWidth() - SQUARE_SIZE);
            int y = rand.nextInt(getHeight() - SQUARE_SIZE);
            squares.add(new Rectangle(x, y, SQUARE_SIZE, SQUARE_SIZE));
            colors.add(new Color(rand.nextInt(256), rand.nextInt(256), rand.nextInt(256))); // Рандомный цвет
        }
    }

    // Метод удаления квадрата по координатам клика
    private void removeSquare(int x, int y) {
        for (int i = 0; i < squares.size(); i++) {
            if (squares.get(i).contains(x, y)) {
                squares.remove(i);
                colors.remove(i);
                repaint(); // Перерисовываем окно
                break;
            }
        }
    }

    // Отрисовка квадратов
    @Override
    public void paint(Graphics g) {
        super.paint(g);
        for (int i = 0; i < squares.size(); i++) {
            g.setColor(colors.get(i));
            Rectangle rect = squares.get(i);
            g.fillRect(rect.x, rect.y, rect.width, rect.height);
        }
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(SquareRemoverApp::new);
    }
}
