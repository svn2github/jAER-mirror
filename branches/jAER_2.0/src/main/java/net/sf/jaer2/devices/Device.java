package net.sf.jaer2.devices;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.SortedMap;
import java.util.TreeMap;

import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.eventio.translators.Translator;
import net.sf.jaer2.util.GUISupport;

public abstract class Device {
	private final SortedMap<String, Component> nameComponentMap = new TreeMap<>();

	protected final String name;
	protected final String description;

	private VBox rootConfigLayout;

	public Device(final String deviceName, final String deviceDescription) {
		name = deviceName;
		description = deviceDescription;
	}

	public String getName() {
		return name;
	}

	public String getDescription() {
		return description;
	}

	protected void addComponent(final Component c) {
		nameComponentMap.put(c.getName(), c);
	}

	public Collection<Component> getComponents() {
		return Collections.unmodifiableCollection(nameComponentMap.values());
	}

	public <E extends Component> Collection<E> getComponents(final Class<E> type) {
		final Collection<E> components = new ArrayList<>();

		for (final Component c : nameComponentMap.values()) {
			if (type.isAssignableFrom(c.getClass())) {
				components.add(type.cast(c));
			}
		}

		return Collections.unmodifiableCollection(components);
	}

	public Component getComponent(final String componentName) {
		return nameComponentMap.get(componentName);
	}

	public <E extends Component> E getComponent(final Class<E> type, final String componentName) {
		final Component c = nameComponentMap.get(componentName);

		// Found a component with specified name, now check the type.
		if ((c != null) && type.isAssignableFrom(c.getClass())) {
			return type.cast(c);
		}

		return null;
	}

	synchronized public Pane getConfigGUI() {
		if (rootConfigLayout == null) {
			rootConfigLayout = new VBox(10);

			buildConfigGUI();
		}

		return rootConfigLayout;
	}

	private void buildConfigGUI() {
		// Add device general data, under that, one Tab for each component.
		GUISupport.addLabel(rootConfigLayout, name, description, null, null);

		final TabPane tabLayout = new TabPane();

		for (final Component c : nameComponentMap.values()) {
			final Tab t = new Tab(c.getName());

			t.setContent(c.getConfigGUI());
			t.setClosable(false);

			tabLayout.getTabs().add(t);
		}

		rootConfigLayout.getChildren().add(tabLayout);
	}

	public abstract Class<? extends Translator> getPreferredTranslator();

	public abstract void open();

	public abstract void close();

	@Override
	public String toString() {
		return name;
	}
}
