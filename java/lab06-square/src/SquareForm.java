import javax.swing.*;
import javax.swing.event.ChangeListener;
import java.awt.*;

public class SquareForm {
    private JPanel mainPanel;
    private JPanel controlPanel;
    private JSpinner countSpinner;
    private JSpinner sizeSpinner;
    private JButton generateButton;
    private CanvasPanel canvasPanel;

    public SquareForm() {
        ChangeListener listener = e -> updateSquares();
        countSpinner.addChangeListener(listener);
        sizeSpinner.addChangeListener(listener);

        generateButton.addActionListener(e -> updateSquares());
        SwingUtilities.invokeLater(this::updateSquares);
    }

    private void updateSquares() {
        int count = (int) countSpinner.getValue();
        int size = (int) sizeSpinner.getValue();
        canvasPanel.generateSquares(count, size);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("Разноцветные квадраты");
            SquareForm squareForm = new SquareForm();
            frame.setContentPane(squareForm.mainPanel);
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.pack();
            frame.setVisible(true);
        });
    }
}
