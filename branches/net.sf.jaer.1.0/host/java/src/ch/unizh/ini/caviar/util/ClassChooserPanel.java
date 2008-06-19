/*
 * ClassChooserPanel2.java
 *
 * Created on May 13, 2007, 3:46 PM
 */
package ch.unizh.ini.caviar.util;
import ch.unizh.ini.caviar.chip.AEChip;
import ch.unizh.ini.caviar.eventprocessing.EventFilter;
import java.awt.event.ActionEvent;
import java.awt.event.FocusEvent;
import java.awt.event.FocusListener;
import java.awt.event.KeyEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Vector;
import javax.swing.AbstractAction;
import javax.swing.Action;
import javax.swing.DefaultListModel;
import javax.swing.InputMap;
import javax.swing.JList;
import javax.swing.KeyStroke;
import javax.swing.event.ListDataEvent;
import javax.swing.event.ListDataListener;
/**
 * A panel that finds subclasses of a class, displays them in a left list, displays another list given as a parameter
in the right panel, and accepts a list of default class names. The user can choose which classes and these are returned
by a call to getList.

 * @author  tobi
 */
public class ClassChooserPanel extends javax.swing.JPanel {
    FilterableListModel chosenClassesListModel, availClassesListModel;
    ArrayList<String> revertCopy, defaultClassNames, availAllList, availFiltList;

    /** Creates new form ClassChooserPanel2
    
    @param subclassOf a Class that will be used to search the classpath for leaf nodes of this type.
    @param classNames a list of names
    @param defaultClassNames the list on the right is replaced by this lixt if the user pushes the Defaults button.
    
     */
    public ClassChooserPanel(Class subclassOf, ArrayList<String> classNames, ArrayList<String> defaultClassNames) {
        initComponents();
        availFilterTextField.requestFocusInWindow();
        this.defaultClassNames=defaultClassNames;
        availAllList=SubclassFinder.findSubclassesOf(subclassOf.getName());
        availClassesListModel=new FilterableListModel(availAllList);
        availClassJList.setModel(availClassesListModel);
        Action addAction=new AbstractAction() {
            public void actionPerformed(ActionEvent e) {
                Object o=availClassJList.getSelectedValue();
                if(o==null) {
                    return;
                }
                int last=chosenClassesListModel.getSize()-1;
                chosenClassesListModel.add(last+1, o);
                classJList.setSelectedIndex(last+1);
            }
        };
        addAction(availClassJList, addAction);
        Action removeAction=new AbstractAction() {
            public void actionPerformed(ActionEvent e) {
                int index=classJList.getSelectedIndex();
                chosenClassesListModel.removeElementAt(index);
                int size=chosenClassesListModel.getSize();

                if(size==0) { //Nobody's left, disable firing.

                    removeClassButton.setEnabled(false);

                } else { //Select an index.

                    if(index==chosenClassesListModel.getSize()) {
                        //removed item in last position
                        index--;
                    }

                    classJList.setSelectedIndex(index);
                    classJList.ensureIndexIsVisible(index);
                }
            }
        };
        addAction(classJList, removeAction);

        revertCopy=new ArrayList<String>(classNames);
        chosenClassesListModel=new FilterableListModel(classNames);
        classJList.setModel(chosenClassesListModel);
    }
    // extends DefaultListModel to add a text filter
    class FilterableListModel extends DefaultListModel {
        Vector origList=new Vector();
        String filterString=null;

        FilterableListModel(List<String> list) {
            super();
            for(String s : list) {
                this.addElement(s);
            }
            origList.addAll(list);
        }

        synchronized void resetList() {
            clear();
            for(Object o : origList) {
                addElement(o);
            }

        }

        synchronized void filter(String s) {
            filterString=s.toLowerCase();
            resetList();
            if(s==null||s.equals("")) {
                return;
            }
            Vector v=new Vector();  // list to prune out
            // must build a list of stuff to prune, then prune

            Enumeration en=elements();
            while(en.hasMoreElements()) {
                Object o=en.nextElement();
                String st=((String) o).toLowerCase();
                int ind=st.indexOf(filterString);
                if(ind==-1) {
                    v.add(o);
                }
            }
            // prune list
            for(Object o : v) {
                removeElement(o);
            }
        }

        synchronized void clearFilter() {
            filter(null);
        }
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jPanel1 = new javax.swing.JPanel();
        jScrollPane1 = new javax.swing.JScrollPane();
        availClassJList = new javax.swing.JList();
        jLabel1 = new javax.swing.JLabel();
        availFilterTextField = new javax.swing.JTextField();
        jPanel2 = new javax.swing.JPanel();
        jScrollPane2 = new javax.swing.JScrollPane();
        classJList = new javax.swing.JList();
        addClassButton = new javax.swing.JButton();
        removeClassButton = new javax.swing.JButton();
        moveUpButton = new javax.swing.JButton();
        moveDownButton = new javax.swing.JButton();
        revertButton = new javax.swing.JButton();
        removeAllButton = new javax.swing.JButton();
        defaultsButton = new javax.swing.JButton();

        jPanel1.setBorder(javax.swing.BorderFactory.createTitledBorder("Available classes"));

