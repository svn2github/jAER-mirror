package net.sf.jaer2.viewer;

import java.nio.ByteBuffer;
import java.util.concurrent.Semaphore;

import javafx.application.Platform;
import javafx.scene.image.ImageView;
import javafx.scene.image.PixelFormat;
import javafx.scene.image.PixelWriter;
import javafx.scene.image.WritableImage;

import com.jogamp.common.nio.Buffers;
import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GL2GL3;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.GLCapabilities;
import com.jogamp.opengl.GLDrawableFactory;
import com.jogamp.opengl.GLEventListener;
import com.jogamp.opengl.GLOffscreenAutoDrawable;
import com.jogamp.opengl.GLProfile;
import com.jogamp.opengl.GLRunnable;
import com.jogamp.opengl.fixedfunc.GLMatrixFunc;

public final class JavaFXImgJOGLConnector extends ImageView {
	protected final WritableImage image;
	protected final PixelWriter pxWriter;
	private final GLOffscreenAutoDrawable glOffscreenDrawable;
	private final GLEventListener readOutListener = new GLReadOutToImage();

	private static final int imageBufferNumber = 4;
	protected final Semaphore syncImageBuffer[] = new Semaphore[JavaFXImgJOGLConnector.imageBufferNumber];
	protected final ByteBuffer imageBuffer[] = new ByteBuffer[JavaFXImgJOGLConnector.imageBufferNumber];

	public JavaFXImgJOGLConnector(final int width, final int height) {
		super();

		image = new WritableImage(width, height);
		pxWriter = image.getPixelWriter();

		setImage(image);

		// Initialize image buffers for pixel data transfer.
		for (int i = 0; i < JavaFXImgJOGLConnector.imageBufferNumber; i++) {
			syncImageBuffer[i] = new Semaphore(1);
			imageBuffer[i] = Buffers.newDirectByteBuffer(4 * width * height);
		}

		GLProfile.initSingleton();
		final GLProfile glp = GLProfile.get(GLProfile.GL2);

		final GLCapabilities caps = new GLCapabilities(glp);
		caps.setOnscreen(false);
		caps.setHardwareAccelerated(true);
		caps.setFBO(true);

		final GLDrawableFactory factory = GLDrawableFactory.getFactory(caps.getGLProfile());

		glOffscreenDrawable = factory.createOffscreenAutoDrawable(null, caps, null, width, height);
		glOffscreenDrawable.setAutoSwapBufferMode(true);

		glOffscreenDrawable.display();

		glOffscreenDrawable.addGLEventListener(readOutListener);
	}

	public synchronized void addGLEventListener(final GLEventListener listener) {
		// Add the new listener at the end of the queue, but before the
		// readOutListener.
		glOffscreenDrawable.addGLEventListener(getGLEventListenerCount(), listener);
	}

	public synchronized void addGLEventListener(final int index, final GLEventListener listener)
		throws IndexOutOfBoundsException {
		// Index can never be negative or bigger than the count (minus the
		// readOutListener).
		if ((index < 0) || (index > getGLEventListenerCount())) {
			throw new IndexOutOfBoundsException();
		}

		// Add new listener at specified index.
		glOffscreenDrawable.addGLEventListener(index, listener);
	}

	public synchronized GLEventListener getGLEventListener(final int index) {
		// Index can never be negative or bigger than the count (minus the
		// readOutListener).
		if ((index < 0) || (index > getGLEventListenerCount())) {
			throw new IndexOutOfBoundsException();
		}

		// Get new listener from specified index.
		return glOffscreenDrawable.getGLEventListener(index);
	}

	public synchronized int getGLEventListenerCount() {
		// Transparently remove the readout listener.
		return (glOffscreenDrawable.getGLEventListenerCount() - 1);

	}

	public synchronized GLEventListener removeGLEventListener(final GLEventListener listener) {
		// Never remove the readOutListener.
		if (listener != readOutListener) {
			return glOffscreenDrawable.removeGLEventListener(listener);
		}

		return null;
	}

	public synchronized void display() {
		glOffscreenDrawable.display();
	}

	public synchronized boolean invoke(final GLRunnable glRunnable) {
		return glOffscreenDrawable.invoke(false, glRunnable);
	}

	public synchronized void destroy() {
		glOffscreenDrawable.destroy();
	}

	private final class GLReadOutToImage implements GLEventListener {
		protected final PixelFormat<ByteBuffer> pxFormat = PixelFormat.getByteBgraPreInstance();

		@Override
		public void display(final GLAutoDrawable drawable) {
			final GL2 gl = drawable.getGL().getGL2();

			// Read back final result.
			int selectedImageBuffer = 0;

			while (!syncImageBuffer[selectedImageBuffer].tryAcquire()) {
				if (Thread.currentThread().isInterrupted()) {
					return;
				}

				selectedImageBuffer = (selectedImageBuffer + 1) % JavaFXImgJOGLConnector.imageBufferNumber;
			}

			gl.glReadBuffer(GL.GL_FRONT);
			gl.glReadPixels(0, 0, (int) image.getWidth(), (int) image.getHeight(), GL.GL_BGRA,
				GL2GL3.GL_UNSIGNED_INT_8_8_8_8_REV, imageBuffer[selectedImageBuffer]);

			final int releaseSelectedImageBuffer = selectedImageBuffer;

			Platform.runLater(new Runnable() {
				@Override
				public void run() {
					// Write current buffer out.
					pxWriter.setPixels(0, 0, (int) image.getWidth(), (int) image.getHeight(), pxFormat,
						imageBuffer[releaseSelectedImageBuffer], ((int) image.getWidth()) * 4);

					syncImageBuffer[releaseSelectedImageBuffer].release();
				}
			});
		}

		@SuppressWarnings("unused")
		@Override
		public void dispose(final GLAutoDrawable drawable) {
			// Empty, no implementation yet.
		}

		@Override
		public void init(final GLAutoDrawable drawable) {
			final GL2 gl = drawable.getGL().getGL2();

			gl.setSwapInterval(0);

			gl.glMatrixMode(GLMatrixFunc.GL_PROJECTION);
			gl.glLoadIdentity();
			gl.glOrthof(0, (int) image.getWidth(), (int) image.getHeight(), 0, 1, -1);

			gl.glMatrixMode(GLMatrixFunc.GL_MODELVIEW);
			gl.glLoadIdentity();
		}

		@SuppressWarnings("unused")
		@Override
		public void reshape(final GLAutoDrawable drawable, final int arg1, final int arg2, final int arg3,
			final int arg4) {
			// Empty, no implementation yet.
		}
	}
}
