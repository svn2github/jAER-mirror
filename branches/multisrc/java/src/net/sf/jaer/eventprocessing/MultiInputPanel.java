/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing;

import java.util.ArrayList;
import javax.swing.BoxLayout;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;

/**
 *
 * @author Peter
 */
public class MultiInputPanel extends FilterPanel {
    
//    ArrayList<PacketStream> sources=new ArrayList();
   
    ProcessingNetwork.Node node;
    
    public MultiInputPanel(ProcessingNetwork.Node p) {
        super(p.filt);
        node=p;
    }
           
        
    public String[] getSourceNames()
    {
        ArrayList<PacketStream> sources=node.getSourceOptions();
        
        String[] names=new String[sources.size()];
        for (int i=0; i<sources.size();i++)
            names[i]=sources.get(i).getName();
        
        return names;
    }
    
    
    
    /** Add a list of select boxes for choosing your source */
    public void addSources()
    {
//        this.setLayout(new BoxLayout(this));
//        this.setLayout(new GridBagLayout());
//        this.setLayout(new FlowLayout());
        
//        GridBagConstraints c=new GridBagConstraints();
        
        String[] inputNames=node.getInputNames();
        for (int i=0; i<node.nInputs(); i++)
        {
            add(new SourceControl(getSourceNames(),node,inputNames[i]));
        }
               
    }
        
    
    class SourceControl extends JPanel {

        ProcessingNetwork.Node filter;
        boolean initValue = false, nval;
        final JComboBox control;

        public void set(Object o) {
            control.setSelectedItem(o);
        }

        public SourceControl(final String[] c, final ProcessingNetwork.Node f, final String name) {
            super();
            filter = f;
            setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
            setAlignmentX(ALIGNMENT);
            final JLabel label = new JLabel(name);
            label.setAlignmentX(ALIGNMENT);
            label.setFont(label.getFont().deriveFont(fontSize));
//            addTip(f, label);
            add(label);

            control = new JComboBox(c);
            control.setFont(control.getFont().deriveFont(fontSize));
//            control.setHorizontalAlignment(SwingConstants.LEADING);

            add(label);
            add(control);
//            try {
//                Object x = (Object) r.invoke(filter);
//                if (x == null) {
//                    log.warning("null Object returned from read method " + r);
//                    return;
//                }
//                control.setSelectedItem(x);
//            } catch (Exception e) {
//                log.warning("cannot access the field named " + name + " is the class or method not public?");
//                e.printStackTrace();
//            }
//            control.addActionListener(new ActionListener() {
//
//                public void actionPerformed(ActionEvent e) {
//                    try {
//                        w.invoke(filter, control.getSelectedItem());
//                    } catch (Exception e2) {
//                        e2.printStackTrace();
//                    }
//                }
//            });
        }
    }
    
    
    
}
