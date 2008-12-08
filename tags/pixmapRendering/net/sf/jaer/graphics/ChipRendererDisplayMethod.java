/*
 * ChipRendererDisplayMethod.java
 *
 * Created on May 4, 2006, 9:07 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright May 4, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */
package net.sf.jaer.graphics;

import com.sun.opengl.util.BufferUtil;
import java.awt.*;
import java.nio.BufferOverflowException;
import java.nio.ByteBuffer;
import java.nio.FloatBuffer;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.graphics.ChipCanvas.Zoom;

/**
 * Renders using OpenGL the RGB histogram values from Chip2DRenderer. 

 * @author tobi
 * @see net.sf.jaer.graphics.Chip2DRenderer
 * @see net.sf.jaer.graphics.AEChipRenderer
 */
public class ChipRendererDisplayMethod extends DisplayMethod implements DisplayMethod2D {

    /**
     * Creates a new instance of ChipRendererDisplayMethod
     */
    public ChipRendererDisplayMethod(ChipCanvas chipCanvas) {
        super(chipCanvas);
    }

    /** called by ChipCanvas.display(GLAutoDrawable) to draw the RGB fr histogram values. The GL context is assumed to already be
    transformed so that chip pixel x,y values can be used for coordinate values, with 0,0 at LL corner.
     */
    public void display(GLAutoDrawable drawable) {
        displayPixmap(drawable);
//        System.out.println("chiprenderdisplaymethod");
//        Chip2DRenderer renderer=chipCanvas.getRenderer();
//        float[][][] fr = renderer.getFr();
//        GL gl=setupGL(drawable);
//        float gray=clearDisplay(renderer, gl);
//        if (fr == null){
//            return;
//        }
//
//        chipCanvas.checkGLError(gl,glu,"before rendering histogram rectangles");
//
//        try{
//            // now iterate over the frame (fr)
//            Point p0=chipCanvas.getZoom().getStartPoint();
//            Point p1=chipCanvas.getZoom().getEndPoint();
//            int x0=p0.x, x1=p1.x, y0=p0.y, y1=p1.y;
//            for (int x = x0; x < x1; x++){
//                for (int y = y0; y < y1; y++){
//                    float[] f = fr[y][x];
//                    if(f[0]==gray && f[1]==gray && f[2]==gray) continue;
//                    // dont flip y direction because retina coordinates are from botton to top (in user space, after lens) are the same as default OpenGL coordinates
//                    gl.glColor3f(f[0],f[1],f[2]);
//                    gl.glRectf(x-.5f,y-.5f, x+.5f, y+.5f);
//                }
//            }
//        }catch(ArrayIndexOutOfBoundsException e){
//            log.warning("while drawing frame buffer");
//            e.printStackTrace();
//            chipCanvas.unzoom(); // in case it was some other chip had set the zoom
//        }
//
//        chipCanvas.checkGLError(gl,glu,"after rendering histogram rectangles");
//
//        // outline frame
//        gl.glColor4f(0,0,1f,0f);
//        gl.glLineWidth(1f);
//        {
//            gl.glBegin(GL.GL_LINE_LOOP);
//            final float o = .5f;
//            final float w = chip.getSizeX()-1;
//            final float h = chip.getSizeY()-1;
//            gl.glVertex2f(-o,-o);
//            gl.glVertex2f(w+o,-o);
//            gl.glVertex2f(w+o,h+o);
//            gl.glVertex2f(-o,h+o);
//            gl.glEnd();
//        }
//        chipCanvas.checkGLError(gl,glu,"after rendering frame of chip");
//
//// following are apparently not needed, this happens anyhow before buffer swap
////        gl.glFlush();
////        gl.glFinish();

    }

    private float clearDisplay(Chip2DRenderer renderer, GL gl) {
        float gray = renderer.getGrayValue();
        gl.glClearColor(gray, gray, gray, 0f);
        gl.glClear(GL.GL_COLOR_BUFFER_BIT);

        return gray;
    }

