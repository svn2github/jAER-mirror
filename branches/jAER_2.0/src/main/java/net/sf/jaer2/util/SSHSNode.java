package net.sf.jaer2.util;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import javax.management.modelmbean.XMLParseException;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import net.sf.jaer2.util.SSHSNode.SSHSNodeListener.NodeEvents;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

public final class SSHSNode {
	public interface SSHSNodeListener {
		public static enum NodeEvents {
			ATTRIBUTE_ADDED,
			ATTRIBUTE_MODIFIED,
			CHILD_NODE_ADDED;
		}

		public void changed(SSHSNode node, Object userData, NodeEvents event, String key);
	}

	private final String name;
	private final String path;
	private final ConcurrentMap<String, SSHSNode> children;
	private final Map<PairRO<String, Class<?>>, SSHSAttribute<?>> attributes;
	private final List<PairRO<SSHSNodeListener, Object>> nodeListeners;
	private final ReadWriteLock nodeLock;

	SSHSNode(final String nodeName, final SSHSNode parent) {
		name = nodeName;
		children = new ConcurrentHashMap<>();
		attributes = new HashMap<>();
		nodeListeners = new ArrayList<>();
		nodeLock = new ReentrantReadWriteLock();

		// Path is based on parent.
		if (parent != null) {
			path = String.format("%s%s/", parent.getPath(), nodeName);
		}
		else {
			// Or the root has an empty path.
			path = "/";
		}
	}

	public String getName() {
		return name;
	}

	public String getPath() {
		return path;
	}

	SSHSNode addChild(final String childName) {
		// Create new child node with appropriate name and parent.
		final SSHSNode child = new SSHSNode(childName, this);

		// Atomic putIfAbsent: returns null if nothing was there before and the
		// node is the new one, or it returns the old node if already present.
		final SSHSNode returnValue = children.putIfAbsent(childName, child);

		// If null was returned, then nothing was in the map beforehand, and
		// thus the new node 'child' is the node that's now in the map.
		if (returnValue == null) {
			// Listener support (only on new addition!).
			nodeLock.readLock().lock();
			for (final PairRO<SSHSNodeListener, Object> listener : nodeListeners) {
				listener.getFirst().changed(this, listener.getSecond(), NodeEvents.CHILD_NODE_ADDED, childName);
			}
			nodeLock.readLock().unlock();

			return child;
		}

		return returnValue;
	}

	SSHSNode getChild(final String childName) {
		// Either null or an always valid value.
		return children.get(childName);
	}

	private List<SSHSNode> getChildren() {
		final List<SSHSNode> returnValue = new ArrayList<>(children.values());

		Collections.sort(returnValue, new Comparator<SSHSNode>() {
			@Override
			public int compare(final SSHSNode o1, final SSHSNode o2) {
				return o1.getName().compareTo(o2.getName());
			}
		});

		return returnValue;
	}

	public void addNodeListener(final SSHSNodeListener l, final Object userData) {
		nodeLock.writeLock().lock();
		// Avoid duplicates by disallowing the addition of them.
		if (!nodeListeners.contains(PairRO.of(l, userData))) {
			nodeListeners.add(PairRO.of(l, userData));
		}
		nodeLock.writeLock().unlock();
	}

	public void removeNodeListener(final SSHSNodeListener l, final Object userData) {
		nodeLock.writeLock().lock();
		nodeListeners.remove(PairRO.of(l, userData));
		nodeLock.writeLock().unlock();
	}

	public boolean attributeExists(final String key, final Class<?> type) {
		nodeLock.readLock().lock();
		final boolean returnValue = attributes.containsKey(PairRO.of(key, type));
		nodeLock.readLock().unlock();

		return returnValue;
	}

	public <V> SSHSAttribute<V> getAttribute(final String key, final Class<V> type) {
		nodeLock.readLock().lock();
		@SuppressWarnings("unchecked")
		SSHSAttribute<V> returnValue = (SSHSAttribute<V>) attributes.get(PairRO.of(key, type));
		nodeLock.readLock().unlock();

		// Verify that the attribute exists, if not, take the slow path and
		// create it.
		if (returnValue == null) {
			returnValue = initAttribute(key, type);

			nodeLock.readLock().lock();
			for (final PairRO<SSHSNodeListener, Object> listener : nodeListeners) {
				listener.getFirst().changed(this, listener.getSecond(), NodeEvents.ATTRIBUTE_ADDED, key);
			}
			nodeLock.readLock().unlock();
		}

		return returnValue;
	}

