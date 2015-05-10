/*
 * ChipRendererDisplayMethod.java
 * 
 * Created on May 4, 2006, 9:07 PM
 * 
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 * 
 * 
 * Copyright May 4, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */
package net.sf.jaer.graphics;

import java.util.Iterator;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GL2ES2;
import com.jogamp.opengl.GL3;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.fixedfunc.GLMatrixFunc;
import com.jogamp.opengl.glu.GLU;

import net.sf.jaer.chip.Chip2D;
import eu.seebetter.ini.chips.davis.DavisDisplayConfigInterface;
import net.sf.jaer.event.ApsDvsEvent;
import net.sf.jaer.event.ApsDvsEventPacket;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.util.EngineeringFormat;

import com.jogamp.opengl.util.gl2.GLUT;

import eu.seebetter.ini.chips.DavisChip;
import eu.seebetter.ini.chips.davis.imu.IMUSample;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.util.Scanner;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.aemonitor.AEConstants;

/**
 * Displays events in space time using a rolling view where old events are
 * erased and new ones are added to the front. In contrast with
 * SpaceTimeEventDisplayMethod, this method smoothly rolls the events through
 * the display. It uses a vertex and fragment shader program to accelerate the
 * rendering.
 *
 * @author tobi, nicolai capocaccia 2015
 */
@Description("Displays events in space time using a rolling view where old events are\n"
        + " * erased and new ones are added to the front.")
@DevelopmentStatus(DevelopmentStatus.Status.InDevelopment)
public class SpaceTimeRollingEventDisplayMethod extends DisplayMethod implements DisplayMethod3D {

    EngineeringFormat engFmt = new EngineeringFormat();

    private DavisDisplayConfigInterface config;
    private boolean displayEvents = true;
    private boolean displayFrames = true;
    boolean spikeListCreated = false;
    int spikeList = 1;
    GLUT glut = null;
    GLU glu = null;
    private boolean shadersInstalled = false;
    int shaderprogram;
    int vertexShader;
    int fragmentShader;
    int vao;
    int vbo;
    final int polarity_vert = 0;
    final int v_vert = 1;
    final int polarity_frag = 0;
    private int BUF_INITIAL_SIZE = 100000;
    ByteBuffer eventBuffer = ByteBuffer.allocateDirect(BUF_INITIAL_SIZE * (Float.SIZE / 8) * 3);
    float rsx = 1;
    float rsy = 1;

    /**
     * Creates a new instance of SpaceTimeEventDisplayMethod
     */
    public SpaceTimeRollingEventDisplayMethod(final ChipCanvas chipCanvas) {
        super(chipCanvas);
    }

