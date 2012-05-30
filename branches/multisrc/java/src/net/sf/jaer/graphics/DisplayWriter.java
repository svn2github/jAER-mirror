/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.graphics;

import javax.swing.JPanel;

/**
 * A class implementing this interface has some means to display its state to the screen.
 * 
 * Generally, a GUI class with either implement this class or contain object(s) 
 * of this class as fields.
 * 
 * 
 * @author Peter
 */
public interface DisplayWriter {
    
    /**
     * Set the object as being watched.  This may do nothing, but certain things
     * may change in the object if it is being watched.
     * @param displayed 
     */
    void setWatched(boolean displayed);
    
    void setPanel(JPanel imagePanel);
    
    JPanel getPanel();
    
    void display();
    
}