	void attributeModifiedNotification(final String key) {
		nodeLock.readLock().lock();
		for (final PairRO<SSHSNodeListener, Object> listener : nodeListeners) {
			listener.getFirst().changed(this, listener.getSecond(), NodeEvents.ATTRIBUTE_MODIFIED, key);
		}
		nodeLock.readLock().unlock();
	}

	@SuppressWarnings("unchecked")
	private <V> SSHSAttribute<V> initAttribute(final String key, final Class<V> type) {
		nodeLock.writeLock().lock();

		SSHSAttribute<V> returnValue = (SSHSAttribute<V>) attributes.get(PairRO.of(key, type));

		if (returnValue == null) {
			returnValue = new SSHSAttribute<>(key, this);
			attributes.put(PairRO.of(key, type), returnValue);
		}

		nodeLock.writeLock().unlock();

		return returnValue;
	}

	private List<Entry<PairRO<String, Class<?>>, SSHSAttribute<?>>> getAttributes() {
		nodeLock.readLock().lock();
		final List<Entry<PairRO<String, Class<?>>, SSHSAttribute<?>>> returnValue = new ArrayList<>(
			attributes.entrySet());
		nodeLock.readLock().unlock();

		Collections.sort(returnValue, new Comparator<Entry<PairRO<String, Class<?>>, SSHSAttribute<?>>>() {
			@Override
			public int compare(final Entry<PairRO<String, Class<?>>, SSHSAttribute<?>> o1,
				final Entry<PairRO<String, Class<?>>, SSHSAttribute<?>> o2) {
				return o1.getKey().getFirst().compareTo(o2.getKey().getFirst());
			}
		});

		return returnValue;
	}

	public void exportNodeToXML(final OutputStream os) {
		toXML(os, false);
	}

	public void exportSubTreeToXML(final OutputStream os) {
		toXML(os, true);
	}

	private void toXML(final OutputStream os, final boolean recursive) {
		try {
			final Document dom = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument();

			final Element root = dom.createElement("sshs");
			dom.appendChild(root);
			root.setAttribute("version", "1.0");
			root.appendChild(generateXML(dom, recursive));

			final Transformer tr = TransformerFactory.newInstance().newTransformer();
			tr.setOutputProperty(OutputKeys.METHOD, "xml");
			tr.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
			tr.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
			tr.setOutputProperty(OutputKeys.INDENT, "yes");
			tr.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");

			tr.transform(new DOMSource(dom), new StreamResult(os));
		}
		catch (ParserConfigurationException | TransformerFactoryConfigurationError | TransformerException e) {
			// Ignore for now.
		}
	}

	private Element generateXML(final Document dom, final boolean recursive) {
		final Element node = dom.createElement("node");

		// First this node's name and full path.
		node.setAttribute("name", getName());
		node.setAttribute("path", getPath());

		// Then it's attributes (key:value pairs).
		for (final Entry<PairRO<String, Class<?>>, SSHSAttribute<?>> entry : getAttributes()) {
			final Element attr = dom.createElement("attr");
			node.appendChild(attr);

			attr.setAttribute("key", entry.getKey().getFirst());
			attr.setAttribute("type", SSHSHelper.typeToStringConverter(entry.getKey().getSecond()));
			attr.setTextContent(SSHSHelper.valueToStringConverter(entry.getKey().getSecond(), entry.getValue()
				.getValue()));
		}

		// And lastly recurse down to the children.
		if (recursive) {
			for (final SSHSNode childNode : getChildren()) {
				final Element childXML = childNode.generateXML(dom, recursive);

				if (childXML.hasChildNodes()) {
					node.appendChild(childXML);
				}
			}
		}

		return node;
	}

	public void importNodeFromXML(final InputStream is, final boolean strict) throws SAXException, IOException,
		XMLParseException {
		fromXML(is, false, strict);
	}

	public void importSubTreeFromXML(final InputStream is, final boolean strict) throws SAXException, IOException,
		XMLParseException {
		fromXML(is, true, strict);
	}

	private static List<Element> filterChildNodes(final Element node, final String childName) {
		final NodeList nodes = node.getChildNodes();
		final List<Element> results = new ArrayList<>();

		for (int i = 0; i < nodes.getLength(); i++) {
			if (nodes.item(i).getNodeName().equals(childName)) {
				results.add((Element) nodes.item(i));
			}
		}

		return results;
	}

