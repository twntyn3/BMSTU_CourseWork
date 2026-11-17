import javax.swing.*;
import java.awt.*;

public class CanvasPanel extends JPanel {
    private int sideA = 50, sideB = 50, sideC = 50;
    private double angleA = 60, angleB = 60, angleC = 60;
    public void setSides(int a, int b, int c) {
        if (isValidTriangle(a, b, c)) {
            this.sideA = a;
            this.sideB = b;
            this.sideC = c;
            calculateAngles();
            repaint();
        } else {
            System.out.println("Error");
        }
    }
    private void calculateAngles() {
        angleA = Math.toDegrees(Math.acos((sideB * sideB + sideC * sideC - sideA * sideA) / (2.0 * sideB * sideC)));
        angleB = Math.toDegrees(Math.acos((sideA * sideA + sideC * sideC - sideB * sideB) / (2.0 * sideA * sideC)));
        angleC = 180 - angleA - angleB;
    }

    private boolean isValidTriangle(int a, int b, int c) {
        return a + b > c && a + c > b && b + c > a;
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);

        if (!isValidTriangle(sideA, sideB, sideC)) return;

        int panelWidth = getWidth();
        int panelHeight = getHeight();
        int centerX = panelWidth / 2;
        int centerY = panelHeight / 2;

        int scale = 5;

        int x1 = centerX - (sideA * scale) / 2;
        int y1 = centerY + (sideB * scale) / 2;
        int x2 = x1 + sideA * scale;
        int y2 = y1;

        double angleRad = Math.acos((sideA * sideA + sideC * sideC - sideB * sideB) / (2.0 * sideA * sideC));
        int x3 = x1 + (int) (sideC * scale * Math.cos(angleRad));
        int y3 = y1 - (int) (sideC * scale * Math.sin(angleRad));

        // Преобразование углов в RGB
        int red = (int) ((angleA / 180) * 255);
        int green = (int) ((angleB / 180) * 255);
        int blue = (int) ((angleC / 180) * 255);
        g.setColor(new Color(red, green, blue));
        g.fillPolygon(new int[]{x1, x2, x3}, new int[]{y1, y2, y3}, 3);
    }
}
