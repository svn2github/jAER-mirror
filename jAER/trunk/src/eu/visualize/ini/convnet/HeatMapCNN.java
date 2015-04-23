/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package eu.visualize.ini.convnet;

import ch.unizh.ini.jaer.projects.util.ColorHelper;
import com.jogamp.opengl.GL2;
import java.beans.PropertyChangeEvent;
import com.jogamp.opengl.GLAutoDrawable;
import java.awt.Color;
import java.awt.Point;
import java.util.Arrays;
import javax.swing.SwingUtilities;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.graphics.AEChipRenderer;
import net.sf.jaer.graphics.AEFrameChipRenderer;
import net.sf.jaer.graphics.MultilineAnnotationTextRenderer;

/* import can be generated automatically 

/**
 * Computes heat map by running CNN using ROI over the frame.
 * @author hongjie & Christian
 */
@Description("Computes heat map by running CNN using ROI over the frame")
@DevelopmentStatus(DevelopmentStatus.Status.InDevelopment)
public class HeatMapCNN extends DavisDeepLearnCnnProcessor{

    private boolean hideOutput = getBoolean("hideOutput", false);
    private boolean showAnalogDecisionOutput = getBoolean("showAnalogDecisionOutput", false);
    private TargetLabeler targetLabeler = null;
    private int totalDecisions = 0, correct = 0, incorrect = 0;
    private float alpha = 0.5f;
    private final int strideX = 16;
    private final int strideY = 16;
    private float[] heatMap;
    private final AEFrameChipRenderer renderer;

    public HeatMapCNN(AEChip chip) {
        super(chip);
        setPropertyTooltip("showAnalogDecisionOutput", "shows output units as analog shading");
        setPropertyTooltip("hideOutput", "hides output units");
        FilterChain chain = new FilterChain(chip);
        targetLabeler = new TargetLabeler(chip); // used to validate whether descisions are correct or not
        chain.add(targetLabeler);
        setEnclosedFilterChain(chain);
        int sx = chip.getSizeX()/strideX;
        int sy = chip.getSizeY()/strideY;
        heatMap = new float[sx*sy];
        Arrays.fill(heatMap, 0.0f);
        apsNet.getSupport().addPropertyChangeListener(DeepLearnCnnNetwork.EVENT_MADE_DECISION, this);
        dvsNet.getSupport().addPropertyChangeListener(DeepLearnCnnNetwork.EVENT_MADE_DECISION, this);
        renderer = (AEFrameChipRenderer) chip.getRenderer();
    }

    @Override
    public synchronized EventPacket<?> filterPacket(EventPacket<?> in) {
        targetLabeler.filterPacket(in);
        EventPacket out = super.filterPacket(in);
        return out;
    }

    private Boolean correctDescisionFromTargetLabeler(TargetLabeler targetLabeler, DeepLearnCnnNetwork net) {
        if (targetLabeler.getTargetLocation() == null) {
            return null; // no location labeled for this time
        }
        Point p = targetLabeler.getTargetLocation().location;
        if (p == null) {
            if (net.outputLayer.maxActivatedUnit == 3) {
                return true; // no target seen
            }
        } else {
            int x = p.x;
            int third = (x * 3) / chip.getSizeX();
            if (third == net.outputLayer.maxActivatedUnit) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void resetFilter() {
        super.resetFilter();
        int sx = chip.getSizeX()/strideX;
        int sy = chip.getSizeY()/strideY;
        heatMap = new float[sx*sy];
        Arrays.fill(heatMap, 0.0f);
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
        targetLabeler.annotate(drawable);
        if (hideOutput) {
            return;
        }
        GL2 gl = drawable.getGL().getGL2();
        checkBlend(gl);
        int third = chip.getSizeX() / 3;
        int sy = chip.getSizeY();
        if (apsNet != null && apsNet.outputLayer.activations != null && isProcessAPSFrames()) {
            drawDecisionOutput(third, gl, sy, apsNet, Color.RED);
        }
        
        if (dvsNet != null && dvsNet.outputLayer != null && dvsNet.outputLayer.activations != null && isProcessDVSTimeSlices()) {
            drawDecisionOutput(third, gl, sy, dvsNet, Color.YELLOW);
        }

        if (totalDecisions > 0) {
            float errorRate = (float) incorrect / totalDecisions;
            String s = String.format("Error rate %.2f%% (total=%d correct=%d incorrect=%d)\n", errorRate * 100, totalDecisions, correct, incorrect);
            MultilineAnnotationTextRenderer.renderMultilineString(s);
        }

    }

    private void drawDecisionOutput(int third, GL2 gl, int sy, DeepLearnCnnNetwork net, Color color) {
        
        renderer.setExternalRenderer(true);
        renderer.resetAnnotationFrame(0.0f);
        renderer.setAnnotateAlpha(alpha);
        float[] colors = new float[3];
        int sizeX = chip.getSizeX()/strideX;
        int sizeY = chip.getSizeY()/strideY;
        for (int x = 0; x < sizeX; x++) {
            for (int y = 0; y < sizeY; y++) {
                float heat = heatMap[getHeatmapIdx(x,y)];
                float hue = 3f-3f*heat;
                colors = ColorHelper.HSVtoRGB(hue, 1.0f, 1.0f);
                for(int xx = 0; xx<strideX; xx++){
                    for(int yy = 0; yy<strideY; yy++){
                        renderer.setAnnotateColorRGB(x*strideX + xx, y*strideY + yy, colors);
                    }
                }
            }
        }
    }
    
    public int getHeatmapIdx(int x, int y){
        int sizeX = chip.getSizeX()/strideX;
        return x+y*sizeX;
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
        if (evt.getPropertyName().equals(AEFrameChipRenderer.EVENT_NEW_FRAME_AVAILBLE)) {
            if (apsNet != null && processAPSFrames) {
                long startTime = 0;
                if (measurePerformance) {
                    startTime = System.nanoTime();
                }
                int dimx2 = apsNet.inputLayer.dimx/2;
                int dimy2 = apsNet.inputLayer.dimy/2;
                int idx = 0;
                for(int x = dimx2; x< chip.getSizeX()-dimx2; x+= strideX){
                    for(int y = dimy2; y< chip.getSizeY()-dimy2; y+= strideY){
                        float[] outputs = apsNet.processInputPatchFrame((AEFrameChipRenderer) (chip.getRenderer()), x, y);
                        apsNet.drawActivations();
                        heatMap[idx]=outputs[0];
                        idx++;
                    }
                }
                if (measurePerformance) {
                    long dt = System.nanoTime() - startTime;
                    float ms = 1e-6f * dt;
                    float fps = 1e3f / ms;
                    log.info(String.format("Frame processing time: %.1fms (%.1f FPS)", ms, fps));

                }
            }
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
