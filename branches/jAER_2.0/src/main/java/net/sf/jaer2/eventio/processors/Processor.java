package net.sf.jaer2.eventio.processors;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CopyOnWriteArrayList;

import javafx.event.EventHandler;
import javafx.geometry.Insets;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.control.SelectionMode;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import net.sf.jaer2.eventio.ProcessorChain;
import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.util.CollectionsUpdate;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.PairRO;
import net.sf.jaer2.util.Reflections;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class Processor implements Runnable {
	/**
	 * Enumeration containing the available processor types and their string
	 * representations for printing.
	 */
	public static enum ProcessorTypes {
		INPUT_PROCESSOR("Input"),
		OUTPUT_PROCESSOR("Output"),
		EVENT_PROCESSOR("Event");

		private final String str;

		private ProcessorTypes(final String s) {
			str = s;
		}

		@Override
		public final String toString() {
			return str;
		}
	}

	/** Local logger for log messages. */
	protected static final Logger logger = LoggerFactory.getLogger(Processor.class);

	/** Processor identification ID. */
	protected final int processorId;
	/** Processor identification Name. */
	protected final String processorName;

	/** Chain this processor belongs to. */
	protected ProcessorChain parentChain;
	/** Previous processor in the ordered chain. */
	private Processor prevProcessor;
	/** Next processor in the ordered chain. */
	private Processor nextProcessor;

	// Processor type management
	/** Defines which Event types this Processor can work on. */
	private final Set<Class<? extends Event>> compatibleInputTypes = new HashSet<>();
	/** Defines which Event types this Processor creates and then outputs. */
	private final Set<Class<? extends Event>> additionalOutputTypes = new HashSet<>();

	protected static final class Stream extends PairRO<Class<? extends Event>, Integer> {
		public Stream(final Class<? extends Event> one, final Integer two) {
			super(one, two);
		}
	}

	// Processor stream management
	/** Defines which streams of events this Processor can work on. */
	private final List<Stream> inputStreams = new ArrayList<>();
	/**
	 * Defines which streams of events this Processor will work on, based on
	 * user configuration.
	 * This is strictly a subset of inputStreams and is automatically updated
	 * when either inputStreams or the selection is changed, thanks to JavaFX
	 * observables and bindings.
	 */
	private final List<Stream> selectedInputStreams = new CopyOnWriteArrayList<>();
	/**
	 * Defines which streams of events this Processor can output, based upon the
	 * Processor itself and all previous processors before it in the chain.
	 */
	private final List<Stream> outputStreams = new ArrayList<>();
	/**
	 * Input streams on which this Processor is working on, based on user
	 * configuration. This is the fast, thread-safe counter-part to
	 * selectedInputStreams, for use inside processors, and as such limited to
	 * read-only operations.
	 */
	protected final List<Stream> selectedInputStreamsReadOnly = Collections
		.unmodifiableList(selectedInputStreams);

	/** Queue containing all containers to process. */
	protected final BlockingQueue<EventPacketContainer> workQueue = new ArrayBlockingQueue<>(16);
	/**
	 * List containing all containers that are currently being worked on (inside
	 * the Processor, not thread-safe!). Never bigger than {@link #workQueue}.
	 */
	protected final List<EventPacketContainer> workToProcess = new ArrayList<>(16);

	/** Main GUI layout - Horizontal Box. */
	private HBox rootLayout;
	/** Main GUI layout for Sub-Classes - Vertical Box. */
	protected VBox rootLayoutChildren;

	/** Main GUI GUI: tasks to execute when related data changes. */
	protected final List<Runnable> rootTasksUIRefresh = new ArrayList<>();

	/** Configuration GUI layout - Vertical Box. */
	private VBox rootConfigLayout;
	/** Configuration GUI layout for Sub-Classes - Vertical Box. */
	protected VBox rootConfigLayoutChildren;

	/** Configuration GUI: tasks to execute before showing the dialog. */
	protected final List<Runnable> rootConfigTasksDialogRefresh = new ArrayList<>();
	/** Configuration GUI: tasks to execute on clicking OK. */
	protected final List<Runnable> rootConfigTasksDialogOK = new ArrayList<>();

	public Processor() {
		processorId = 0;
		processorName = getClass().getSimpleName();

		// Fill in the type information from the extending sub-classes.
		final Set<Class<? extends Event>> loadedCompatibleInputTypes = new HashSet<>();
		setCompatibleInputTypes(loadedCompatibleInputTypes);

		final Set<Class<? extends Event>> loadedAdditionalOutputTypes = new HashSet<>();
		setAdditionalOutputTypes(loadedAdditionalOutputTypes);

		// Inflate compatibleInputTypes, so as to also consider sub-classes.
		final Set<Class<? extends Event>> inflatedLoadedCompatibleInputTypes = new HashSet<>();
		for (final Class<? extends Event> clazz : loadedCompatibleInputTypes) {
			inflatedLoadedCompatibleInputTypes.addAll(Reflections.getSubClasses(clazz));
		}
		loadedCompatibleInputTypes.addAll(inflatedLoadedCompatibleInputTypes);

		// Now update the present, main data structures with the new
		// information. This is done in such a way as to preserve the content
		// loaded from the saved chains and processors as much as possible, but
		// at the same time reflect possible updates in the types definitions
		// themselves and in their inheritance tree.
		CollectionsUpdate.replaceNonDestructive(compatibleInputTypes, loadedCompatibleInputTypes);

		CollectionsUpdate.replaceNonDestructive(additionalOutputTypes, loadedAdditionalOutputTypes);

		Processor.logger.debug("Created Processor {}.", this);
	}

	/**
	 * Return the ID number of this processor.
	 *
	 * @return processor ID number.
	 */
	public final int getProcessorId() {
		return processorId;
	}

	/**
	 * Return the name of this processor.
	 *
	 * @return processor name.
	 */
	public final String getProcessorName() {
		return processorName;
	}

	/**
	 * Return the chain this processor belongs to.
	 *
	 * @return parent chain.
	 */
	public final ProcessorChain getParentChain() {
		return parentChain;
	}

	/**
	 * Set the chain this processor belongs to.
	 *
	 * @param chain
	 *            parent chain.
	 */
	public final void setParentChain(final ProcessorChain chain) {
		parentChain = chain;

		// Update processor ID, while keeping the field read-only.
		if (processorId == 0) {
			Reflections.setFinalField(this, "processorId", parentChain.getNextAvailableProcessorID());

			// Update UI to show new ID number.
			GUISupport.runTasksCollection(rootTasksUIRefresh);
		}
	}

	public final Processor getPrevProcessor() {
		return prevProcessor;
	}

	public final void setPrevProcessor(final Processor prev) {
		prevProcessor = prev;

		// StreamSets depend on the previous processor.
		rebuildStreamSets();
	}

	public final Processor getNextProcessor() {
		return nextProcessor;
	}

	public final void setNextProcessor(final Processor next) {
		nextProcessor = next;

		// Update UI to show/hide the Types box.
		GUISupport.runTasksCollection(rootTasksUIRefresh);
	}

	protected abstract void setCompatibleInputTypes(Set<Class<? extends Event>> inputs);

	protected abstract void setAdditionalOutputTypes(Set<Class<? extends Event>> outputs);

	/**
	 * Updates the list of additional output types by replacing it wholly
	 * with the one returned by the user through this function.
	 *
	 * @return set of all the types that this processor can emit.
	 *
	 * @throws UnsupportedOperationException
	 *             not supported, since output types do never change.
	 */
	protected abstract Set<Class<? extends Event>> updateAdditionalOutputTypes();

	private List<Stream> getAllOutputStreams() {
		return Collections.unmodifiableList(outputStreams);
	}

	private static final class StreamComparator implements Comparator<Stream> {
		@Override
		public int compare(final Stream stream1, final Stream stream2) {
			if (stream1.getSecond() > stream2.getSecond()) {
				return 1;
			}

			if (stream1.getSecond() < stream2.getSecond()) {
				return -1;
			}

			return 0;
		}
	}

	private void rebuildInputStreams() {
		if (prevProcessor != null) {
			final List<Stream> compatibleInputStreams = new ArrayList<>();

			// Add all outputs from previous Processor, filtering incompatible
			// Event types out.
			for (final Stream stream : prevProcessor.getAllOutputStreams()) {
				if (compatibleInputTypes.contains(stream.getFirst())) {
					compatibleInputStreams.add(stream);
				}
			}

			CollectionsUpdate.replaceNonDestructive(inputStreams, compatibleInputStreams);

			// Sort list by source ID.
			Collections.sort(inputStreams, new StreamComparator());
		}
		else {
			inputStreams.clear();
		}

		selectedInputStreams.retainAll(inputStreams);
	}

	private void rebuildOutputStreams() {
		final List<Stream> allOutputStreams = new ArrayList<>();

		// Add all outputs from previous Processor, as well as outputs produced
		// by the current Processor.
		if (prevProcessor != null) {
			allOutputStreams.addAll(prevProcessor.getAllOutputStreams());
		}

		// Ensure we're using the current, correct data for
		// additionalOutputTypes.
		try {
			CollectionsUpdate.replaceNonDestructive(additionalOutputTypes, updateAdditionalOutputTypes());
		}
		catch (final UnsupportedOperationException e) {
			// Ignore UnsupportedOperationException, it's expected.
		}

		for (final Class<? extends Event> outputType : additionalOutputTypes) {
			allOutputStreams.add(new Stream(outputType, processorId));
		}

		CollectionsUpdate.replaceNonDestructive(outputStreams, allOutputStreams);

		// Sort list by source ID.
		Collections.sort(outputStreams, new StreamComparator());
	}

	public final void rebuildStreamSets() {
		GUISupport.runOnJavaFXThread(new Runnable() {
			@Override
			public void run() {
				Processor.logger.debug("Rebuilding StreamSets for {}.", Processor.this.toString());

				rebuildInputStreams();
				rebuildOutputStreams();

				// Update UI after changes to streams.
				GUISupport.runTasksCollection(rootTasksUIRefresh);

				// Call recursively on the next Processor, so that the rest of
				// the chain gets updated correctly.
				if (nextProcessor != null) {
					nextProcessor.rebuildStreamSets();
				}
				else {
					// Rebuilding the StreamSets always constitutes a structural
					// change.
					parentChain.newStructuralChangesToCommit();
				}
			}
		});
	}

	/**
	 * Check if a container is to be processed by this processor.
	 * This is the case if it contains <Type, Source> combinations that are
	 * relevant, based upon the configuration done by the user.
	 *
	 * @param container
	 *            the EventPacket container to check.
	 * @return whether relevant EventPackets are present or not.
	 */
	public final boolean processContainer(final EventPacketContainer container) {
		for (final Stream relevant : selectedInputStreams) {
			if (container.getPacket(relevant.getFirst(), relevant.getSecond()) != null) {
				return true;
			}
		}

		return false;
	}

	public final void add(final EventPacketContainer container) {
		workQueue.offer(container);
	}

	public final void addAll(final Collection<EventPacketContainer> containers) {
		for (final EventPacketContainer container : containers) {
			workQueue.offer(container);
		}
	}

	protected abstract boolean readyToRun();

	/**
	 * Get the graphical layout corresponding to this class, so that it can be
	 * displayed somewhere by adding it to a Scene.
	 *
	 * @return GUI reference to display.
	 */
	synchronized public final Pane getGUI() {
		if (rootLayout == null) {
			rootLayout = new HBox(10);
			rootLayoutChildren = new VBox(5);

			buildGUI();

			// Ensure display of all newly built GUI elements.
			GUISupport.runTasksCollection(rootTasksUIRefresh);
		}

		return rootLayout;
	}

	/**
	 * Create the base GUI elements and add them to the rootLayout.
	 */
	protected void buildGUI() {
		// Box holding information and controls for the processor.
		final VBox processorBox = new VBox(5);
		processorBox.setPadding(new Insets(5));
		processorBox.getStyleClass().add("border-box");
		rootLayout.getChildren().add(processorBox);

		// Name of processor.
		final Label processorNameID = GUISupport.addLabel(processorBox, toString(), null, null, null);

		rootTasksUIRefresh.add(new Runnable() {
			@Override
			public void run() {
				processorNameID.setText(Processor.this.toString());
			}
		});

		// Box holding the processor configuration buttons.
		final HBox configButtonBox = new HBox(5);
		processorBox.getChildren().add(configButtonBox);

		GUISupport.addButtonWithMouseClickedHandler(configButtonBox, "Remove Processor", false,
			"/images/icons/Remove.png", new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent event) {
					parentChain.removeProcessor(Processor.this);
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(configButtonBox, "Save Processor", false,
			"/images/icons/Export To Document.png", new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent event) {
					// TODO: SSHS export.
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(configButtonBox, "Configure Processor", false,
			"/images/icons/Gear.png", new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent event) {
					GUISupport.showDialog("Processor Configuration", getConfigGUI(), rootConfigTasksDialogRefresh,
						rootConfigTasksDialogOK, rootTasksUIRefresh);
				}
			});

		// Box holding information about the <Type, Source> combinations that
		// are currently being processed inside this processor.
		final VBox selectedInputStreamsBox = new VBox(5);
		processorBox.getChildren().add(selectedInputStreamsBox);

		// Update box with the new selected input streams after user clicks OK.
		rootTasksUIRefresh.add(new Runnable() {
			@Override
			public void run() {
				selectedInputStreamsBox.getChildren().clear();

				if (!selectedInputStreams.isEmpty()) {
					GUISupport.addLabel(selectedInputStreamsBox, "Currently processing:", null, null, null);

					for (final Stream selInStream : selectedInputStreams) {
						GUISupport.addLabel(selectedInputStreamsBox, String.format("< %s, %d >", selInStream.getFirst()
							.getSimpleName(), selInStream.getSecond()), null, null, null);
					}
				}
			}
		});

		// Box with content from sub-classes (end of processor info box).
		processorBox.getChildren().add(rootLayoutChildren);

		// Box holding information about the types in transit.
		final VBox typesBox = new VBox(5);
		rootLayout.getChildren().add(typesBox);

		// Update box with the new output streams after user clicks OK.
		rootTasksUIRefresh.add(new Runnable() {
			@Override
			public void run() {
				typesBox.getChildren().clear();

				if (!outputStreams.isEmpty()) {
					GUISupport.addArrow(typesBox, 150, 2, 10, 6);

					for (final Stream outStream : outputStreams) {
						GUISupport.addLabel(typesBox,
							String.format("< %s, %d >", outStream.getFirst().getSimpleName(), outStream.getSecond()),
							null, null, null);
					}
				}

				// Visibility of the TypesBox depends on next processor.
				if (nextProcessor == null) {
					typesBox.setManaged(false);
					typesBox.setVisible(false);
				}
				else {
					typesBox.setManaged(true);
					typesBox.setVisible(true);
				}
			}
		});
	}

	/**
	 * Get the graphical layout for the configuration screen corresponding to
	 * this class, so that it can be
	 * displayed somewhere by adding it to a Scene.
	 *
	 * @return GUI reference to display.
	 */
	synchronized public final Pane getConfigGUI() {
		if (rootConfigLayout == null) {
			rootConfigLayout = new VBox(10);
			rootConfigLayoutChildren = new VBox(5);

			buildConfigGUI();
		}

		return rootConfigLayout;
	}

	/**
	 * Create the base GUI elements for the configuration screen and add them to
	 * the rootConfigLayout.
	 */
	protected void buildConfigGUI() {
		// List view of all possible input streams, to select on which to work.
		final ListView<Stream> streamsView = new ListView<>();

		// Enable multiple selections and fix the height to something sensible.
		streamsView.getSelectionModel().setSelectionMode(SelectionMode.MULTIPLE);
		streamsView.setPrefHeight(140);

		if (!(this instanceof InputProcessor)) {
			GUISupport.addLabelWithControlsVertical(rootConfigLayout, "Select streams to process:",
				"Select the <Type, Source> combinations (streams) on which to operate.", streamsView);
		}

		// Update input streams view with the latest content.
		rootConfigTasksDialogRefresh.add(new Runnable() {
			@Override
			public void run() {
				CollectionsUpdate.replaceNonDestructive(streamsView.getItems(), inputStreams);
				streamsView.getItems().sort(new StreamComparator());
			}
		});

		rootConfigTasksDialogOK.add(new Runnable() {
			@Override
			public void run() {
				if (CollectionsUpdate.replaceNonDestructive(selectedInputStreams, streamsView.getSelectionModel()
					.getSelectedItems())) {
					// Changing anything about the selected input streams is
					// considered a structural change, as it requires updating
					// the chain's stream information.
					parentChain.newStructuralChangesToCommit();
				}
			}
		});

		// Box with content from sub-classes (end of config layout box).
		rootConfigLayout.getChildren().add(rootConfigLayoutChildren);
	}

	@Override
	public String toString() {
		return String.format("%s - ID %d", processorName, processorId);
	}
}