    /* 
    
     struct Event {
     GLfloat polarity;
     GLfloat x, y, t;
     };
    
     GLuint polarity_vert = 0;
     GLuint v_vert = 1;
     GLuint polarity_frag = 0;

     void
     generate_buffers() {
     glGenVertexArrays(1, &vao);
     glBindVertexArray(vao);

     glGenBuffers(1, &vbo);
     glBindBuffer(GL_ARRAY_BUFFER, vbo);

     
     glVertexAttribPointer(polarity_vert, 1, GL_FLOAT, GL_FALSE, sizeof(Event),
     reinterpret_cast<void*>(offsetof(Event, polarity)));
     GL_CHECK_ERROR();

     glVertexAttribPointer(v_vert, 3, GL_FLOAT, GL_FALSE, sizeof(Event),
     reinterpret_cast<void*>(offsetof(Event, x)));
     GL_CHECK_ERROR();
     }

     
     */
    private void installShaders(GL2 gl) throws IOException {
        if (shadersInstalled) {
            return;
        }
        gl.glEnable(GL3.GL_PROGRAM_POINT_SIZE);

        shadersInstalled = true;
        IntBuffer b = IntBuffer.allocate(8); // buffer to hold return values
        shaderprogram = gl.glCreateProgram();
        vertexShader = gl.glCreateShader(GL2ES2.GL_VERTEX_SHADER);
        fragmentShader = gl.glCreateShader(GL2ES2.GL_FRAGMENT_SHADER);
        checkGLError(gl, "creating shaders and shader program");

        String vsrc = readFromStream(SpaceTimeRollingEventDisplayMethod.class
                .getResourceAsStream("SpaceTimeRollingEventDisplayMethod_Vertex.glsl"));
        gl.glShaderSource(vertexShader, 1, new String[]{vsrc}, (int[]) null, 0);
        gl.glCompileShader(vertexShader);
        b.clear();
        gl.glGetShaderiv(vertexShader, GL2ES2.GL_COMPILE_STATUS, b);
        if (b.get(0) != GL.GL_TRUE) {
            log.warning("error compiling vertex shader");
            printShaderLog(gl);
        }
        checkGLError(gl, "compiling vertex shader");

        String fsrc = readFromStream(SpaceTimeRollingEventDisplayMethod.class
                .getResourceAsStream("SpaceTimeRollingEventDisplayMethod_Fragment.glsl"));
        gl.glShaderSource(fragmentShader, 1, new String[]{fsrc}, (int[]) null, 0);
        gl.glCompileShader(fragmentShader);
        b.clear();
        gl.glGetShaderiv(fragmentShader, GL2ES2.GL_COMPILE_STATUS, b);
        if (b.get(0) != GL.GL_TRUE) {
            log.warning("error compiling fragment shader");
            printShaderLog(gl);
        }
        checkGLError(gl, "compiling fragment shader");

        gl.glAttachShader(shaderprogram, vertexShader);
        gl.glAttachShader(shaderprogram, fragmentShader);

        gl.glLinkProgram(shaderprogram);
        b.clear();
//        gl.glGetShaderiv(shaderprogram, GL2ES2.GL_COMPILE_STATUS, b);
//        if (b.get(0) != GL.GL_TRUE) {
//            log.warning("error linking shader program");
//            printShaderLog(gl);
//        }

        checkGLError(gl, "linking shader program");
        b.clear();
        gl.glGenVertexArrays(1, b);
        vao = b.get(0);
        gl.glBindVertexArray(vao);
        b.clear();
        gl.glGenBuffers(1, b);
        vbo = b.get(0);
        checkGLError(gl, "setting up vertex array and vertex buffer");

        gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vbo);
        gl.glBindAttribLocation(shaderprogram, polarity_vert, "polarity"); // symbolic names in vertex and fragment shaders
        gl.glBindAttribLocation(shaderprogram, v_vert, "v");
        gl.glBindAttribLocation(shaderprogram, polarity_frag, "frag_polarity");
        checkGLError(gl, "binding shader attributes");

