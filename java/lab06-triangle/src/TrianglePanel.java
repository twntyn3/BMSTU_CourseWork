import javax.swing.*;
import java.awt.*;

public class TrianglePanel extends JPanel {

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);

        Graphics2D g2d = (Graphics2D) g;
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        int[] xPoints = {getWidth() / 2, 50, getWidth() - 50};
        int[] yPoints = {50, getHeight() - 50, getHeight() - 50};

        double angleA = 60;
        double angleB = 60;
        double angleC = 60;


        int red = (int) (angleA / 180 * 255);
        int green = (int) (angleB / 180 * 255);
        int blue = (int) (angleC / 180 * 255);
        Color triangleColor = new Color(red, green, blue);
        g2d.setColor(triangleColor);
        g2d.fillPolygon(xPoints, yPoints, 3);
    }
}
