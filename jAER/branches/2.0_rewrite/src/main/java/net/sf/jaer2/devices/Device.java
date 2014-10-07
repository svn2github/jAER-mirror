package net.sf.jaer2.devices;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

import javafx.scene.control.ScrollPane;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.stage.Screen;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.eventio.translators.Translator;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHS;
import net.sf.jaer2.util.SSHSNode;

public abstract class Device {
	private final Map<String, Component> componentsMap = new LinkedHashMap<>();

	private final String name;
	private final String description;
	private final SSHSNode configNode;

	private VBox rootConfigLayout;

	public Device(final String deviceName, final String deviceDescription) {
		name = deviceName;
		description = deviceDescription;
		configNode = SSHS.GLOBAL.getNode(String.format("/devices/%s/", deviceName));
	}

	public String getName() {
		return name;
	}

	public String getDescription() {
		return description;
	}

	public SSHSNode getConfigNode() {
		return configNode;
	}

	protected void addComponent(final Component c) {
		componentsMap.put(c.getName(), c);
		c.setDevice(this);
	}

	public Collection<Component> getComponents() {
		return Collections.unmodifiableCollection(componentsMap.values());
	}

	public <E extends Component> Collection<E> getComponents(final Class<E> type) {
		final Collection<E> components = new ArrayList<>();

		for (final Component c : componentsMap.values()) {
			if (type.isAssignableFrom(c.getClass())) {
				components.add(type.cast(c));
			}
		}

		return Collections.unmodifiableCollection(components);
	}

	public Component getComponent(final String componentName) {
		return componentsMap.get(componentName);
	}

	public <E extends Component> E getComponent(final Class<E> type, final String componentName) {
		final Component c = componentsMap.get(componentName);

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
		GUISupport.addLabel(rootConfigLayout, getName(), getDescription(), null, null);

		final TabPane tabLayout = new TabPane();

		for (final Component c : componentsMap.values()) {
			final ScrollPane p = new ScrollPane(c.getConfigGUI());

			p.setFitToWidth(true);
			p.setPrefHeight(Screen.getPrimary().getVisualBounds().getHeight());
			// TODO: is there a better way to maximize the ScrollPane content?

			final Tab t = new Tab(c.getName());

			t.setContent(p);
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
		return getName();
	}
}
