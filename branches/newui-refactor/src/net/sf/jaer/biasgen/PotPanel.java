/*
 * PotPanel.java
 *
 * Created on September 21, 2005, 11:18 AM
 */
package net.sf.jaer.biasgen;
import java.awt.Color;
import java.awt.Component;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.event.FocusEvent;
import java.awt.event.FocusListener;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.logging.Logger;

import javax.swing.AbstractButton;
import javax.swing.BoxLayout;
import javax.swing.JComboBox;
import javax.swing.JComponent;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSlider;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.border.Border;
import javax.swing.border.LineBorder;
import javax.swing.table.TableCellRenderer;
/**
 * Panel for controlling a chip's set of Pots over a HardwareInterface.
 * @author  tobi
 */
public class PotPanel extends javax.swing.JPanel implements FocusListener {
    static Logger log=Logger.getLogger("PotPanel");
    public PotArray pots=null;
    JScrollPane scrollPane=null;
    JPanel potsPanel;
    ArrayList<Pot> potList;
    ArrayList<JComponent> componentList;
    final Border selectedBorder=new LineBorder(Color.red, 1), unselectedBorder=null; // new EmptyBorder(1,1,1,1);
    /**
     * Creates new form PotPanel
     */
    public PotPanel(PotArray ipotArray) {
        pots=ipotArray;
        initComponents();
        getInsets().set(0, 0, 0, 0);
        buildPanel();
    }//    JTable table;
//
//    class PotTable extends JTable{
//        private PotPanel panel;
//        private PotArray pots;
//        TableModel model;
//        public PotTable(TableModel m,PotPanel p){
//            super(m);
//            panel=p;
//            model=m;
//        }
//    }

    private void addBorderSetter(final JComponent s) {
        if (s instanceof JTextField || s instanceof JSlider || s instanceof JComboBox || s instanceof AbstractButton) {
            s.setFocusable(true);// sliders and combo boxes not normally focusable
            s.addFocusListener(this);
//            log.info("added border setter for "+s.getClass().getSimpleName());
        } else if (s instanceof Container) {
            Component[] components = s.getComponents();
            for (Component c : components) {
//                log.info("possibly adding border setter for "+c.getClass().getSimpleName());
                if (c instanceof JComponent) {
                    addBorderSetter((JComponent) c);
                }
            }
        }
    }
    
    class MyRenderer implements TableCellRenderer {
        public java.awt.Component getTableCellRendererComponent(JTable jTable, Object obj, boolean param, boolean param3, int param4, int param5) {
            return null;
        }
    }

    /** builds the panel of pots */
    private void buildPanel() {
        IPotSliderTextControl.allInstances.clear();
        potList=new ArrayList<Pot>(pots.getPots());
        componentList=new ArrayList<JComponent>();
        Collections.sort(potList, new PotDisplayComparator());
        potsPanel=new JPanel();
        potsPanel.getInsets().set(0, 0, 0, 0);
        potsPanel.setLayout(new BoxLayout(potsPanel, BoxLayout.Y_AXIS));
        scrollPane=new JScrollPane(potsPanel);
        add(new PotSorter(componentList, potList));
        add(scrollPane);
        for(Pot p : potList) {
            JComponent s=p.makeGUIPotControl(); // make a bias control gui component
            potsPanel.add(s);
            componentList.add(s);
            addBorderSetter(s);
        }
        JPanel fillPanel=new JPanel();
        fillPanel.setMinimumSize(new Dimension(0, 0));
        fillPanel.setPreferredSize(new Dimension(0, 0));
        fillPanel.setMaximumSize(new Dimension(32767, 32767));
        potsPanel.add(fillPanel); // spacer at bottom so biases don't stretch out too much
    }
    private class PotDisplayComparator implements Comparator<Pot> {
        public int compare(Pot p1, Pot p2) {
            if(p1.getDisplayPosition()<p2.getDisplayPosition()) {
                return -1;
            }
            if(p1.getDisplayPosition()==p2.getDisplayPosition()) {
                return 0;
            }
            return 1;
        }

        public boolean equals(IPot p1, IPot p2) {
            if(p1.getDisplayPosition()==p2.getDisplayPosition()) {
                return true;
            } else {
                return false;
            }
        }
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        setBorder(javax.swing.BorderFactory.createTitledBorder("IPot Array"));
        setToolTipText("");
        setLayout(new javax.swing.BoxLayout(this, javax.swing.BoxLayout.Y_AXIS));
    }// </editor-fold>//GEN-END:initComponents

    private void jButton1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton1ActionPerformed
    }//GEN-LAST:event_jButton1ActionPerformed

    private void filterBiasnameTextFieldKeyTyped(java.awt.event.KeyEvent evt) {//GEN-FIRST:event_filterBiasnameTextFieldKeyTyped
    }//GEN-LAST:event_filterBiasnameTextFieldKeyTyped
    // Variables declaration - do not modify//GEN-BEGIN:variables
    // End of variables declaration//GEN-END:variables
    public PotArray getPots() {
        return this.pots;
    }

    public void setPots(final PotArray pots) {
        this.pots=pots;
        buildPanel();
    }

    public void focusGained(FocusEvent e) { // some control sends this event, color the pot control border red for that control and others blank
        Component src=e.getComponent();
//        log.info("focus gained by "+src.getClass().getSimpleName());
        Component potControl=null;
        do{
            Component parent=src.getParent();
            if(componentList.contains(parent)) {
                potControl=parent;
                break;
            }
            src=parent;
        }while(src!=null);
        for(JComponent c:componentList){
            if(c==potControl){
                c.setBorder(selectedBorder);
            }else{
                c.setBorder(unselectedBorder);
           }
        }
    }

    public void focusLost(FocusEvent e) {
    }
}
