/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * cDVSTest30DisplayControlPanel.java
 *
 * Created on Dec 5, 2010, 11:57:36 AM
 */

package eu.seebetter.ini.chips.seebetter1011;

import eu.seebetter.ini.chips.seebetter1011.SeeBetter1011.SeeBetter1011DisplayMethod;
import eu.seebetter.ini.chips.seebetter1011.SeeBetter1011.SeeBetter1011Renderer;
import java.awt.geom.Point2D;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import net.sf.jaer.graphics.AEChipRenderer;
import org.jdesktop.beansbinding.Validator;

/**
 * Controls display of pixel data on SeeBetter1011.
 *
 * @author Tobi
 */
public class SeeBetter1011DisplayControlPanel extends javax.swing.JPanel implements PropertyChangeListener{

    private SeeBetter1011DisplayMethod displayMethod=null;
    private SeeBetter1011Renderer renderer=null;
    private SeeBetter1011 chip;

    /** Creates new form cDVSTest30DisplayControlPanel */
    public SeeBetter1011DisplayControlPanel(SeeBetter1011 chip) {
        this.chip=chip;
        this.displayMethod=(SeeBetter1011DisplayMethod)chip.getCanvas().getDisplayMethod();
        this.renderer=(SeeBetter1011Renderer)chip.getRenderer();
        initComponents();
        renderer.getSupport().addPropertyChangeListener(AEChipRenderer.PROPERTY_COLOR_SCALE, this);
        renderer.getSupport().addPropertyChangeListener(SeeBetter1011.SeeBetter1011Renderer.AGC_VALUES, this);
        renderer.getSupport().addPropertyChangeListener(SeeBetter1011.SeeBetter1011Renderer.LOG_INTENSITY_GAIN, this);
        renderer.getSupport().addPropertyChangeListener(SeeBetter1011.SeeBetter1011Renderer.LOG_INTENSITY_OFFSET, this);
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {
        bindingGroup = new org.jdesktop.beansbinding.BindingGroup();

        displayControlPanel = new javax.swing.JPanel();
        jPanel1 = new javax.swing.JPanel();
        logIntensityCB = new javax.swing.JCheckBox();
        invertADCvaluesCB = new javax.swing.JCheckBox();
        logIntenCalibPanel = new javax.swing.JPanel();
        offchipCalibCB = new javax.swing.JCheckBox();
        calibButton = new javax.swing.JButton();
        twoPointCalibCB = new javax.swing.JCheckBox();
        calibData2Button = new javax.swing.JButton();
        agcPanel = new javax.swing.JPanel();
        agcCB = new javax.swing.JCheckBox();
        jLabel1 = new javax.swing.JLabel();
        agcSpinner = new javax.swing.JSpinner();
        applyButton = new javax.swing.JButton();
        logIntenStatPanel = new javax.swing.JPanel();
        jLabel2 = new javax.swing.JLabel();
        gainAGCTF = new javax.swing.JTextField();
        jLabel5 = new javax.swing.JLabel();
        maxTF = new javax.swing.JTextField();
        jLabel6 = new javax.swing.JLabel();
        minTF = new javax.swing.JTextField();
        jPanel4 = new javax.swing.JPanel();
        gainLabel = new javax.swing.JLabel();
        gainSlider = new javax.swing.JSlider();
        gainTF = new javax.swing.JTextField();
        offsetLabel = new javax.swing.JLabel();
        offsetSlider = new javax.swing.JSlider();
        offTF = new javax.swing.JTextField();
        jPanel2 = new javax.swing.JPanel();
        logIntensityChangeCB = new javax.swing.JCheckBox();
        colorScaleSpinner = new javax.swing.JSpinner();
        jLabel3 = new javax.swing.JLabel();
        jPanel3 = new javax.swing.JPanel();
        jCheckBox1 = new javax.swing.JCheckBox();
        jLabel4 = new javax.swing.JLabel();
        jSpinner1 = new javax.swing.JSpinner();

        displayControlPanel.setBorder(javax.swing.BorderFactory.createTitledBorder("SeeBetter10/11 Display"));
        displayControlPanel.setPreferredSize(new java.awt.Dimension(565, 300));

        jPanel1.setBorder(javax.swing.BorderFactory.createTitledBorder("Log intensity"));

        logIntensityCB.setText("Show log intensity data");
        logIntensityCB.setToolTipText("Shows the scanned out static log intensity values.");

        org.jdesktop.beansbinding.Binding binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.displayLogIntensity}"), logIntensityCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        invertADCvaluesCB.setText("Invert ADC values");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.frameData.invertADCvalues}"), invertADCvaluesCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        logIntenCalibPanel.setBorder(javax.swing.BorderFactory.createTitledBorder("Calibration"));