        jScrollPane1.setPreferredSize(new java.awt.Dimension(200, 100));

        availClassJList.setToolTipText("If your class doesn't show up here, rebuild the project to get it into jAER.jar (or some other jar on the classpath)");
        jScrollPane1.setViewportView(availClassJList);

        jLabel1.setText("Filter");

        availFilterTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                availFilterTextFieldActionPerformed(evt);
            }
        });
        availFilterTextField.addKeyListener(new java.awt.event.KeyAdapter() {
            public void keyTyped(java.awt.event.KeyEvent evt) {
                availFilterTextFieldKeyTyped(evt);
            }
        });

        javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 373, Short.MAX_VALUE)
                    .addGroup(jPanel1Layout.createSequentialGroup()
                        .addComponent(jLabel1)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(availFilterTextField, javax.swing.GroupLayout.PREFERRED_SIZE, 160, javax.swing.GroupLayout.PREFERRED_SIZE)))
                .addContainerGap())
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(availFilterTextField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 388, Short.MAX_VALUE)
                .addContainerGap())
        );

        jPanel2.setBorder(javax.swing.BorderFactory.createTitledBorder("Class list"));

        jScrollPane2.setPreferredSize(new java.awt.Dimension(200, 100));

        classJList.setSelectionMode(javax.swing.ListSelectionModel.SINGLE_SELECTION);
        classJList.setToolTipText("These filters will appear in the FilterFrame and can be enabled");
        classJList.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                classJListMouseClicked(evt);
            }
        });
        classJList.addInputMethodListener(new java.awt.event.InputMethodListener() {
            public void caretPositionChanged(java.awt.event.InputMethodEvent evt) {
                classJListCaretPositionChanged(evt);
            }
            public void inputMethodTextChanged(java.awt.event.InputMethodEvent evt) {
            }
        });
        jScrollPane2.setViewportView(classJList);

        javax.swing.GroupLayout jPanel2Layout = new javax.swing.GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel2Layout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addComponent(jScrollPane2, javax.swing.GroupLayout.PREFERRED_SIZE, 344, javax.swing.GroupLayout.PREFERRED_SIZE))
        );
        jPanel2Layout.setVerticalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel2Layout.createSequentialGroup()
                .addComponent(jScrollPane2, javax.swing.GroupLayout.DEFAULT_SIZE, 414, Short.MAX_VALUE)
                .addContainerGap())
        );

        addClassButton.setMnemonic('a');
        addClassButton.setText("Add");
        addClassButton.setToolTipText("Add the filter to the list of available filters");
        addClassButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                addClassButtonActionPerformed(evt);
            }
        });

        removeClassButton.setMnemonic('r');
        removeClassButton.setText("Remove");
        removeClassButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                removeClassButtonActionPerformed(evt);
            }
        });

        moveUpButton.setMnemonic('u');
        moveUpButton.setText("Move up");
        moveUpButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                moveUpButtonActionPerformed(evt);
            }
        });

        moveDownButton.setMnemonic('d');
        moveDownButton.setText("Move down");
        moveDownButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                moveDownButtonActionPerformed(evt);
            }
        });

        revertButton.setMnemonic('e');
        revertButton.setText("Revert");
        revertButton.setToolTipText("Revert changes to the list");
        revertButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                revertButtonActionPerformed(evt);
            }
        });

        removeAllButton.setText("Remove all");
        removeAllButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                removeAllButtonActionPerformed(evt);
            }
        });

        defaultsButton.setMnemonic('d');
        defaultsButton.setText("Defaults");
        defaultsButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                defaultsButtonActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(addClassButton)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jPanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(removeAllButton, javax.swing.GroupLayout.DEFAULT_SIZE, 87, Short.MAX_VALUE)
                    .addComponent(defaultsButton, javax.swing.GroupLayout.DEFAULT_SIZE, 87, Short.MAX_VALUE)
                    .addComponent(moveUpButton, javax.swing.GroupLayout.DEFAULT_SIZE, 87, Short.MAX_VALUE)
                    .addComponent(moveDownButton, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(removeClassButton)
                    .addComponent(revertButton, javax.swing.GroupLayout.DEFAULT_SIZE, 87, Short.MAX_VALUE))
                .addContainerGap())
        );

        layout.linkSize(javax.swing.SwingConstants.HORIZONTAL, new java.awt.Component[] {defaultsButton, moveDownButton, moveUpButton, removeAllButton, removeClassButton, revertButton});

        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(172, 172, 172)
                .addComponent(addClassButton)
                .addContainerGap(282, Short.MAX_VALUE))
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jPanel2, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jPanel1, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addGap(109, 109, 109)
                .addComponent(moveUpButton)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(moveDownButton)
                .addGap(33, 33, 33)
                .addComponent(removeClassButton)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(removeAllButton)
                .addGap(64, 64, 64)
                .addComponent(revertButton)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 63, Short.MAX_VALUE)
                .addComponent(defaultsButton)
                .addGap(58, 58, 58))
        );
    }// </editor-fold>//GEN-END:initComponents

    private void availFilterTextFieldKeyTyped(java.awt.event.KeyEvent evt) {//GEN-FIRST:event_availFilterTextFieldKeyTyped
        String s=availFilterTextField.getText();
        availClassesListModel.filter(s);
    }//GEN-LAST:event_availFilterTextFieldKeyTyped

    private void availFilterTextFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_availFilterTextFieldActionPerformed
        String s=availFilterTextField.getText();
        availClassesListModel.filter(s);
    }//GEN-LAST:event_availFilterTextFieldActionPerformed

    private void defaultsButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_defaultsButtonActionPerformed
        chosenClassesListModel.clear();
        for(String s : defaultClassNames) {
            chosenClassesListModel.addElement(s);
        }
    }//GEN-LAST:event_defaultsButtonActionPerformed

    private void removeAllButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_removeAllButtonActionPerformed
        chosenClassesListModel.clear();
    }//GEN-LAST:event_removeAllButtonActionPerformed

    private void revertButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_revertButtonActionPerformed
        chosenClassesListModel.clear();
        for(String s : revertCopy) {
            chosenClassesListModel.addElement(s);
        }
    }//GEN-LAST:event_revertButtonActionPerformed

    private void addClassButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_addClassButtonActionPerformed
        Object o=availClassJList.getSelectedValue();
        if(o==null) {
            return;
        }
        int last=chosenClassesListModel.getSize()-1;
        chosenClassesListModel.add(last+1, o);
        classJList.setSelectedIndex(last+1);
    }//GEN-LAST:event_addClassButtonActionPerformed

    private void moveDownButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_moveDownButtonActionPerformed
        int last=chosenClassesListModel.getSize()-1;
        int index=classJList.getSelectedIndex();
        if(index==last) {
            return;
        }
        Object o=chosenClassesListModel.getElementAt(index);
        chosenClassesListModel.removeElementAt(index);
        chosenClassesListModel.insertElementAt(o, index+1);
        classJList.setSelectedIndex(index+1);
    }//GEN-LAST:event_moveDownButtonActionPerformed

    private void moveUpButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_moveUpButtonActionPerformed
        int index=classJList.getSelectedIndex();
        if(index==0) {
            return;
        }
        Object o=chosenClassesListModel.getElementAt(index);
        chosenClassesListModel.removeElementAt(index);
        chosenClassesListModel.insertElementAt(o, index-1);
        classJList.setSelectedIndex(index-1);
    }//GEN-LAST:event_moveUpButtonActionPerformed

    private void removeClassButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_removeClassButtonActionPerformed
        int index=classJList.getSelectedIndex();
        chosenClassesListModel.removeElementAt(index);
        int size=chosenClassesListModel.getSize();

        if(size==0) { //Nobody's left, disable firing.

            removeClassButton.setEnabled(false);

        } else { //Select an index.

            if(index==chosenClassesListModel.getSize()) {
                //removed item in last position
                index--;
            }

            classJList.setSelectedIndex(index);
            classJList.ensureIndexIsVisible(index);
        }
    }//GEN-LAST:event_removeClassButtonActionPerformed

    private void classJListMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_classJListMouseClicked
