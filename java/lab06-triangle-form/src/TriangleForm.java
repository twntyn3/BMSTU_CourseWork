import javax.swing.*;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.awt.*;

public class TriangleForm {
    private JPanel mainPanel;
    private JSpinner sideASpinner;
    private JSpinner sideBSpinner;
    private JSpinner sideCSpinner;
    private JTextField anglesField;
    private CanvasPanel canvasPanel;

    public TriangleForm() {
        sideASpinner.setValue(50);
        sideBSpinner.setValue(50);
        sideCSpinner.setValue(50);

        ChangeListener listener = new ChangeListener() {
            public void stateChanged(ChangeEvent e) {
                updateTriangle();
            }
        };

        sideASpinner.addChangeListener(listener);
        sideBSpinner.addChangeListener(listener);
        sideCSpinner.addChangeListener(listener);

        updateTriangle();
    }

    private void updateTriangle() {
        int a = (int) sideASpinner.getValue();
        int b = (int) sideBSpinner.getValue();
        int c = (int) sideCSpinner.getValue();

        if (canvasPanel != null) {
            canvasPanel.setSides(a, b, c);
        }

        if (a + b > c && a + c > b && b + c > a) {
            double angleA = Math.toDegrees(Math.acos((b*b + c*c - a*a) / (2.0 * b * c)));
            double angleB = Math.toDegrees(Math.acos((a*a + c*c - b*b) / (2.0 * a * c)));
            double angleC = 180 - angleA - angleB;

            anglesField.setText(String.format("A=%.1f°, B=%.1f°, C=%.1f°", angleA, angleB, angleC));
        } else {
            anglesField.setText("Error");
        }
    }

    public static void main(String[] args) {
        JFrame frame = new JFrame("Треугольник");
        frame.setContentPane(new TriangleForm().mainPanel);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }
}
