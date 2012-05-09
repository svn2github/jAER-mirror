
package uk.ac.imperial.vsbe;

import java.nio.IntBuffer;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.GLEventListener;
import javax.media.opengl.GLJPanel;
import javax.media.opengl.glu.GLU;
import com.sun.opengl.util.FPSAnimator;

/*
 * An openGL container that displays the raw frame data for cameras.
 * 
 * @author Tobi - modified mlk11
 */
public class CameraViewPanel extends GLJPanel implements GLEventListener {

    final static Logger log = Logger.getLogger("CameraViewPanel");
    final static GLU glu = new GLU();
    FrameSource stream = null;
    private Frame frame;
    private final double ZCLIP = 1;
    // is scaled width longer then height
    private boolean fillHorizontal;
    // current chip size
    private int sx;
    private int sy;
    // current scaling values between chip and display
    private float scaleX;
    private float scaleY;
    
    public FPSAnimator animator;

    /* Border class for neatness (symmetric top/bottom and left/right). */
    private class Borders {

        float x = 0, y = 0;

        Borders(float x, float y) {
            this.x = x;
            this.y = y;
        }
    }
    /* The actual borders are generated as space around the chip area. */
    private Borders borders = new Borders(1, 1);

    public CameraViewPanel() {
        super();
        addGLEventListener(this);
        
    }

    public void setStream(FrameSource stream) {
        this.stream = stream;
        if (stream != null) {
            frame.setSize(stream.getFrameX() * stream.getFrameY() * stream.getPixelSize());
            
            // set the current chip size and necessary scales
            this.reshape(0, 0, this.getWidth(), this.getHeight());
        }
    }
    
    @Override
    public void init(GLAutoDrawable drawable) {
        // set up gl context
        drawable.setAutoSwapBufferMode(true);
        GL gl = drawable.getGL();
        gl = drawable.getGL();

        gl.setSwapInterval(1);
        gl.glShadeModel(GL.GL_FLAT);

        gl.glClearColor(0, 0, 0, 0f);
        gl.glClear(GL.GL_COLOR_BUFFER_BIT);
        gl.glLoadIdentity();

        gl.glRasterPos3f(0, 0, 0);
        gl.glColor3f(1, 1, 1);
        checkGLError(gl, glu, "after init");        
               
        animator = new FPSAnimator(drawable, 60);
    }

    @Override
    public void display(GLAutoDrawable drawable) {
        displayPixmap(drawable);
    }
    
    public void setScaling(int width, int height) {
        sx = stream.getFrameX();
        sy = stream.getFrameY(); 
        
        scaleX = (float) (width - 2 * borders.x) / sx;
        scaleY = (float) (height - 2 * borders.y) / sy;
        
        // which is the more drastic scale (preserves aspect ratio)
        fillHorizontal = (scaleX <= scaleY);
    }
    
    @Override
    public void reshape(GLAutoDrawable drawable, int x, int y, int width, int height) {
        GL gl = drawable.getGL();
        
        checkGLError(gl, glu, "before reshape");  
        if (stream == null) return;
        
        setScaling(width, height);
        
        // re configure projection with new sizes
        setDefaultProjection(gl, drawable); 
        
        // set view port to span whole display
        gl.glViewport(0, 0, width, height);

        repaint();
        checkGLError(gl, glu, "after reshape");
    }

    @Override
    public void displayChanged(GLAutoDrawable drawable, boolean modeChanged, boolean deviceChanged) {
    }

    private void displayPixmap(GLAutoDrawable drawable) {
        GL gl = drawable.getGL();
        checkGLError(gl, glu, "before pixmap");
        if (gl == null) {
            return;
        }
        
        if (stream == null) {
            return;
        }        

        if (!stream.read(frame)) {
            return;
        }

        clearDisplay(gl);
                
        // scale according to most fill
        if (fillHorizontal) {
            gl.glPixelZoom(scaleX, -scaleX); // flips y according to CLCamera output
        }
        else {
            gl.glPixelZoom(scaleY, -scaleY); // flips y according to CLCamera output
        }
        // to UL corner of chip, but must be inside viewport or else it is ignored, breaks on zoom 
        // sy - 1 as coordinate not length
        gl.glRasterPos2f(0, sy - 1); 

        gl.glDrawPixels(sx, sy, GL.GL_BGRA, GL.GL_UNSIGNED_INT_8_8_8_8_REV, frame.getData());
        checkGLError(gl, glu, "after pixmap");
    }

    private float clearDisplay(GL gl) {
        float gray = 0;
        gl.glClearColor(gray, gray, gray, 0f);
        gl.glClear(GL.GL_COLOR_BUFFER_BIT);

        return gray;
    }

    /** Utility method to check for GL errors. Prints stacked up errors up to a limit.
    @param g the GL context
    @param glu the GLU used to obtain the error strings
    @param msg an error message to log to e.g., show the context
     */
    public void checkGLError(GL g, GLU glu, String msg) {
        int error = g.glGetError();
        int nerrors = 3;
        while (error != GL.GL_NO_ERROR && nerrors-- != 0) {
            StackTraceElement[] trace = Thread.currentThread().getStackTrace();
            if (trace.length > 1) {
                String className = trace[2].getClassName();
                String methodName = trace[2].getMethodName();
                int lineNumber = trace[2].getLineNumber();
                log.log(Level.WARNING, "GL error number {0} {1} : {2} at {3}.{4} (line {5})", new Object[]{error, glu.gluErrorString(error), msg, className, methodName, lineNumber});
            } else {
                log.log(Level.WARNING, "GL error number {0} {1} : {2}", new Object[]{error, glu.gluErrorString(error), msg});
            }
//             Thread.dumpStack();
            error = g.glGetError();
        }
    }

    /** Sets the projection matrix so that we getString an orthographic projection that is the size of the
    canvas with z volume -ZCLIP to ZCLIP padded with extra space around the sides.
    
    @param g the GL context
    @param d the GLAutoDrawable canvas
     */
    protected void setDefaultProjection(GL g, GLAutoDrawable d) {
        checkGLError(g, glu, "before setDefaultProjection");
        g.glMatrixMode(GL.GL_PROJECTION);
        g.glLoadIdentity(); // very important to load identity matrix here so this works after first resize!!!
        // now we set the clipping volume so that the volume is clipped according to whether the window is tall (ar>1) or wide (ar<1).

        float bx, by;

        // scale borders to chip coordinates
        if (fillHorizontal) { //width
            bx = borders.x / scaleX; // l,r border in model coordinates
            by = (sy * (scaleY - scaleX) + 2 * borders.y) / (2 * scaleX);
        } 
        else {
            by = borders.y / scaleY;
            bx = (sx * (scaleX - scaleY) + 2 * borders.x) / (2 * scaleY);
            
        }
        // set projection need -1 as coordinates
        g.glOrtho(-bx, (sx + bx - 1), -by, (sy + by - 1), ZCLIP, -ZCLIP); // clip area has same ar as screen!
        g.glMatrixMode(GL.GL_MODELVIEW);
    }
   
}
