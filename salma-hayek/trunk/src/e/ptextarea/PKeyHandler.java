package e.ptextarea;


import java.awt.*;
import java.awt.event.*;

public class PKeyHandler extends KeyAdapter {
    private PTextArea textArea;
    
    public PKeyHandler(PTextArea textArea) {
        this.textArea = textArea;
    }
    
    public void keyPressed(KeyEvent event) {
        long startTime = System.currentTimeMillis();
        if (event.isControlDown()) {
            switch (event.getKeyCode()) {
            case KeyEvent.VK_T: textArea.printLineInfo(); break;
            case KeyEvent.VK_L: textArea.getLineList().printLineInfo(); break;
            case KeyEvent.VK_R: textArea.repaint(); break;
            case KeyEvent.VK_I:
                {
                    int caret = textArea.getCaretLocation();
                    String insertion = "Insertion\nof some\ntext";
                    textArea.getText().insert(caret, insertion.toCharArray());
                    textArea.setCaretLocation(caret + insertion.length());
                }
                break;
            case KeyEvent.VK_D:
                {
                    int caret = textArea.getCaretLocation();
                    int delCount = Math.min(caret, 20);
                    textArea.getText().delete(caret - delCount, delCount);
                    textArea.setCaretLocation(caret - delCount);
                }
                break;
                
            case KeyEvent.VK_H:
                {
                    int caret = textArea.getCaretLocation();
                    int end = Math.min(caret + 20, textArea.getText().length());
                    textArea.addHighlight(new PColoredHighlight(textArea, caret, end, Color.yellow));
                }
                break;
                
            case KeyEvent.VK_A:
                {
                    if (event.isShiftDown()) {
                        textArea.removeHighlights(new PColoredHighlightMatcher(Color.cyan));
                    } else {
                        for (int i = 0; i < textArea.getText().length() - 4; i += 4) {
                            textArea.addHighlight(new PColoredHighlight(textArea, i, i + 2, Color.cyan));
                        }
                    }
                }
            }
        }
//        System.err.println("keyPressed took " + (System.currentTimeMillis() - startTime) + "ms.");
    }
    
    public class PColoredHighlightMatcher implements PHighlightMatcher {
        private Color color;
        
        public PColoredHighlightMatcher(Color color) {
            this.color = color;
        }
        
        public boolean matches(PHighlight highlight) {
            if (highlight instanceof PColoredHighlight) {
                return ((PColoredHighlight) highlight).getColor().equals(color);
            } else {
                return false;
            }
        }
    }
    
    public void keyTyped(KeyEvent event) {
        long startTime = System.currentTimeMillis();
        char key = event.getKeyChar();
        int caretLocation = textArea.getCaretLocation();
        if (event.isControlDown()) {
            // Do nothing.
        } else if (key == KeyEvent.VK_BACK_SPACE) {
            if (caretLocation > 0) {
                caretLocation -= 1;
                textArea.getText().delete(caretLocation, 1);
                textArea.setCaretLocation(caretLocation);
            }
        } else if (key != KeyEvent.CHAR_UNDEFINED && event.isControlDown() == false) {
            textArea.getText().insert(textArea.getCaretLocation(), new char[] { key });
            textArea.setCaretLocation(caretLocation + 1);
        }
        System.err.println("keyTyped took " + (System.currentTimeMillis() - startTime) + "ms.");
    }
}
