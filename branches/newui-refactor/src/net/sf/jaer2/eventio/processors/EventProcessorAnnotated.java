package net.sf.jaer2.eventio.processors;

import javafx.scene.layout.Pane;

import javax.media.opengl.GLAutoDrawable;

import net.sf.jaer2.eventio.ProcessorChain;
import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;

public abstract class EventProcessorAnnotated extends EventProcessor {
	public EventProcessorAnnotated(final ProcessorChain chain) {
		super(chain);
	}

	public abstract Object prepareAnnotateEvents(EventPacketContainer container);

	public abstract void annotateEvents(EventPacketContainer container, Object annotateData, GLAutoDrawable glDrawable,
		Pane fxPane);

	@Override
	public void run() {
		while (!Thread.currentThread().isInterrupted()) {
			if (workQueue.drainTo(toProcess) == 0) {
				// No elements, retry.
				continue;
			}

			for (final EventPacketContainer container : toProcess) {
				processEvents(container);

				// Annotation support.
				container.annotateDataSetsAdd(prepareAnnotateEvents(container));

				// TODO: add to next processor's queue.
			}

			toProcess.clear();
		}
	}
}