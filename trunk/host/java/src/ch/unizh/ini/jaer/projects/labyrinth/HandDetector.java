/*
 *Tobi Delbruck, CapoCaccia 2011
 */
package ch.unizh.ini.jaer.projects.labyrinth;

import com.sun.opengl.util.j2d.TextRenderer;
import java.awt.Font;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.filter.EventRateEstimator;
import net.sf.jaer.graphics.FrameAnnotater;

/**
 * Detects hand by setting a threshold on the average event activity. Very high activity says probably a hand is picking up the ball or putting it down.
 * @author tobi
 */
public class HandDetector extends EventRateEstimator implements FrameAnnotater {

    protected float handEventRateThresholdKEPS = getFloat("handEventRateThresholdKEPS", 100);
    TextRenderer renderer;
    boolean handDetected = false;
    long lastTimeHandDetected = 0;
    int timeoutMs = getInt("timeoutMs", 2000);

    enum State {

        NoHand, HandNow, TimeoutAfterHand
    };
    State state = State.NoHand;

    public HandDetector(AEChip chip) {
        super(chip);
        setPropertyTooltip("thresholdKEPS", "threshold avg event rate in kilo event per second to count as hand detection");
    }

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        super.filterPacket(in);
        boolean detectedNow = (handDetected = getFilteredEventRate() * 1e-3f > handEventRateThresholdKEPS);
        if (detectedNow) {
            handDetected = true;
            lastTimeHandDetected = System.currentTimeMillis();
        }
        if (handDetected && !detectedNow && (System.currentTimeMillis() - lastTimeHandDetected) > timeoutMs) {
            handDetected = false;
        }
        return in;
    }

    /**
     * Get the value of handEventRateThresholdKEPS
     *
     * @return the value of handEventRateThresholdKEPS
     */
    public float getHandEventRateThresholdKEPS() {
        return handEventRateThresholdKEPS;
    }

    public boolean isHandDetected() {
        return handDetected;

    }

    /**
     * Set the value of handEventRateThresholdKEPS
     *
     * @param handEventRateThresholdKEPS new value of handEventRateThresholdKEPS
     */
    public void setHandEventRateThresholdKEPS(float thresholdKEPS) {
        this.handEventRateThresholdKEPS = thresholdKEPS;
        putFloat("handEventRateThresholdKEPS", thresholdKEPS);
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        if (renderer == null) {
            renderer = new TextRenderer(new Font("SansSerif", Font.BOLD, 24));
        }
        GL gl = drawable.getGL();
        if (handDetected && renderer != null) {
            renderer.beginRendering(chip.getSizeX(), chip.getSizeY());
            gl.glColor4f(1, 1, 0, .7f);
            renderer.draw("Hand!", 5, chip.getSizeY() / 2);
            renderer.endRendering();
        } else {
            gl.glColor4f(0, 1, 0, .5f);
            gl.glRectf(0, -3, chip.getSizeX() * getFilteredEventRate() / handEventRateThresholdKEPS * 1e-3f, -1);
        }
    }
}
