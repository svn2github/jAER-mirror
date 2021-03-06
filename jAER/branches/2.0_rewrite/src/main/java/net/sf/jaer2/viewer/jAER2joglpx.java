package net.sf.jaer2.viewer;

import java.awt.BorderLayout;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

import javax.swing.JFrame;

import net.sf.jaer2.viewer.BufferWorks.BUFFER_FORMATS;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.GLCapabilities;
import com.jogamp.opengl.GLEventListener;
import com.jogamp.opengl.GLProfile;
import com.jogamp.opengl.awt.GLCanvas;
import com.jogamp.opengl.fixedfunc.GLMatrixFunc;
import com.jogamp.opengl.util.Animator;

public class jAER2joglpx implements GLEventListener {
	private static long FPS = 0;
	private static final int RSIZE = 2;
	private static final int XLEN = 640;
	private static final int YLEN = 480;

	private static final BufferWorks buffer = new BufferWorks(jAER2joglpx.XLEN, jAER2joglpx.YLEN,
		BUFFER_FORMATS.BYTE_NOALPHA, 0);

	public static void main(final String[] args) {
		GLProfile.initSingleton();
		final GLProfile glp = GLProfile.get(GLProfile.GL2);
		final GLCapabilities caps = new GLCapabilities(glp);
		final GLCanvas canvas = new GLCanvas(caps);

		final JFrame jframe = new JFrame("jAER2 JOGL Test");
		jframe.getContentPane().add(canvas, BorderLayout.CENTER);
		jframe.setSize(1920, 1080);
		jframe.setVisible(true);

		canvas.addGLEventListener(new jAER2joglpx());

		final Animator animator = new Animator();
		animator.add(canvas);
		animator.setRunAsFastAsPossible(true);
		animator.start();

		final Thread t = new Thread(new Runnable() {
			@Override
			public void run() {
				final long start = System.currentTimeMillis();

				while (!Thread.currentThread().isInterrupted()) {
					try {
						Thread.sleep(1000);
					}
					catch (final InterruptedException e) {
						return;
					}

					final long fpsPrint = jAER2joglpx.FPS / ((System.currentTimeMillis() - start) / 1000);
					System.out.println("FPS are: " + fpsPrint);
				}
			}
		});
		t.start();

		jframe.addWindowListener(new WindowAdapter() {
			@Override
			public void windowClosing(final WindowEvent windowevent) {
				t.interrupt();
				animator.stop();
				jframe.dispose();
				System.exit(0);
			}
		});
	}

	@Override
	public void display(final GLAutoDrawable drawable) {
		jAER2joglpx.FPS++;

		jAER2joglpx.buffer.update();

		render(drawable);
	}

	@Override
	public void dispose(final GLAutoDrawable drawable) {
	}

	@Override
	public void init(final GLAutoDrawable drawable) {
		final GL2 gl = drawable.getGL().getGL2();

		gl.setSwapInterval(0);

		gl.glMatrixMode(GLMatrixFunc.GL_PROJECTION);
		gl.glLoadIdentity();
		gl.glOrthof(0, 1920, 0, 1080, -1, 1);

		gl.glMatrixMode(GLMatrixFunc.GL_MODELVIEW);
		gl.glLoadIdentity();

		gl.glViewport(0, 0, 1920, 1080);
	}

	@Override
	public void reshape(final GLAutoDrawable drawable, final int arg1, final int arg2, final int arg3, final int arg4) {
	}

	private void render(final GLAutoDrawable drawable) {
		final GL2 gl = drawable.getGL().getGL2();

		gl.glClear(GL.GL_COLOR_BUFFER_BIT);

		gl.glPixelZoom(jAER2joglpx.RSIZE, jAER2joglpx.RSIZE);

		gl.glDrawPixels(jAER2joglpx.XLEN, jAER2joglpx.YLEN, jAER2joglpx.buffer.getGLColorFormat(),
			jAER2joglpx.buffer.getGLFormat(), jAER2joglpx.buffer.getBuffer());

		gl.glFlush();
	}
}