    private boolean isValidRasterPosition(GL gl) {
        boolean validRaster;
        ByteBuffer buf = ByteBuffer.allocate(1);
        gl.glGetBooleanv(GL.GL_CURRENT_RASTER_POSITION_VALID, buf);
        buf.rewind();
        byte b = buf.get();
        validRaster = b != 0;
        return validRaster;
    }

    private void displayPixmap(GLAutoDrawable drawable) {
        Chip2DRenderer renderer = chipCanvas.getRenderer();
        GL gl = setupGL(drawable);
        clearDisplay(renderer, gl);
        final int ncol = chip.getSizeX();
        final int nrow = chip.getSizeY();
        final int n = 3 * nrow * ncol;
        chipCanvas.checkGLError(gl, glu, "before pixmap");


        Zoom zoom = chip.getCanvas().getZoom();
        if (!zoom.isZoomEnabled()) {
            final int wi = drawable.getWidth(),  hi = drawable.getHeight();
            float scale = 1;
            if (chip.getCanvas().isFillsVertically()) {// tall chip, use chip height
                scale = ((float) hi - 2 * chip.getCanvas().getBorderSpacePixels()) / (chip.getSizeY() - 1);
            } else if (chip.getCanvas().isFillsHorizontally()) {
                scale = ((float) wi - 2 * chip.getCanvas().getBorderSpacePixels()) / (chip.getSizeX() - 1);
            }
            gl.glPixelZoom(scale, scale);
            gl.glRasterPos2f(-.5f, -.5f); // to LL corner of chip, but must be inside viewport or else it is ignored, breaks on zoom     if (zoom.isZoomEnabled() == false) {

//        gl.glMinmax(GL.GL_MINMAX,GL.GL_RGB,false);
//        gl.glEnable(GL.GL_MINMAX);
//            chipCanvas.checkGLError(gl, glu, "after minmax");
            {
                try {
                    synchronized (renderer) {
                        FloatBuffer pixmap = renderer.getPixmap();
                        if (pixmap != null) {
                            pixmap.position(0);
                            gl.glDrawPixels(ncol, nrow, GL.GL_RGB, GL.GL_FLOAT, pixmap);
                        }
                    }
                } catch (IndexOutOfBoundsException e) {
                    log.warning(e.toString());
                }
            }
        } else { // zoomed in, easiest to drawRect the pixels
            float scale = zoom.zoomFactor * chip.getCanvas().getScale();
            float[] f=renderer.getPixmapArray();
            int sx=chip.getSizeX(), sy=chip.getSizeY();
            float gray=renderer.getGrayValue();
            int ind=0;
            for(int y=0;y<sx;y++){
                for(int x=0;x<sy;x++){
                    if(f[ind]!=gray || f[ind+1]!=gray || f[ind+2]!=gray) {
                        gl.glColor3fv(f,ind);
                        gl.glRectf(x-.5f, y-.5f, x+.5f, y+.5f);
                    }
                    ind+=3;
                }
            }
        }
//        FloatBuffer minMax=FloatBuffer.allocate(6);
//        gl.glGetMinmax(GL.GL_MINMAX, true, GL.GL_RGB, GL.GL_FLOAT, minMax);
//        gl.glDisable(GL.GL_MINMAX);
        chipCanvas.checkGLError(gl, glu, "after rendering histogram rectangles");
        // outline frame
        gl.glColor4f(0, 0, 1f, 0f);
        gl.glLineWidth(1f);
        {
            gl.glBegin(GL.GL_LINE_LOOP);
            final float o = .5f;
            final float w = chip.getSizeX() - 1;
            final float h = chip.getSizeY() - 1;
            gl.glVertex2f(-o, -o);
            gl.glVertex2f(w + o, -o);
            gl.glVertex2f(w + o, h + o);
            gl.glVertex2f(-o, h + o);
            gl.glEnd();
        }
        chipCanvas.checkGLError(gl, glu, "after rendering frame of chip");
    }
}
