package net.sf.jaer2.devices;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.eventio.translators.Translator;

public abstract class Device {
	private Map<String, Component> nameComponentMap = new HashMap<>();

	protected final String name;
	protected final String description;

	public Device(String deviceName, String deviceDescription) {
		name = deviceName;
		description = deviceDescription;
	}

	public String getName() {
		return name;
	}

	public String getDescription() {
		return description;
	}

	public void addComponent(Component c) {
		nameComponentMap.put(c.getName(), c);
	}

	public Collection<Component> getComponents() {
		return Collections.unmodifiableCollection(nameComponentMap.values());
	}

	public <E extends Component> Collection<E> getComponents(Class<E> type) {
		Collection<E> components = new ArrayList<>();

		for (Component c : nameComponentMap.values()) {
			if (type.isAssignableFrom(c.getClass())) {
				components.add(type.cast(c));
			}
		}

		return Collections.unmodifiableCollection(components);
	}

	public Component getComponent(String componentName) {
		return nameComponentMap.get(componentName);
	}

	public <E extends Component> E getComponent(Class<E> type, String componentName) {
		Component c = nameComponentMap.get(componentName);

		// Found a component with specified name, now check the type.
		if ((c != null) && type.isAssignableFrom(c.getClass())) {
			return type.cast(c);
		}

		return null;
	}

	public abstract Class<? extends Translator> getPreferredTranslator();
}
