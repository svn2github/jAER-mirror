package net.sf.jaer2.eventio.processors;

import java.util.Collection;
import java.util.Set;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.ComboBox;
import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.sinks.Sink;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Reflections;

public final class OutputProcessor extends Processor {
	private final BlockingQueue<EventPacketContainer> outputQueue = new ArrayBlockingQueue<>(32);

	private Sink connectedSink;

	/** For displaying and maintaining a link to the current config GUI. */
	private Sink currentSinkConfig;

	public OutputProcessor() {
		super();
	}

	public Sink getConnectedSink() {
		return connectedSink;
	}

	public void setConnectedSink(final Sink sink) {
		connectedSink = sink;

		Processor.logger.debug("ConnectedSink set to: {}.", sink);
	}

	@Override
	protected void setCompatibleInputTypes(final Set<Class<? extends Event>> inputs) {
		// Accepts all inputs.
		inputs.add(Event.class);
	}

	@SuppressWarnings("unused")
	@Override
	protected void setAdditionalOutputTypes(final Set<Class<? extends Event>> outputs) {
		// Empty, doesn't add any new output types to the system.
	}

	@Override
	protected Set<Class<? extends Event>> updateAdditionalOutputTypes() {
		// Never changes it's returned output types (which are none!).
		throw new UnsupportedOperationException();
	}

	@Override
	public boolean readyToRun() {
		return (connectedSink != null);
	}

	@Override
	public void run() {
		while (!Thread.currentThread().isInterrupted()) {
			if (workQueue.drainTo(workToProcess) == 0) {
				// No elements, retry.
				continue;
			}

			for (final EventPacketContainer container : workToProcess) {
				// Check that this container is interesting for this processor.
				if (processContainer(container)) {
					outputQueue.add(container);
				}

				if (getNextProcessor() != null) {
					getNextProcessor().add(container);
				}
			}

			workToProcess.clear();
		}
	}

	public EventPacketContainer getFromOutput() {
		return outputQueue.poll();
	}

	public void getAllFromOutput(final Collection<EventPacketContainer> eventPacketContainers) {
		outputQueue.drainTo(eventPacketContainers);
	}

	@Override
	protected void buildGUI() {
		super.buildGUI();

		rootTasksUIRefresh.add(new Runnable() {
			@Override
			public void run() {
				rootLayoutChildren.getChildren().clear();

				if (connectedSink != null) {
					rootLayoutChildren.getChildren().add(connectedSink.getGUI());
				}
			}
		});
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		// Create Sink type chooser box.
		final ComboBox<Class<? extends Sink>> sinkTypeChooser = GUISupport.addComboBox(null, Reflections.sinkTypes, -1);
		GUISupport.addLabelWithControlsHorizontal(rootConfigLayoutChildren, "Sink:",
			"Select the output Sink you want to use.", sinkTypeChooser);

		sinkTypeChooser.valueProperty().addListener(new ChangeListener<Class<? extends Sink>>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Class<? extends Sink>> observable,
				final Class<? extends Sink> oldValue, final Class<? extends Sink> newValue) {
				if ((currentSinkConfig != null) && currentSinkConfig.getClass().equals(newValue)) {
					// If the class didn't change, don't generate a new one!
					return;
				}

				// Don't display old value anymore (if any).
				if (currentSinkConfig != null) {
					rootConfigLayoutChildren.getChildren().remove(currentSinkConfig.getConfigGUI());
				}

				// When the chosen sink type changes, create an instance
				// of the new one and save it for future reference, so that
				// when the user clicks OK, it gets saved.
				currentSinkConfig = Reflections.newInstanceForClass(newValue);

				if (currentSinkConfig != null) {
					// Add config GUI for new sink instance.
					rootConfigLayoutChildren.getChildren().add(currentSinkConfig.getConfigGUI());
				}
			}
		});

		rootConfigTasksDialogRefresh.add(new Runnable() {
			@Override
			public void run() {
				if (connectedSink != null) {
					// If connectedSink is defined, let's make sure
					// currentSinkConfig reflects that value and its effects.
					if (currentSinkConfig != null) {
						rootConfigLayoutChildren.getChildren().remove(currentSinkConfig.getConfigGUI());
					}

					currentSinkConfig = connectedSink;

					rootConfigLayoutChildren.getChildren().add(currentSinkConfig.getConfigGUI());

					// Set default value.
					sinkTypeChooser.setValue(connectedSink.getClass());
				}
			}
		});

		rootConfigTasksDialogOK.add(new Runnable() {
			@Override
			public void run() {
				if (currentSinkConfig == null) {
					// Enforce setting a sink type.
					GUISupport.showDialogError("No Sink selected, please do so!");
					return;
				}

				setConnectedSink(currentSinkConfig);
			}
		});
	}
}