        gl.glVertexAttribPointer(polarity_vert, 1, GL.GL_FLOAT, false, 4 * Float.SIZE / 8, 3);
        gl.glVertexAttribPointer(v_vert, 3, GL.GL_FLOAT, false, 4 * Float.SIZE / 8, 0);
        checkGLError(gl, "setting vertex attribute pointers");
    }

    private void uninstallShaders(GL2 gl) {
//        gl.glDetachShader(shaderprogram, vertexShader);
//        gl.glDetachShader(shaderprogram, fragmentShader);
//
//        checkGLError(gl);

    }

    @Override
    public void display(final GLAutoDrawable drawable) {
        // GL2 gl=setupGL(drawable);
        // AEChipRenderer renderer = (AEChipRenderer) (getChipCanvas().getRenderer());
        // log.info("display");
        final Chip2D chip = getChipCanvas().getChip();
        if (glut == null) {
            glut = new GLUT();
        }
        final GL2 gl = drawable.getGL().getGL2();
        if (gl == null) {
            log.warning("null GL context - not displaying");
            return;
        }
        try {
            installShaders(gl);
        } catch (IOException ex) {
            log.warning("could not load shaders: " + ex.toString());
            return;
        }
//        gl.glMatrixMode(GLMatrixFunc.GL_PROJECTION);
//        gl.glLoadIdentity(); // very important to load identity matrix here so this works after first resize!!!
//        gl.glOrtho(0, drawable.getSurfaceWidth(), 0, drawable.getSurfaceHeight(), 10000, -10000);
//        gl.glMatrixMode(GLMatrixFunc.GL_MODELVIEW);
//        gl.glViewport(0, 0, drawable.getSurfaceWidth(), drawable.getSurfaceHeight());

        // render events
        final EventPacket packet = (EventPacket) chip.getLastData();
        if (packet == null) {
            log.warning("null packet to render");
            return;
        }
        final int n = packet.getSize();
        if (n == 0) {
            return;
        }
        final int t0 = packet.getFirstTimestamp();
        final int dt = packet.getDurationUs() + 1;
        float z;
        float rsx;
        rsx = 1f / chip.getSizeX();
        float rsy;
        rsy = 1f / chip.getSizeY();

        Iterator evItr = packet.iterator();
        if (packet instanceof ApsDvsEventPacket) {
            final ApsDvsEventPacket apsPacket = (ApsDvsEventPacket) packet;
            evItr = apsPacket.fullIterator();
            if ((config == null) && (chip != null) && (chip instanceof DavisChip)) {
                config = (DavisDisplayConfigInterface) chip.getBiasgen();
            }
            if (config != null) {
                displayEvents = config.isDisplayEvents();
                displayFrames = config.isDisplayFrames();
            }
        }
        eventBuffer.clear();// TODO should not really clear, rather should erase old events
        int nEvents = 0;
        while (evItr.hasNext()) {
            final BasicEvent ev = (BasicEvent) evItr.next();

            // Check if event needs to be rendered (APS/DVS).
            if (ev instanceof ApsDvsEvent) {
                final ApsDvsEvent apsEv = (ApsDvsEvent) ev;

                if ((!displayFrames && apsEv.isSampleEvent()) || (!displayEvents && apsEv.isDVSEvent())
                        || ((apsEv instanceof IMUSample) && ((IMUSample) apsEv).imuSampleEvent)) {
                    continue;
                }
            }
            z = (float) (ev.timestamp - t0) / dt; // z goes from 0 (oldest) to 1 (youngest)
//                    computeRGBFromZ(z, rgb);
            eventBuffer.putFloat(rsx * ev.x); // all vertices normalized to 0-1 range
            eventBuffer.putFloat(rsy * ev.y);
            eventBuffer.putFloat(z);
            eventBuffer.putFloat((float) (ev.address & 1)); // hack for polarity TODO get rid of polarity for generic chip use
            nEvents++;
        }
        eventBuffer.flip();
        renderEvents(gl, drawable, eventBuffer, nEvents, dt);

    }

    FloatBuffer mv = FloatBuffer.allocate(16);
    FloatBuffer proj = FloatBuffer.allocate(16);

    void renderEvents(GL2 gl, GLAutoDrawable drawable, ByteBuffer b, int nEvents, int dt) {
        gl.glClearColor(0, 0, 0, 0);
        gl.glClear(GL.GL_COLOR_BUFFER_BIT);

//        gl.glMatrixMode(GLMatrixFunc.GL_PROJECTION);
//        gl.glPushMatrix();
//        gl.glLoadIdentity();
//        gl.glViewport(0, 0, drawable.getSurfaceWidth(), drawable.getSurfaceHeight());
//        gl.glOrtho(0, 1, 0, 1, -100, 100); // clip area has same aspect ratio as screen!
//
//        gl.glMatrixMode(GLMatrixFunc.GL_MODELVIEW);
        gl.glPushMatrix();
        gl.glLoadIdentity();

        // rotate viewpoint
//        gl.glLoadIdentity();
//        gl.glMatrixMode(GLMatrixFunc.GL_MODELVIEW);
        gl.glRotatef(getChipCanvas().getAngley(), 0, 1, 0); // rotate viewpoint by angle deg around the y axis
        gl.glRotatef(getChipCanvas().getAnglex(), 1, 0, 0); // rotate viewpoint by angle deg around the x axis
        gl.glTranslatef(getChipCanvas().getOrigin3dx() * rsx, getChipCanvas().getOrigin3dy() * rsy, 0);
        // save matrices here for vertex shader use
        gl.glGetFloatv(GL2.GL_PROJECTION_MATRIX, proj);
        gl.glGetFloatv(GL2.GL_MODELVIEW_MATRIX, mv);

        gl.glUseProgram(shaderprogram);
        gl.glValidateProgram(shaderprogram);
//        IntBuffer i = IntBuffer.allocate(8);
//        gl.glGetShaderiv(shaderprogram, GL2ES2.GL_VALIDATE_STATUS, i);
//        if (i.get(0) != GL.GL_TRUE) {
//            log.warning("error compiling vertex shader");
//            printShaderLog(gl);
//        }

        checkGLError(gl, "using shader program");

        // get matrix and supply to shader - see http://www.cs.rutgers.edu/~decarlo/428/jogl.html
        // get IDs to access the data
        // Get the current matrix on the MODELVIEW stack
        int mvId = gl.glGetUniformLocation(shaderprogram, "mv"); // TODO can do once at init
        gl.glUniformMatrix4fv(mvId, 1, false, mv);

        int projId = gl.glGetUniformLocation(shaderprogram, "proj");
        gl.glUniformMatrix4fv(projId, 1, false, proj);
        checkGLError(gl, "setting model/view matrix");

        gl.glBindVertexArray(vao);
        gl.glEnableVertexAttribArray(polarity_vert);
        gl.glEnableVertexAttribArray(v_vert);
        gl.glBindBuffer(GL.GL_ARRAY_BUFFER, vbo);
        gl.glBufferData(GL.GL_ARRAY_BUFFER, b.limit(), b, GL2ES2.GL_STREAM_DRAW);
        checkGLError(gl, "binding vertex buffers");

//        gl.glEnable(GL.GL_DEPTH_TEST);
//        gl.glDepthMask(true);
//        gl.glEnable(GL.GL_BLEND);
//        gl.glBlendFunc(GL.GL_ONE, GL.GL_ONE);
//        gl.glBlendEquation(GL.GL_FUNC_ADD);
//        checkGLError(gl, "setting blend function");
        // draw
        gl.glDrawArrays(GL.GL_POINTS, 0, nEvents);
        checkGLError(gl, "drawArrays");
        // draw 3d axes
        gl.glColor3f(0, 0, 1);
        gl.glLineWidth(.4f);

        gl.glBegin(GL.GL_LINES);
        gl.glVertex3f(0, 0, 0);
//        gl.glVertex3f(chip.getSizeX(), 0, 0);
        gl.glVertex3f(1, 0, 0);

        gl.glVertex3f(0, 0, 0);
        gl.glVertex3f(0, 1, 0);
//        gl.glVertex3f(0, chip.getSizeY(), 0);

        gl.glVertex3f(0, 0, 0);
//        gl.glVertex3f(0, 0, chip.getMaxSize());
        gl.glVertex3f(0, 0, 1);
        gl.glEnd();

        // draw axes labels x,y,t. See tutorial at http://jerome.jouvie.free.fr/OpenGl/Tutorials/Tutorial18.php
        final int font = GLUT.BITMAP_HELVETICA_18;
        final int FS = 1; // distance in pixels of text from endZoom of axis
        gl.glRasterPos3f(1, 0, 0);
//        gl.glRasterPos3f(chip.getSizeX() + FS, 0, 0);
        glut.glutBitmapString(font, "x=" + chip.getSizeX());
        gl.glRasterPos3f(0, 1, 0);
//        gl.glRasterPos3f(0, chip.getSizeY() + FS, 0);
        glut.glutBitmapString(font, "y=" + chip.getSizeY());
        gl.glRasterPos3f(0, 0, 1);
//        gl.glRasterPos3f(0, 0, chip.getMaxSize() + FS);
        glut.glutBitmapString(font, "t=" + engFmt.format(dt * AEConstants.TICK_DEFAULT_US * 1e-6f) + "s");
        checkGLError(gl, "drawing axes labels");

        gl.glPopMatrix(); // pop out so that shader uses matrix without applying it twice
//        gl.glMatrixMode(GLMatrixFunc.GL_PROJECTION);
//        gl.glPopMatrix(); // pop out so that shader uses matrix without applying it twice
        // re-enable depth sorting for everything else
//        gl.glDepthMask(true);
    }

    boolean checkGLError(final GL2 gl, String msg) {
        boolean r = false;
        int error = gl.glGetError();
        int nerrors = 10;
        while ((error != GL.GL_NO_ERROR) && (nerrors-- != 0)) {
            if (glu == null) {
                glu = new GLU();
            }
            StackTraceElement[] st = Thread.currentThread().getStackTrace();
            log.warning("GL error number " + error + " " + glu.gluErrorString(error) + "\n");
            new RuntimeException("GL error number " + error + " " + glu.gluErrorString(error)).printStackTrace();
            error = gl.glGetError();
            r = true;
        }
        return r;
    }

    protected float[] rgb = new float[3];

    protected final void computeRGBFromZ(final float z, float[] rgb) {
        rgb[0] = z;
        rgb[1] = 1 - z;
        rgb[2] = 0;
    }

    @Override
    protected void onDeregistration() {
    }

    @Override
    protected void onRegistration() {
    }

    private void printShaderLog(GL2 gl) {
        IntBuffer b = IntBuffer.allocate(8);
        gl.glGetProgramiv(shaderprogram, GL2ES2.GL_INFO_LOG_LENGTH, b);
        int logLength = b.get(0);
        ByteBuffer bb = ByteBuffer.allocate(logLength);
        b.clear();
        gl.glGetProgramInfoLog(shaderprogram, logLength, b, bb);
        String v = new String(bb.array(), java.nio.charset.StandardCharsets.UTF_8);
        log.info(v);

    }

    private String readFromStream(InputStream ins) throws IOException {
        if (ins == null) {
            throw new IOException("Could not read from stream.");
        }
        StringBuffer buffer = new StringBuffer();
        Scanner scanner = new Scanner(ins);
        try {
            while (scanner.hasNextLine()) {
                buffer.append(scanner.nextLine() + "\n");
            }
        } finally {
            scanner.close();
        }

        return buffer.toString();
    }

}
