package net.sf.jaer2.eventio.processors;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.ComboBox;
import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.raw.RawEvent;
import net.sf.jaer2.eventio.sources.Source;
import net.sf.jaer2.eventio.translators.Translator;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Reflections;

public final class InputProcessor extends Processor {
	private final BlockingQueue<RawEventPacket> inputQueue = new ArrayBlockingQueue<>(32);
	private final List<RawEventPacket> inputToProcess = new ArrayList<>(32);

	private Source connectedSource;
	private Translator eventTranslator;

	/** For displaying and maintaining a link to the current config GUI. */
	private Source currentSourceConfig;

	public InputProcessor() {
		super();
	}

	public Source getConnectedSource() {
		return connectedSource;
	}

	public void setConnectedSource(final Source source) {
		connectedSource = source;

		Processor.logger.debug("ConnectedSource set to: {}.", source);
	}

	public Translator getEventTranslator() {
		return eventTranslator;
	}

	public void setEventTranslator(final Translator translator) {
		eventTranslator = translator;

		// Regenerate output types based on what the Translator can produce.
		rebuildStreamSets();

		Processor.logger.debug("EventTranslator set to: {}.", translator);
	}

	@Override
	protected void setCompatibleInputTypes(@SuppressWarnings("unused") final Set<Class<? extends Event>> inputs) {
		// Empty, doesn't process any inputs at all.
	}

	@Override
	protected void setAdditionalOutputTypes(@SuppressWarnings("unused") final Set<Class<? extends Event>> outputs) {
		// No events exist here by default, they depend on what the selected
		// Chip can output.
	}

	@Override
	protected Set<Class<? extends Event>> updateAdditionalOutputTypes() {
		final Set<Class<? extends Event>> newOutputs = new HashSet<>();

		if (eventTranslator != null) {
			newOutputs.addAll(eventTranslator.getRawEventToEventMappings());
		}

		return newOutputs;
	}

	@Override
	public boolean readyToRun() {
		return ((eventTranslator != null) && (connectedSource != null));
	}

	@Override
	public void run() {
		while (!Thread.currentThread().isInterrupted()) {
			// First forward currently waiting packets from previous processors.
			if (workQueue.drainTo(workToProcess) != 0) {
				getNextProcessor().addAll(workToProcess);

				workToProcess.clear();
			}

			// Then see if there is any conversion to be done.
			if (inputQueue.drainTo(inputToProcess) == 0) {
				// Nothing to be done, next cycle!
				continue;
			}

			// Convert raw events into real ones.
			for (final RawEventPacket inRawEventPacket : inputToProcess) {
				final EventPacketContainer outPacketContainer = new EventPacketContainer(this);

				for (RawEvent rawEvent : inRawEventPacket) {
					eventTranslator.extractEventFromRawEvent(rawEvent, outPacketContainer);
				}

				// Send only packets with some (in)valid events on their way.
				if (outPacketContainer.sizeFull() != 0) {
					getNextProcessor().add(outPacketContainer);
				}
			}

			inputToProcess.clear();
		}
	}

	public void addToInput(final RawEventPacket rawEventPacket) {
		inputQueue.offer(rawEventPacket);
	}

	public void addAllToInput(final Collection<RawEventPacket> rawEventPackets) {
		for (final RawEventPacket rawEventPacket : rawEventPackets) {
			inputQueue.offer(rawEventPacket);
		}
	}

	@Override
	protected void buildGUI() {
		super.buildGUI();

		rootTasksUIRefresh.add(new Runnable() {
			@Override
			public void run() {
				rootLayoutChildren.getChildren().clear();

				if (eventTranslator != null) {
					GUISupport.addLabel(rootLayoutChildren, eventTranslator.toString(), null, null, null);
				}

				if (connectedSource != null) {
					rootLayoutChildren.getChildren().add(connectedSource.getGUI());
				}
			}
		});
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		// Create Translator type chooser box.
		final ComboBox<Class<? extends Translator>> translatorTypeChooser = GUISupport.addComboBox(null,
			Reflections.translatorTypes, 0);
		GUISupport
			.addLabelWithControlsHorizontal(
				rootConfigLayoutChildren,
				"Translator:",
				"Select the Translator you want to use to translate the raw events coming from the source into meaningful ones.",
				translatorTypeChooser);

		rootConfigTasksDialogRefresh.add(new Runnable() {
			@Override
			public void run() {
				if (eventTranslator != null) {
					// Set default value.
					translatorTypeChooser.setValue(eventTranslator.getClass());
				}
			}
		});

		rootConfigTasksDialogOK.add(new Runnable() {
			@Override
			public void run() {
				final Translator translator = Reflections.newInstanceForClass(translatorTypeChooser.getValue());

				if (translator != null) {
					setEventTranslator(translator);
				}
			}
		});

		// Create Source type chooser box.
		final ComboBox<Class<? extends Source>> sourceTypeChooser = GUISupport.addComboBox(null,
			Reflections.sourceTypes, -1);
		GUISupport.addLabelWithControlsHorizontal(rootConfigLayoutChildren, "Source:",
			"Select the input Source you want to use.", sourceTypeChooser);

		sourceTypeChooser.valueProperty().addListener(new ChangeListener<Class<? extends Source>>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Class<? extends Source>> observable,
				final Class<? extends Source> oldValue, final Class<? extends Source> newValue) {
				if ((currentSourceConfig != null) && currentSourceConfig.getClass().equals(newValue)) {
					// If the class didn't change, don't generate a new one!
					return;
				}

				// Don't display old value anymore (if any).
				if (currentSourceConfig != null) {
					rootConfigLayoutChildren.getChildren().remove(currentSourceConfig.getConfigGUI());
				}

				// When the chosen source type changes, create an instance
				// of the new one and save it for future reference, so that
				// when the user clicks OK, it gets saved.
				currentSourceConfig = Reflections.newInstanceForClass(newValue);

				if (currentSourceConfig != null) {
					// Add config GUI for new source instance.
					rootConfigLayoutChildren.getChildren().add(currentSourceConfig.getConfigGUI());
				}
			}
		});

		rootConfigTasksDialogRefresh.add(new Runnable() {
			@Override
			public void run() {
				if (connectedSource != null) {
					// If connectedSource is defined, let's make sure
					// currentSourceConfig reflects that value and its effects.
					if (currentSourceConfig != null) {
						rootConfigLayoutChildren.getChildren().remove(currentSourceConfig.getConfigGUI());
					}

					currentSourceConfig = connectedSource;

					rootConfigLayoutChildren.getChildren().add(currentSourceConfig.getConfigGUI());

					// Set default value.
					sourceTypeChooser.setValue(connectedSource.getClass());
				}
			}
		});

		rootConfigTasksDialogOK.add(new Runnable() {
			@Override
			public void run() {
				if (currentSourceConfig == null) {
					// Enforce setting a source type.
					GUISupport.showDialogError("No Source selected, please do so!");
					return;
				}

				setConnectedSource(currentSourceConfig);
			}
		});
	}
}
