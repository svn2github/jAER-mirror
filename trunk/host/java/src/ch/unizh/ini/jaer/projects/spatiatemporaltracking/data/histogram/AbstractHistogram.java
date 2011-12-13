/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.spatiatemporaltracking.data.histogram;

import com.sun.opengl.util.j2d.TextRenderer;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.GL;

/**
 *
 * @author matthias
 * 
 * The abstract class Histogram provides some fundamental methods and structures
 * for the histograms.
 */
public abstract class AbstractHistogram implements Histogram {
    protected int window;
    
    protected int start;
    protected int step;
    protected int nBins;
    
    protected float[] gaussian;
    
    /**
     * Creates a new AbstractHistogram based on the default values.
     */
    public AbstractHistogram() {
        this(1000, 100, 10000, 0);
    }
    
    /**
     * Creates a new AbstractHistogram.
     * 
     * @param start The start of the histogram.
     * @param step The step size of the histogram.
     * @param nBins The number of bins used by the histogram.
     * @param window The window specifies how the values are distributed over
     * the neighbouring bins.
     */
    public AbstractHistogram(int start, int step, int nBins, int window) {
        this.start = start;
        this.step = step;
        this.nBins = nBins;
        this.window = window;
    }
    
    @Override
    public void init() {
        this.gaussian = new float[2 * window + 1];
        float s = 0;
        for (int i = -window; i <= window; i++) {
            double p = -Math.pow(i, 2) / 2;
            double e = Math.exp(p);
            this.gaussian[i + window] = (float)(1 / Math.sqrt(2*Math.PI) * e);
            s += this.gaussian[i + window];
        }
        for (int i = 0; i < this.gaussian.length; i++) {
            this.gaussian[i] /= s;
        }
    }

    @Override
    public int getStart() {
        return this.start;
    }

    @Override
    public int getStep() {
        return this.step;
    }
    
    @Override
    public void draw(GLAutoDrawable drawable, TextRenderer renderer, float x, float y, int height, int resolution) {
        GL gl = drawable.getGL();
        
        int from = 0;
        float total = 0;
        while (total < 0.1 && from < this.getSize()) {
            total += this.getNormalized(from);
            from++;
        }
        int to = from;
        from = Math.max(0, from - 2);
        
        while (total < 0.9 && to < this.getSize()) {
            total += this.getNormalized(to);
            to++;
        }
        to = Math.min(to + 2, this.nBins);
        
        int pack = (to - from) / resolution + 1;
        
        float [] sum = new float[resolution + 1];
        int counter = 0;
        
        for (int i = from; i < to; i++) {
            sum[counter] += this.getNormalized(i);
            
            if (i % pack == 0 && i != 0) {
                counter++;
            }
        }
        
        float max = 0;
        for (int i = 0; i < sum.length; i++) {
            if (max < sum[i]) max = sum[i];
        }
        
        for (int i = 0; i < sum.length; i++) {
            float h = sum[i] / max * (height - 4);
            gl.glBegin(GL.GL_LINE_LOOP);
            {
                gl.glVertex2f(x + i, y - height + 3);
                gl.glVertex2f(x + i, y - height + h + 3);

                gl.glVertex2f(x + i + 1, y - height + h + 3);
                gl.glVertex2f(x + i + 1, y - height + 3);
            }
            gl.glEnd();
        }
        
        renderer.begin3DRendering();
        renderer.draw3D("histogram [au]: " + (this.start + from * this.step) + ", " + (this.start + to * this.step) + ".", x, y, 0, 0.5f);
        renderer.end3DRendering();
    }
}
