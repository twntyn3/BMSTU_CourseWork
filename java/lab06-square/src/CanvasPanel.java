import javax.swing.*;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.Random;

public class CanvasPanel extends JPanel {
    private final ArrayList<Square> squares = new ArrayList<>();
    private final Random random = new Random();
    private static class Square {
        int x, y, size;
        Color color;

        Square(int x, int y, int size, Color color) {
            this.x = x;
            this.y = y;
            this.size = size;
            this.color = color;
        }
    }
    public CanvasPanel() {
        setBackground(Color.WHITE);
        setPreferredSize(new Dimension(500, 500));
        initMouseListener();
    }

    private void initMouseListener() {
        addMouseListener(new MouseAdapter() {
            public void mouseClicked(MouseEvent e) {
                removeSquareAt(e.getX(), e.getY());
            }
        });
    }
    public void generateSquares(int count, int size) {
        squares.clear();
        if (getWidth() < size || getHeight() < size) {
            return;
        }

        for (int i = 0; i < count; i++) {
            addRandomSquare(size);
        }
        repaint();
    }
    private void addRandomSquare(int size) {
        int width = getWidth();
        int height = getHeight();
        if (width <= size || height <= size) {
            return;
        }
        int x = random.nextInt(width - size);
        int y = random.nextInt(height - size);
        Color color = new Color(
                random.nextInt(256),
                random.nextInt(256),
                random.nextInt(256)
        );
        squares.add(new Square(x, y, size, color));
    }

    private void removeSquareAt(int x, int y) {
        squares.removeIf(sq ->
                x >= sq.x && x <= sq.x + sq.size &&
                        y >= sq.y && y <= sq.y + sq.size
        );
        repaint();
    }
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        for (Square sq : squares) {
            g.setColor(sq.color);
            g.fillRect(sq.x, sq.y, sq.size, sq.size);
            g.setColor(Color.BLACK);
            g.drawRect(sq.x, sq.y, sq.size, sq.size);
        }
    }
}
