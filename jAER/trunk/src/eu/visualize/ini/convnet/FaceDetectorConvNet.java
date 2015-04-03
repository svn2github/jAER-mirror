/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.visualize.ini.convnet;

import java.awt.Color;
import java.awt.Point;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.glu.GLU;
import com.jogamp.opengl.glu.GLUquadric;
import javax.swing.SwingUtilities;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.graphics.MultilineAnnotationTextRenderer;

/**
 * Extends DavisDeepLearnCnnProcessor to add annotation graphics to show
 * steering decision.
 *
 * @author Tobi
 */
@Description("Displays face detector ConvNet results; subclass of DavisDeepLearnCnnProcessor")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
public class FaceDetectorConvNet extends DavisDeepLearnCnnProcessor implements PropertyChangeListener {

    private boolean hideOutput = getBoolean("hideOutput", false);
    private boolean showAnalogDecisionOutput = getBoolean("showAnalogDecisionOutput", false);
    private TargetLabeler targetLabeler = null;
    private int totalDecisions = 0, correct = 0, incorrect = 0;

    public FaceDetectorConvNet(AEChip chip) {
        super(chip);
        setPropertyTooltip("showAnalogDecisionOutput", "shows output units as analog shading");
        setPropertyTooltip("hideOutput", "hides output units");
        FilterChain chain = new FilterChain(chip);
        targetLabeler = new TargetLabeler(chip); // used to validate whether descisions are correct or not
        chain.add(targetLabeler);
        setEnclosedFilterChain(chain);
        apsNet.getSupport().addPropertyChangeListener(DeepLearnCnnNetwork.EVENT_MADE_DECISION, this);
        dvsNet.getSupport().addPropertyChangeListener(DeepLearnCnnNetwork.EVENT_MADE_DECISION, this);
    }

    @Override
    public synchronized EventPacket<?> filterPacket(EventPacket<?> in) {
        targetLabeler.filterPacket(in);
        EventPacket out = super.filterPacket(in);
        return out;
    }

    private Boolean correctDescisionFromTargetLabeler(TargetLabeler targetLabeler, DeepLearnCnnNetwork net) {
        if (targetLabeler.getTargetLocation() == null) {
            return null; // no face labeled for this sample
        }
        Point p = targetLabeler.getTargetLocation().location;
        if (p == null) { // no face labeled
            if (net.outputLayer.maxActivatedUnit == 1) {
                return true; // no face detected
            }
        } else { // face labeled
            if (0 == net.outputLayer.maxActivatedUnit) {
                return true;  // face detected
            }
        }
        return false; // wrong decision
    }

    @Override
    public void resetFilter() {
        super.resetFilter();
        totalDecisions = 0;
        correct = 0;
        incorrect = 0;

    }

    @Override
    public synchronized void setFilterEnabled(boolean yes) {
        super.setFilterEnabled(yes);
        if (yes && !targetLabeler.hasLocations()) {
            Runnable r = new Runnable() {

                @Override
                public void run() {
                    targetLabeler.loadLastLocations();
                }
            };
            SwingUtilities.invokeLater(r);
        }
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        super.annotate(drawable);
        if(targetLabeler!=null) targetLabeler.annotate(drawable);
        if (hideOutput) {
            return;
        }
        GL2 gl = drawable.getGL().getGL2();
        checkBlend(gl);
        int sy = chip.getSizeY();
        if (apsNet != null && apsNet.outputLayer!=null && apsNet.outputLayer.activations != null && isProcessAPSFrames()) {
            drawDecisionOutput(gl, sy, apsNet, Color.RED);
        }
        if (dvsNet != null && dvsNet.outputLayer!=null && dvsNet.outputLayer.activations != null && isProcessDVSTimeSlices()) {
            drawDecisionOutput(gl, sy, dvsNet, Color.YELLOW);
        }

        if (totalDecisions > 0) {
            float errorRate = (float) incorrect / totalDecisions;
            String s = String.format("Error rate %.2f%% (total=%d correct=%d incorrect=%d)\n", errorRate * 100, totalDecisions, correct, incorrect);
            MultilineAnnotationTextRenderer.renderMultilineString(s);
        }

    }
    GLU glu = null;
    GLUquadric quad = null;

    private void drawDecisionOutput(GL2 gl, int sy, DeepLearnCnnNetwork net, Color color) {
        // 0=left, 1=center, 2=right, 3=no target
        int decision = net.outputLayer.maxActivatedUnit;
        float r = color.getRed() / 255f, g = color.getGreen() / 255f, b = color.getBlue() / 255f;
        float[] cv = color.getColorComponents(null);
        if (glu == null) {
            glu = new GLU();
        }
        if (quad == null) {
            quad = glu.gluNewQuadric();
        }

        float rad = chip.getMinSize() / 4, rim = 3;
        final float brightness = net.outputLayer.activations[0] * 1f; // brightness scale
        gl.glColor3f(brightness, brightness, brightness);
        gl.glPushMatrix();
        gl.glTranslatef(chip.getSizeX()/2, chip.getSizeY()/2, 0);
        glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
        glu.gluDisk(quad, rad - rim, rad + rim, 32, 1);
        gl.glPopMatrix();
    }

    /**
     * @return the hideOutput
     */
    public boolean isHideOutput() {
        return hideOutput;
    }

    /**
     * @param hideOutput the hideOutput to set
     */
    public void setHideOutput(boolean hideOutput) {
        this.hideOutput = hideOutput;
        putBoolean("hideOutput", hideOutput);
    }

    /**
     * @return the showAnalogDecisionOutput
     */
    public boolean isShowAnalogDecisionOutput() {
        return showAnalogDecisionOutput;
    }

    /**
     * @param showAnalogDecisionOutput the showAnalogDecisionOutput to set
     */
    public void setShowAnalogDecisionOutput(boolean showAnalogDecisionOutput) {
        this.showAnalogDecisionOutput = showAnalogDecisionOutput;
        putBoolean("showAnalogDecisionOutput", showAnalogDecisionOutput);
    }

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        if (evt.getPropertyName() != DeepLearnCnnNetwork.EVENT_MADE_DECISION) {
            super.propertyChange(evt);
        } else {
            DeepLearnCnnNetwork net = (DeepLearnCnnNetwork) evt.getNewValue();
            Boolean correctDecision = correctDescisionFromTargetLabeler(targetLabeler, net);
            if (correctDecision != null) {
                totalDecisions++;
                if (correctDecision) {
                    correct++;
                } else {
                    incorrect++;
                }
            }
        }
    }

}