//        System.out.println(classJList.getSelectedValue());
        moveDownButton.setEnabled(true);
        moveUpButton.setEnabled(true);
    }//GEN-LAST:event_classJListMouseClicked

    private void classJListCaretPositionChanged(java.awt.event.InputMethodEvent evt) {//GEN-FIRST:event_classJListCaretPositionChanged
        Object[] objs=classJList.getSelectedValues();
//        for(Object o:objs){
//            System.out.println(o.toString());
//        }

    }//GEN-LAST:event_classJListCaretPositionChanged
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton addClassButton;
    private javax.swing.JList availClassJList;
    private javax.swing.JTextField availFilterTextField;
    private javax.swing.JList classJList;
    private javax.swing.JButton defaultsButton;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JScrollPane jScrollPane2;
    private javax.swing.JButton moveDownButton;
    private javax.swing.JButton moveUpButton;
    private javax.swing.JButton removeAllButton;
    private javax.swing.JButton removeClassButton;
    private javax.swing.JButton revertButton;
    // End of variables declaration//GEN-END:variables
    // from http://forum.java.sun.com/thread.jspa?forumID=57&threadID=626866
    private static final KeyStroke ENTER=KeyStroke.getKeyStroke(KeyEvent.VK_ENTER, 0);

    public static void addAction(JList source, Action action) {
        //  Handle enter key

        InputMap im=source.getInputMap();
        im.put(ENTER, ENTER);
        source.getActionMap().put(ENTER, action);

        //  Handle mouse double click

        source.addMouseListener(new ActionMouseListener());
    }
    //  Implement Mouse Listener
    static class ActionMouseListener extends MouseAdapter {
        public void mouseClicked(MouseEvent e) {
            if(e.getClickCount()==2) {
                JList list=(JList) e.getSource();
                Action action=list.getActionMap().get(ENTER);

                if(action!=null) {
                    ActionEvent event=new ActionEvent(
                            list,
                            ActionEvent.ACTION_PERFORMED,
                            "");
                    action.actionPerformed(event);
                }
            }
        }
    }
}
