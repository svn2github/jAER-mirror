/*
 * BiasgenPanel.java
 *
 * Created on September 24, 2005, 10:05 PM
 */

package ch.unizh.ini.caviar.biasgen;

/**
 * A panel for controlling a biasgen, with a masterbias and an IPotArray. This is added to the content panel of BiasgenApp.
 *
 * @author  tobi
 */
public class BiasgenPanel extends javax.swing.JPanel {
    public Biasgen biasgen;
    MasterbiasPanel masterbiasPanel;
    PotPanel iPotPanel;
    BiasgenFrame frame;
    
    /** Creates new form BiasgenPanel */
    public BiasgenPanel(Biasgen biasgen, BiasgenFrame frame) {
        this.biasgen=biasgen;
        this.frame=frame;
        if(biasgen==null) throw new RuntimeException("null biasgen while trying to construct BiasgenPanel");
        masterbiasPanel=new MasterbiasPanel(biasgen.getMasterbias());
        iPotPanel=new PotPanel(biasgen.getPotArray(),frame);
        
        initComponents();
        add(jTabbedPane1);
        jTabbedPane1.addTab("IPots",iPotPanel);
        if(biasgen instanceof FunctionalBiasgen){
            jTabbedPane1.addTab("Functional biases",((FunctionalBiasgen)biasgen).getControlPanel());
        }
        jTabbedPane1.addTab("Masterbias",masterbiasPanel);
    }
    
    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc=" Generated Code ">//GEN-BEGIN:initComponents
    private void initComponents() {
        jTabbedPane1 = new javax.swing.JTabbedPane();

        setLayout(new javax.swing.BoxLayout(this, javax.swing.BoxLayout.Y_AXIS));

        setBorder(new javax.swing.border.TitledBorder("Biasgen"));
    }
    // </editor-fold>//GEN-END:initComponents
    
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JTabbedPane jTabbedPane1;
    // End of variables declaration//GEN-END:variables
    
    
    public Biasgen getBiasgen() {
        return this.biasgen;
    }
    
    public void setBiasgen(final Biasgen biasgen) {
        this.biasgen = biasgen;
    }
}
