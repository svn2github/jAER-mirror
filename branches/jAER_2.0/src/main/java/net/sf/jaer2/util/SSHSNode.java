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
import java.util.NoSuchElementException;
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

import net.sf.jaer2.util.SSHSListener.AttributeEvents;
import net.sf.jaer2.util.SSHSListener.NodeEvents;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

public final class SSHSNode {
	private final String name;
	private final String path;
	private final ConcurrentMap<String, SSHSNode> children;
	private final TypedMap<String> attributes;
	private final List<SSHSListener> listeners;
	private final ReadWriteLock lock;

	SSHSNode(final String nodeName, final SSHSNode parent) {
		name = nodeName;
		children = new ConcurrentHashMap<>();
		attributes = new TypedMap<>();
		listeners = new ArrayList<>();
		lock = new ReentrantReadWriteLock();

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
			lock.readLock().lock();
			for (final SSHSListener listener : listeners) {
				listener.nodeChanged(this, NodeEvents.CHILD_NODE_ADDED, child);
			}
			lock.readLock().unlock();

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

	public void addListener(final SSHSListener l) {
		lock.writeLock().lock();
		listeners.add(l);
		lock.writeLock().unlock();
	}

	public void removeListener(final SSHSListener l) {
		lock.writeLock().lock();
		listeners.remove(l);
		lock.writeLock().unlock();
	}

	void transactionLock() {
		lock.writeLock().lock();
	}

	void transactionUnlock() {
		lock.writeLock().unlock();
	}

	public boolean exists(final String key, final Class<?> type) {
		lock.readLock().lock();
		final boolean returnValue = attributes.contains(key, type);
		lock.readLock().unlock();

		return returnValue;
	}

	private <V> void putAttribute(final String key, final Class<V> type, final V value) {
		lock.writeLock().lock();
		final V returnValue = attributes.put(key, type, value);
		lock.writeLock().unlock();

		// Listener support.
		lock.readLock().lock();
		for (final SSHSListener listener : listeners) {
			listener.attributeChanged(this, (returnValue == null) ? (AttributeEvents.ATTRIBUTE_ADDED)
				: (AttributeEvents.ATTRIBUDE_MODIFIED), key, type, value);
		}
		lock.readLock().unlock();
	}

	private <V> V getAttribute(final String key, final Class<V> type) {
		lock.readLock().lock();
		final V returnValue = attributes.get(key, type);
		lock.readLock().unlock();

		// Verify that we're getting values from a valid attribute.
		// Valid means it already exists and has a well-defined default.
		if (returnValue == null) {
			throw new NoSuchElementException("Attribute not present, please initialize it first with attributePut().");
		}

		return returnValue;
	}

	private List<Entry<PairRO<String, ?>, Object>> getAttributes() {
		lock.readLock().lock();
		final List<Entry<PairRO<String, ?>, Object>> returnValue = new ArrayList<>(attributes.entrySet());
		lock.readLock().unlock();

		Collections.sort(returnValue, new Comparator<Entry<PairRO<String, ?>, Object>>() {
			@Override
			public int compare(final Entry<PairRO<String, ?>, Object> o1, final Entry<PairRO<String, ?>, Object> o2) {
				return o1.getKey().getFirst().compareTo(o2.getKey().getFirst());
			}
		});

		return returnValue;
	}

	public void putBool(final String key, final boolean value) {
		putAttribute(key, Boolean.class, value);
	}

	public boolean getBool(final String key) {
		return getAttribute(key, Boolean.class);
	}

	public void putByte(final String key, final byte value) {
		putAttribute(key, Byte.class, value);
	}

	public byte getByte(final String key) {
		return getAttribute(key, Byte.class);
	}

	public void putShort(final String key, final short value) {
		putAttribute(key, Short.class, value);
	}

	public short getShort(final String key) {
		return getAttribute(key, Short.class);
	}

	public void putInt(final String key, final int value) {
		putAttribute(key, Integer.class, value);
	}

	public int getInt(final String key) {
		return getAttribute(key, Integer.class);
	}

	public void putLong(final String key, final long value) {
		putAttribute(key, Long.class, value);
	}

	public long getLong(final String key) {
		return getAttribute(key, Long.class);
	}

	public void putFloat(final String key, final float value) {
		putAttribute(key, Float.class, value);
	}

	public float getFloat(final String key) {
		return getAttribute(key, Float.class);
	}

	public void putDouble(final String key, final double value) {
		putAttribute(key, Double.class, value);
	}

	public double getDouble(final String key) {
		return getAttribute(key, Double.class);
	}

	public void putString(final String key, final String value) {
		putAttribute(key, String.class, value);
	}

	public String getString(final String key) {
		return getAttribute(key, String.class);
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
		for (final Entry<PairRO<String, ?>, Object> entry : getAttributes()) {
			final Element attr = dom.createElement("attr");
			node.appendChild(attr);

			attr.setAttribute("key", entry.getKey().getFirst());
			attr.setAttribute("type", SSHSNode.typeToXMLNameMap.get(entry.getKey().getSecond()));
			attr.setTextContent(entry.getValue().toString());
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

	private void fromXML(final InputStream is, final boolean recursive, final boolean strict) throws SAXException,
		IOException, XMLParseException {
		try {
			final Document dom = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(is);

			final Element root = dom.getDocumentElement();

			// Check name and version for compliance.
			if ((root.getNodeName().compareTo("sshs") != 0) || (root.getAttribute("version").compareTo("1.0") != 0)) {
				throw new XMLParseException("Invalid SSHS v1.0 XML content.");
			}

			final Element rootNode = SSHSNode.filterChildNodes(root, "node").get(0);

			// Strict mode: check if names match.
			if (strict) {
				if (!rootNode.hasAttribute("name") || (rootNode.getAttribute("name").compareTo(getName()) != 0)) {
					throw new XMLParseException("Names don't match (required in 'strict' mode).");
				}
			}

			consumeXML(rootNode, recursive);
		}
		catch (final ParserConfigurationException e) {
			// Ignore for now.
		}
	}

	private void consumeXML(final Element content, final boolean recursive) {
		for (final Element attr : SSHSNode.filterChildNodes(content, "attr")) {
			// Check that the proper attributes exist.
			if (!attr.hasAttribute("key") || !attr.hasAttribute("type")) {
				continue;
			}

			// Get the needed values.
			final String key = attr.getAttribute("key");
			final String type = attr.getAttribute("type");
			final String value = attr.getTextContent();

			xmlToNodeConverter(key, type, value);
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

	private static List<Element> filterChildNodes(final Element node, final String childName) {
		final NodeList nodes = node.getChildNodes();
		final List<Element> results = new ArrayList<>();

		for (int i = 0; i < nodes.getLength(); i++) {
			if (nodes.item(i).getNodeName().compareTo(childName) == 0) {
				results.add((Element) nodes.item(i));
			}
		}

		return results;
	}

	private static final Map<Class<?>, String> typeToXMLNameMap = new HashMap<>();
	static {
		SSHSNode.typeToXMLNameMap.put(Boolean.class, "bool");
		SSHSNode.typeToXMLNameMap.put(Byte.class, "byte");
		SSHSNode.typeToXMLNameMap.put(Short.class, "short");
		SSHSNode.typeToXMLNameMap.put(Integer.class, "int");
		SSHSNode.typeToXMLNameMap.put(Long.class, "long");
		SSHSNode.typeToXMLNameMap.put(Float.class, "float");
		SSHSNode.typeToXMLNameMap.put(Double.class, "double");
		SSHSNode.typeToXMLNameMap.put(String.class, "string");
	}

	private void xmlToNodeConverter(final String key, final String type, final String value) {
		// Parse the values according to type and put them in the node.
		switch (type) {
			case "bool":
				putBool(key, Boolean.parseBoolean(value));
				break;

			case "byte":
				putByte(key, Byte.parseByte(value));
				break;

			case "short":
				putShort(key, Short.parseShort(value));
				break;

			case "int":
				putInt(key, Integer.parseInt(value));
				break;

			case "long":
				putLong(key, Long.parseLong(value));
				break;

			case "float":
				putFloat(key, Float.parseFloat(value));
				break;

			case "double":
				putDouble(key, Double.parseDouble(value));
				break;

			case "string":
				putString(key, value);
				break;

			default:
				break;
		}
	}
}