        offchipCalibCB.setText("Off-chip");
        offchipCalibCB.setToolTipText("Use off-chip calibration");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.frameData.useOffChipCalibration}"), offchipCalibCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        calibButton.setText("Store dark");
        calibButton.setToolTipText("Stores teh calibration frame; use while sensor looks at a unifform dark scene");
        calibButton.setMargin(new java.awt.Insets(0, 2, 2, 2));
        calibButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                calibButtonActionPerformed(evt);
            }
        });

        twoPointCalibCB.setText("Two-point");
        twoPointCalibCB.setToolTipText("Use two-point (dark+bright) calibration");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.frameData.twoPointCalibration}"), twoPointCalibCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        twoPointCalibCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                twoPointCalibCBActionPerformed(evt);
            }
        });

        calibData2Button.setText("Store bright");
        calibData2Button.setToolTipText("Stores the white calibration frame; use while sensor looks at uniform bright scene");
        calibData2Button.setMargin(new java.awt.Insets(2, 2, 2, 2));
        calibData2Button.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                calibData2ButtonActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout logIntenCalibPanelLayout = new javax.swing.GroupLayout(logIntenCalibPanel);
        logIntenCalibPanel.setLayout(logIntenCalibPanelLayout);
        logIntenCalibPanelLayout.setHorizontalGroup(
            logIntenCalibPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(logIntenCalibPanelLayout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addGroup(logIntenCalibPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(offchipCalibCB)
                    .addComponent(twoPointCalibCB))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(logIntenCalibPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(calibButton)
                    .addComponent(calibData2Button)))
        );
        logIntenCalibPanelLayout.setVerticalGroup(
            logIntenCalibPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(logIntenCalibPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                .addGroup(logIntenCalibPanelLayout.createSequentialGroup()
                    .addComponent(calibButton)
                    .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                    .addComponent(calibData2Button))
                .addGroup(logIntenCalibPanelLayout.createSequentialGroup()
                    .addComponent(offchipCalibCB)
                    .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                    .addComponent(twoPointCalibCB)))
        );

        agcPanel.setBorder(javax.swing.BorderFactory.createTitledBorder("AGC"));

        agcCB.setText("Use AGC");
        agcCB.setToolTipText("Activates Automagitc Gain Control for log intensity display");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${renderer.agcEnabled}"), agcCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        jLabel1.setText("AGC time constant (ms)");

        agcSpinner.setModel(new javax.swing.SpinnerNumberModel(Float.valueOf(1000.0f), Float.valueOf(10.0f), null, Float.valueOf(100.0f)));
        agcSpinner.setToolTipText("Set time constant in ms for AGC");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${renderer.AGCTauMs}"), agcSpinner, org.jdesktop.beansbinding.BeanProperty.create("value"));
        bindingGroup.addBinding(binding);

        applyButton.setText("Apply");
        applyButton.setToolTipText("Apply AGC offset and gain values to fixed values");
        applyButton.setIconTextGap(1);
        applyButton.setMargin(new java.awt.Insets(1, 3, 1, 3));
        applyButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                applyButtonActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout agcPanelLayout = new javax.swing.GroupLayout(agcPanel);
        agcPanel.setLayout(agcPanelLayout);
        agcPanelLayout.setHorizontalGroup(
            agcPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(agcPanelLayout.createSequentialGroup()
                .addComponent(agcCB)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jLabel1)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(agcSpinner, javax.swing.GroupLayout.PREFERRED_SIZE, 63, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(applyButton))
        );
        agcPanelLayout.setVerticalGroup(
            agcPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(agcPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.CENTER)
                .addComponent(jLabel1)
                .addComponent(agcCB)
                .addComponent(agcSpinner, javax.swing.GroupLayout.PREFERRED_SIZE, 22, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addComponent(applyButton))
        );

        logIntenStatPanel.setBorder(javax.swing.BorderFactory.createTitledBorder("statistics"));

        jLabel2.setText("min (offset)");

        gainAGCTF.setColumns(4);
        gainAGCTF.setEditable(false);
        gainAGCTF.setHorizontalAlignment(javax.swing.JTextField.TRAILING);
        gainAGCTF.setText("4095");
        gainAGCTF.setToolTipText("gain as computed by AGC");

        jLabel5.setText("max");

        maxTF.setColumns(4);
        maxTF.setEditable(false);
        maxTF.setHorizontalAlignment(javax.swing.JTextField.TRAILING);
        maxTF.setText("4095");
        maxTF.setToolTipText("lowpass max log intensity value");

        jLabel6.setText("gain");

        minTF.setColumns(4);
        minTF.setEditable(false);
        minTF.setHorizontalAlignment(javax.swing.JTextField.TRAILING);
        minTF.setText("0");
        minTF.setToolTipText("low pass min log intensity value");

        javax.swing.GroupLayout logIntenStatPanelLayout = new javax.swing.GroupLayout(logIntenStatPanel);
        logIntenStatPanel.setLayout(logIntenStatPanelLayout);
        logIntenStatPanelLayout.setHorizontalGroup(
            logIntenStatPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, logIntenStatPanelLayout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addComponent(jLabel2)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(logIntenStatPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(logIntenStatPanelLayout.createSequentialGroup()
                        .addGap(10, 10, 10)
                        .addComponent(jLabel6)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(minTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addGroup(logIntenStatPanelLayout.createSequentialGroup()
                        .addComponent(gainAGCTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jLabel5)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(maxTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)))
                .addContainerGap())
        );
        logIntenStatPanelLayout.setVerticalGroup(
            logIntenStatPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(logIntenStatPanelLayout.createSequentialGroup()
                .addGroup(logIntenStatPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.CENTER)
                    .addComponent(jLabel2)
                    .addComponent(gainAGCTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jLabel5)
                    .addComponent(maxTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addGroup(logIntenStatPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.CENTER)
                    .addComponent(jLabel6)
                    .addComponent(minTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap())
        );

        gainLabel.setText("gain");

        gainSlider.setMaximum(SeeBetter1011.MAX_ADC/100);
        gainSlider.setToolTipText("Sets the gain applied to ADC count. Gain=1 scales full count to white when offset=0. Gain=MAX_ADC scales a single count to full white when offset=0.");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${logIntensityGain}"), gainSlider, org.jdesktop.beansbinding.BeanProperty.create("value"));
        bindingGroup.addBinding(binding);

        gainTF.setColumns(6);
        gainTF.setHorizontalAlignment(javax.swing.JTextField.TRAILING);

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, gainSlider, org.jdesktop.beansbinding.ELProperty.create("${value}"), gainTF, org.jdesktop.beansbinding.BeanProperty.create("text"));
        bindingGroup.addBinding(binding);

        offsetLabel.setText("offset");

        offsetSlider.setMaximum(SeeBetter1011.MAX_ADC);
        offsetSlider.setToolTipText("Sets the offset subtracted from ADC count. Gain=1 scales full count to white when offset=0. Offset shifts black point to offset count value.");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${logIntensityOffset}"), offsetSlider, org.jdesktop.beansbinding.BeanProperty.create("value"));
        bindingGroup.addBinding(binding);

        offTF.setColumns(6);
        offTF.setHorizontalAlignment(javax.swing.JTextField.TRAILING);

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, offsetSlider, org.jdesktop.beansbinding.ELProperty.create("${value}"), offTF, org.jdesktop.beansbinding.BeanProperty.create("text"));
        bindingGroup.addBinding(binding);

        javax.swing.GroupLayout jPanel4Layout = new javax.swing.GroupLayout(jPanel4);
        jPanel4.setLayout(jPanel4Layout);
        jPanel4Layout.setHorizontalGroup(
            jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel4Layout.createSequentialGroup()
                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(jPanel4Layout.createSequentialGroup()
                        .addComponent(offsetLabel)
                        .addComponent(offsetSlider, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addGroup(jPanel4Layout.createSequentialGroup()
                        .addComponent(gainLabel)
                        .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(gainSlider, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addGroup(jPanel4Layout.createSequentialGroup()
                                .addGap(204, 204, 204)
                                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                                    .addComponent(offTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                                    .addComponent(gainTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))))))
                .addContainerGap(15, Short.MAX_VALUE))
        );

        jPanel4Layout.linkSize(javax.swing.SwingConstants.HORIZONTAL, new java.awt.Component[] {gainLabel, offsetLabel});

        jPanel4Layout.setVerticalGroup(
            jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel4Layout.createSequentialGroup()
                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(gainLabel)
                    .addComponent(gainSlider, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(gainTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(offsetLabel, javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(offsetSlider, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(offTF, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)))
        );

        jPanel4Layout.linkSize(javax.swing.SwingConstants.VERTICAL, new java.awt.Component[] {gainLabel, gainSlider, gainTF});

        jPanel4Layout.linkSize(javax.swing.SwingConstants.VERTICAL, new java.awt.Component[] {offTF, offsetLabel, offsetSlider});

        javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(logIntenStatPanel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(logIntenCalibPanel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addComponent(logIntensityCB)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(invertADCvaluesCB))
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING, false)
                    .addComponent(agcPanel, javax.swing.GroupLayout.Alignment.LEADING, 0, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jPanel4, javax.swing.GroupLayout.Alignment.LEADING, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)))
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(logIntensityCB, javax.swing.GroupLayout.PREFERRED_SIZE, 23, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(invertADCvaluesCB))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(jPanel4, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(agcPanel, javax.swing.GroupLayout.PREFERRED_SIZE, 49, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(logIntenStatPanel, 0, 77, Short.MAX_VALUE)
                    .addComponent(logIntenCalibPanel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap())
        );

        jPanel2.setBorder(javax.swing.BorderFactory.createTitledBorder("Events"));

        logIntensityChangeCB.setText("Show log intensity change events");
        logIntensityChangeCB.setToolTipText("Show log intensity change (temporal contrast) Brighter and Darker events.");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.displayLogIntensityChangeEvents}"), logIntensityChangeCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        colorScaleSpinner.setToolTipText("Sets the full scale (white or black) event count.");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.renderer.colorScale}"), colorScaleSpinner, org.jdesktop.beansbinding.BeanProperty.create("value"), "colorScale");
        bindingGroup.addBinding(binding);

        jLabel3.setText("Full scale events");

        javax.swing.GroupLayout jPanel2Layout = new javax.swing.GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel2Layout.createSequentialGroup()
                .addContainerGap(10, Short.MAX_VALUE)
                .addComponent(logIntensityChangeCB)
                .addContainerGap())
            .addGroup(jPanel2Layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jLabel3)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(colorScaleSpinner, javax.swing.GroupLayout.PREFERRED_SIZE, 59, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addContainerGap(51, Short.MAX_VALUE))
        );
        jPanel2Layout.setVerticalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel2Layout.createSequentialGroup()
                .addComponent(logIntensityChangeCB, javax.swing.GroupLayout.PREFERRED_SIZE, 23, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel3)
                    .addComponent(colorScaleSpinner, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)))
        );

        jPanel3.setBorder(javax.swing.BorderFactory.createTitledBorder("Global intensity"));

        jCheckBox1.setText("Show global intensity");
        jCheckBox1.setToolTipText("Shows the global sum photocurrent value.");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${displayMethod.intensityDisplayEnabled}"), jCheckBox1, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        jLabel4.setText("Global intensity scale");

        jSpinner1.setModel(new javax.swing.SpinnerNumberModel(Float.valueOf(1.0f), Float.valueOf(0.1f), Float.valueOf(10.0f), Float.valueOf(0.1f)));
        jSpinner1.setToolTipText("Scales ISI so that scale=1 shows 1ms ISI as full scale.");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${displayMethod.intensityScale}"), jSpinner1, org.jdesktop.beansbinding.BeanProperty.create("value"));
        bindingGroup.addBinding(binding);

        javax.swing.GroupLayout jPanel3Layout = new javax.swing.GroupLayout(jPanel3);
        jPanel3.setLayout(jPanel3Layout);
        jPanel3Layout.setHorizontalGroup(
            jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel3Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING, false)
                    .addComponent(jCheckBox1)
                    .addGroup(jPanel3Layout.createSequentialGroup()
                        .addComponent(jLabel4)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(jSpinner1, javax.swing.GroupLayout.PREFERRED_SIZE, 62, javax.swing.GroupLayout.PREFERRED_SIZE)))
                .addGap(45, 45, 45))
        );
        jPanel3Layout.setVerticalGroup(
            jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel3Layout.createSequentialGroup()
                .addComponent(jCheckBox1)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel4)
                    .addComponent(jSpinner1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap(18, Short.MAX_VALUE))
        );

        javax.swing.GroupLayout displayControlPanelLayout = new javax.swing.GroupLayout(displayControlPanel);
        displayControlPanel.setLayout(displayControlPanelLayout);
        displayControlPanelLayout.setHorizontalGroup(
            displayControlPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, displayControlPanelLayout.createSequentialGroup()
                .addGroup(displayControlPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jPanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jPanel3, javax.swing.GroupLayout.PREFERRED_SIZE, 239, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
        displayControlPanelLayout.setVerticalGroup(
            displayControlPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(displayControlPanelLayout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jPanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(jPanel3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
            .addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, 235, javax.swing.GroupLayout.PREFERRED_SIZE)
        );

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(displayControlPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 657, Short.MAX_VALUE)
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(displayControlPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 262, Short.MAX_VALUE)
        );

        bindingGroup.bind();
    }// </editor-fold>//GEN-END:initComponents

    private void applyButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_applyButtonActionPerformed
        renderer.applyAGCValues();
    }//GEN-LAST:event_applyButtonActionPerformed

    private void calibButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_calibButtonActionPerformed
        if(chip==null || chip.getFrameData()==null) return;
        chip.getFrameData().setCalibData1();
    }//GEN-LAST:event_calibButtonActionPerformed

    private void twoPointCalibCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_twoPointCalibCBActionPerformed
        // TODO add your handling code here:
        if(chip==null || chip.getFrameData()==null) return;
        chip.getFrameData().calculateCalibration();
    }//GEN-LAST:event_twoPointCalibCBActionPerformed

    private void calibData2ButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_calibData2ButtonActionPerformed
         if(chip==null || chip.getFrameData()==null) return;
        chip.getFrameData().setCalibData2();
    }//GEN-LAST:event_calibData2ButtonActionPerformed


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JCheckBox agcCB;
    private javax.swing.JPanel agcPanel;
    private javax.swing.JSpinner agcSpinner;
    private javax.swing.JButton applyButton;
    private javax.swing.JButton calibButton;
    private javax.swing.JButton calibData2Button;
    private javax.swing.JSpinner colorScaleSpinner;
    private javax.swing.JPanel displayControlPanel;
    private javax.swing.JTextField gainAGCTF;
    private javax.swing.JLabel gainLabel;
    private javax.swing.JSlider gainSlider;
    private javax.swing.JTextField gainTF;
    private javax.swing.JCheckBox invertADCvaluesCB;
    private javax.swing.JCheckBox jCheckBox1;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JLabel jLabel5;
    private javax.swing.JLabel jLabel6;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JPanel jPanel3;
    private javax.swing.JPanel jPanel4;
    private javax.swing.JSpinner jSpinner1;
    private javax.swing.JPanel logIntenCalibPanel;
    private javax.swing.JPanel logIntenStatPanel;
    private javax.swing.JCheckBox logIntensityCB;
    private javax.swing.JCheckBox logIntensityChangeCB;
    private javax.swing.JTextField maxTF;
    private javax.swing.JTextField minTF;
    private javax.swing.JTextField offTF;
    private javax.swing.JCheckBox offchipCalibCB;
    private javax.swing.JLabel offsetLabel;
    private javax.swing.JSlider offsetSlider;
    private javax.swing.JCheckBox twoPointCalibCB;
    private org.jdesktop.beansbinding.BindingGroup bindingGroup;
    // End of variables declaration//GEN-END:variables

    /**
     * @return the displayMethod
     */
    public SeeBetter1011DisplayMethod getDisplayMethod() {
        return displayMethod;
    }

    /**
     * @param displayMethod the displayMethod to set
     */
    public void setDisplayMethod(SeeBetter1011DisplayMethod displayMethod) {
        this.displayMethod = displayMethod;
    }

    /**
     * @return the chip
     */
    public SeeBetter1011 getChip() {
        return chip;
    }

    /**
     * @param chip the chip to set
     */
    public void setChip(SeeBetter1011 chip) {
        this.chip = chip;
    }

    public void setLogIntensityOffset(int logIntensityOffset) {
        renderer.setLogIntensityOffset(logIntensityOffset);
    }

    public void setLogIntensityGain(int logIntensityGain) {
        renderer.setLogIntensityGain(logIntensityGain);
    }

    public int getLogIntensityOffset() {
        return (int)(renderer.getLogIntensityOffset());
    }

    public int getLogIntensityGain() {
        return (int)(renderer.getLogIntensityGain());
    }


    public int getColorScale(){
        if(chip==null || chip.getRenderer()==null) return 1;
        return chip.getRenderer().getColorScale();
    }

    public void setColorScale(int s){
        if(s<1) s=1;
         if (chip == null || chip.getRenderer() == null) {
            return;
        }
        chip.getRenderer().setColorScale(s);
    }

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        if(evt.getPropertyName()==AEChipRenderer.PROPERTY_COLOR_SCALE){
            colorScaleSpinner.setValue((Integer)evt.getNewValue());
        }else if(evt.getPropertyName()==SeeBetter1011.SeeBetter1011Renderer.AGC_VALUES){
            Point2D.Float f=(Point2D.Float)evt.getNewValue();
            minTF.setText(String.format("%.0f",f.x));
            maxTF.setText(String.format("%.0f",f.y));
            gainAGCTF.setText(String.format("%.0f",SeeBetter1011.MAX_ADC/(f.y-f.x)));
        }else if(evt.getPropertyName()==SeeBetter1011.SeeBetter1011Renderer.LOG_INTENSITY_GAIN){
            gainSlider.setValue(renderer.getLogIntensityGain());
        }else if(evt.getPropertyName()==SeeBetter1011.SeeBetter1011Renderer.LOG_INTENSITY_OFFSET){
            offsetSlider.setValue(renderer.getLogIntensityOffset());
        }
    }

    /**
     * @return the renderer
     */
    public SeeBetter1011Renderer getRenderer() {
        return renderer;
    }

}
