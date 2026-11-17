import javax.swing.*;
import java.awt.*;

public class CanvasPanel extends JPanel {
    private int sideA = 50, sideB = 50, sideC = 50; // Начальные значения

    public CanvasPanel() {
        setPreferredSize(new Dimension(300, 300));
        setBackground(Color.WHITE);
    }

    public void setSides(int a, int b, int c) {
        if (isValidTriangle(a, b, c)) {
            this.sideA = a;
            this.sideB = b;
            this.sideC = c;
            repaint();
        } else {
            System.out.println("Некорректные стороны треугольника");
        }
    }

    private boolean isValidTriangle(int a, int b, int c) {
        return a + b > c && a + c > b && b + c > a;
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);

        if (!isValidTriangle(sideA, sideB, sideC)) {
            return; // Не рисуем, если стороны не образуют треугольник
        }

        // Начальная точка
        int x1 = 100, y1 = 200;
        int x2 = x1 + sideA * 5;
        int y2 = y1;

        // Вычисление углов
        double angleA = Math.toDegrees(Math.acos((sideB * sideB + sideC * sideC - sideA * sideA) / (2.0 * sideB * sideC)));
        double angleB = Math.toDegrees(Math.acos((sideA * sideA + sideC * sideC - sideB * sideB) / (2.0 * sideA * sideC)));
        double angleC = 180 - angleA - angleB;

        // Преобразуем углы в цвет (0° → 0, 180° → 255)
        int red = (int) (angleA / 180 * 255);
        int green = (int) (angleB / 180 * 255);
        int blue = (int) (angleC / 180 * 255);

        // Вычисление третьей вершины
        double angleRad = Math.acos((sideA * sideA + sideC * sideC - sideB * sideB) / (2.0 * sideA * sideC));
        int x3 = x1 + (int) (sideC * 5 * Math.cos(angleRad));
        int y3 = y1 - (int) (sideC * 5 * Math.sin(angleRad));

        int[] xPoints = {x1, x2, x3};
        int[] yPoints = {y1, y2, y3};

        g.setColor(new Color(red, green, blue)); // Устанавливаем цвет
        g.fillPolygon(xPoints, yPoints, 3);
    }
}
