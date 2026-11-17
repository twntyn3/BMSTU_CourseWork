import javax.swing.*;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.awt.*;

public class PictureForm {
    private JPanel mainPanel;
    private JSpinner radiusSpinner;
    private JTextField areaField;
    private CanvasPanel canvasPanel;
    private JLabel radiusLabel;  // Добавлено
    private JLabel areaLabel;    // Добавлено

    public PictureForm() {
        // Установка начального значения радиуса
        radiusSpinner.setValue(20);

        // Обработчик изменения радиуса
        radiusSpinner.addChangeListener(new ChangeListener() {
            @Override
            public void stateChanged(ChangeEvent e) {
                int radius = (int) radiusSpinner.getValue();
                canvasPanel.setRadius(radius);

                // Вычисляем площадь круга
                double area = Math.PI * radius * radius;
                areaField.setText(String.format("%.2f", area));
            }
        });
    }

    public static void main(String[] args) {
        JFrame frame = new JFrame("Окружность");
        frame.setContentPane(new PictureForm().mainPanel);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }
}