	private void fromXML(final InputStream is, final boolean recursive, final boolean strict) throws SAXException,
		IOException, XMLParseException {
		try {
			final Document dom = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(is);

			final Element root = dom.getDocumentElement();

			// Check name and version for compliance.
			if (!root.getNodeName().equals("sshs") || !root.getAttribute("version").equals("1.0")) {
				throw new XMLParseException("Invalid SSHS v1.0 XML content.");
			}

			final List<Element> rootChildren = SSHSNode.filterChildNodes(root, "node");

			if (rootChildren.size() != 1) {
				throw new XMLParseException("Multiple or no root child nodes present.");
			}

			final Element rootNode = rootChildren.get(0);

			// Strict mode: check if names match.
			if (strict) {
				if (!rootNode.hasAttribute("name") || !rootNode.getAttribute("name").equals(getName())) {
					throw new XMLParseException("Names don't match (required in 'strict' mode).");
				}
			}

			consumeXML(rootNode, recursive);
		}
		catch (final ParserConfigurationException e) {
			// Ignore for now.
		}
	}

	private void consumeXML(final Element content, final boolean recursive) throws XMLParseException {
		for (final Element attr : SSHSNode.filterChildNodes(content, "attr")) {
			// Check that the proper attributes exist.
			if (!attr.hasAttribute("key") || !attr.hasAttribute("type")) {
				continue;
			}

			// Get the needed values.
			final String key = attr.getAttribute("key");
			final String type = attr.getAttribute("type");
			final String value = attr.getTextContent();

			if (!stringToNodeConverter(key, type, value)) {
				throw new XMLParseException(String.format("Failed to convert attribute %s of type %s with value %s.",
					key, type, value));
			}
		}

		if (recursive) {
			for (final Element child : SSHSNode.filterChildNodes(content, "node")) {
				// Check that the proper attributes exist.
				if (!child.hasAttribute("name")) {
					continue;
				}

				// Get the child node.
				final String childName = child.getAttribute("name");
				SSHSNode childNode = getChild(childName);

				// If not existing, try to create.
				if (childNode == null) {
					childNode = addChild(childName);
				}

				// And call recursively.
				childNode.consumeXML(child, recursive);
			}
		}
	}

	public boolean stringToNodeConverter(final String key, final String typeStr, final String valueStr) {
		// Parse the values according to type and put them in the node.
		final Class<?> type = SSHSHelper.stringToTypeConverter(typeStr);

		if (type == Boolean.class) {
			getAttribute(key, Boolean.class).setValue(SSHSHelper.stringToValueConverter(Boolean.class, valueStr));
		}
		else if (type == Byte.class) {
			getAttribute(key, Byte.class).setValue(SSHSHelper.stringToValueConverter(Byte.class, valueStr));
		}
		else if (type == Short.class) {
			getAttribute(key, Short.class).setValue(SSHSHelper.stringToValueConverter(Short.class, valueStr));
		}
		else if (type == Integer.class) {
			getAttribute(key, Integer.class).setValue(SSHSHelper.stringToValueConverter(Integer.class, valueStr));
		}
		else if (type == Long.class) {
			getAttribute(key, Long.class).setValue(SSHSHelper.stringToValueConverter(Long.class, valueStr));
		}
		else if (type == Float.class) {
			getAttribute(key, Float.class).setValue(SSHSHelper.stringToValueConverter(Float.class, valueStr));
		}
		else if (type == Double.class) {
			getAttribute(key, Double.class).setValue(SSHSHelper.stringToValueConverter(Double.class, valueStr));
		}
		else if (type == String.class) {
			getAttribute(key, String.class).setValue(SSHSHelper.stringToValueConverter(String.class, valueStr));
		}
		else {
			return false; // UNKNOWN TYPE.
		}

		return true;
	}

	public List<String> getChildNames() {
		final List<String> childNames = new ArrayList<>(children.keySet());

		return (childNames);
	}

	public List<String> getAttributeKeys() {
		final List<String> attributeKeys = new ArrayList<>(attributes.size());

		for (final PairRO<String, ?> attribute : attributes.keySet()) {
			attributeKeys.add(attribute.getFirst());
		}

		return (attributeKeys);
	}

	public List<Class<?>> getAttributeTypes(final String key) {
		final List<Class<?>> attributeTypes = new ArrayList<>();

		for (final PairRO<String, ?> attribute : attributes.keySet()) {
			if (attribute.getFirst().equals(key)) {
				attributeTypes.add((Class<?>) attribute.getSecond());
			}
		}

		return (attributeTypes);
	}
}
