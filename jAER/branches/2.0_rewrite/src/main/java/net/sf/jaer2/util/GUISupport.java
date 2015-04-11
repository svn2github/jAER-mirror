package net.sf.jaer2.util;

import java.io.File;
import java.util.Arrays;
import java.util.Collection;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;

import javafx.application.Platform;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.concurrent.Worker;
import javafx.event.EventHandler;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.Button;
import javafx.scene.control.ButtonType;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Control;
import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import javafx.scene.control.TextField;
import javafx.scene.control.Tooltip;
import javafx.scene.image.ImageView;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.input.MouseEvent;
import javafx.scene.input.ScrollEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.shape.Line;
import javafx.scene.shape.Polygon;
import javafx.scene.text.Font;
import javafx.stage.FileChooser;
import javafx.stage.FileChooser.ExtensionFilter;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.SSHSAttribute.SSHSAttrListener;

import org.controlsfx.dialog.ExceptionDialog;
import org.controlsfx.dialog.ProgressDialog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class GUISupport {
	/** Local logger for log messages. */
	private static final Logger logger = LoggerFactory.getLogger(GUISupport.class);

	public static Button addButton(final Pane parentPane, final String text, final boolean displayText,
		final String imagePath) {
		final Button button = new Button();

		if (displayText) {
			button.setText(text);
		}

		button.setTooltip(new Tooltip(text));

		if (imagePath != null) {
			button.setGraphic(new ImageView(imagePath));
		}

		if (parentPane != null) {
			parentPane.getChildren().add(button);
		}

		return button;
	}

	public static Button addButtonWithMouseClickedHandler(final Pane parentPane, final String text,
		final boolean displayText, final String imagePath, final EventHandler<? super MouseEvent> handler) {
		final Button button = GUISupport.addButton(parentPane, text, displayText, imagePath);

		if (handler != null) {
			button.setOnMouseClicked(handler);
		}

		return button;
	}

	public static <T> ComboBox<T> addComboBox(final Pane parentPane, final Collection<T> values, final int defaultValue) {
		if ((defaultValue < -1) || (defaultValue >= values.size())) {
			throw new IndexOutOfBoundsException();
		}

		final ComboBox<T> comboBox = new ComboBox<>();

		comboBox.getItems().addAll(values);

		if (defaultValue != -1) {
			comboBox.getSelectionModel().select(defaultValue);
		}

		if (parentPane != null) {
			parentPane.getChildren().add(comboBox);
		}

		return comboBox;
	}

	public static CheckBox addCheckBox(final Pane parentPane, final String text, final boolean selected) {
		final CheckBox checkBox = new CheckBox(text);

		checkBox.setTooltip(new Tooltip(text));

		checkBox.setSelected(selected);

		if (parentPane != null) {
			parentPane.getChildren().add(checkBox);
		}

		return checkBox;
	}

	public static Label addLabel(final Pane parentPane, final String text, final String tooltip, final Color color,
		final Font font) {
		final Label label = new Label(text);

		label.setTooltip(new Tooltip((tooltip == null) ? (text) : (tooltip)));

		if (color != null) {
			label.setTextFill(color);
		}

		if (font != null) {
			label.setFont(font);
		}

		if (parentPane != null) {
			parentPane.getChildren().add(label);
		}

		return label;
	}

	public static HBox addLabelWithControlsHorizontal(final Pane parentPane, final String text, final String tooltip,
		final Control... controls) {
		final HBox hbox = new HBox(5);

		// Create and add both Label and Control.
		final Label label = GUISupport.addLabel(hbox, text, tooltip, null, null);

		for (final Control control : controls) {
			hbox.getChildren().add(control);

			// Ensure the Control has the same Tooltip as the Label.
			control.setTooltip(label.getTooltip());
		}

		if (parentPane != null) {
			parentPane.getChildren().add(hbox);
		}

		return hbox;
	}

	public static VBox addLabelWithControlsVertical(final Pane parentPane, final String text, final String tooltip,
		final Control... controls) {
		final VBox vbox = new VBox(5);

		// Create and add both Label and Control.
		final Label label = GUISupport.addLabel(vbox, text, tooltip, null, null);

		for (final Control control : controls) {
			vbox.getChildren().add(control);

			// Ensure the Control has the same Tooltip as the Label.
			control.setTooltip(label.getTooltip());
		}

		if (parentPane != null) {
			parentPane.getChildren().add(vbox);
		}

		return vbox;
	}

	public static TextField addTextField(final Pane parentPane, final String defaultText, final Font font) {
		final TextField txt = new TextField(defaultText);

		if (font != null) {
			txt.setFont(font);
		}

		txt.setOnMouseEntered(new EventHandler<MouseEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
				txt.requestFocus();
			}
		});

		if (parentPane != null) {
			parentPane.getChildren().add(txt);
		}

		return txt;
	}

	private static String formatIntegerStringForTextfield(final int value, final int displayLength,
		final NumberFormat fmt, final EnumSet<NumberOptions> opts) {
		final String str = Numbers.integerToString(value, fmt, opts);

		if (opts.contains(NumberOptions.LEFT_PADDING)) {
			return str.substring(Integer.SIZE - displayLength, Integer.SIZE);
		}

		return str;
	}

	public static TextField addTextNumberField(final Pane parentPane, final SSHSAttribute<Integer> backendValue,
		final int displayLength, final int min, final int max, final NumberFormat fmt,
		final EnumSet<NumberOptions> opts, final Font font) {
		final TextField txt = new TextField(GUISupport.formatIntegerStringForTextfield(backendValue.getValue(),
			displayLength, fmt, opts));

		if (font != null) {
			txt.setFont(font);
		}

		txt.setPrefColumnCount(displayLength);

		txt.textProperty().addListener(new ChangeListener<String>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends String> val, final String oldVal, final String newVal) {
				backendValue.setValue(Numbers.stringToInteger(newVal, fmt, opts));
			}
		});

		backendValue.addListener(new SSHSAttrListener<Integer>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(SSHSNode node, Object userData,
				net.sf.jaer2.util.SSHSAttribute.SSHSAttrListener.AttributeEvents event, Integer oldValue,
				Integer newValue) {
				txt.setText(GUISupport.formatIntegerStringForTextfield(newValue, displayLength, fmt, opts));
			}
		}, null);

		txt.setOnMouseEntered(new EventHandler<MouseEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
				txt.requestFocus();
			}
		});

		txt.setOnScroll(new EventHandler<ScrollEvent>() {
			@Override
			public void handle(final ScrollEvent scroll) {
				int i = backendValue.getValue();

				if (scroll.getDeltaY() > 0) {
					i++;
				}

				if (scroll.getDeltaY() < 0) {
					i--;
				}

				if ((i >= min) && (i <= max)) {
					backendValue.setValue(i);
				}

				scroll.consume();
			}
		});

		if (parentPane != null) {
			parentPane.getChildren().add(txt);
		}

		return txt;
	}

	private static String formatLongStringForTextfield(final long value, final int displayLength,
		final NumberFormat fmt, final EnumSet<NumberOptions> opts) {
		final String str = Numbers.longToString(value, fmt, opts);

		if (opts.contains(NumberOptions.LEFT_PADDING)) {
			return str.substring(Long.SIZE - displayLength, Long.SIZE);
		}

		return str;
	}

	public static TextField addTextNumberField(final Pane parentPane, final SSHSAttribute<Long> backendValue,
		final int displayLength, final long min, final long max, final NumberFormat fmt,
		final EnumSet<NumberOptions> opts, final Font font) {
		final TextField txt = new TextField(GUISupport.formatLongStringForTextfield(backendValue.getValue(),
			displayLength, fmt, opts));

		if (font != null) {
			txt.setFont(font);
		}

		txt.setPrefColumnCount(displayLength);

		txt.textProperty().addListener(new ChangeListener<String>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends String> val, final String oldVal, final String newVal) {
				backendValue.setValue(Numbers.stringToLong(newVal, fmt, opts));
			}
		});

		backendValue.addListener(new SSHSAttrListener<Long>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(SSHSNode node, Object userData,
				net.sf.jaer2.util.SSHSAttribute.SSHSAttrListener.AttributeEvents event, Long oldValue, Long newValue) {
				txt.setText(GUISupport.formatLongStringForTextfield(newValue, displayLength, fmt, opts));
			}
		}, null);

		txt.setOnMouseEntered(new EventHandler<MouseEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
				txt.requestFocus();
			}
		});

		txt.setOnScroll(new EventHandler<ScrollEvent>() {
			@Override
			public void handle(final ScrollEvent scroll) {
				long i = backendValue.getValue();

				if (scroll.getDeltaY() > 0) {
					i++;
				}

				if (scroll.getDeltaY() < 0) {
					i--;
				}

				if ((i >= min) && (i <= max)) {
					backendValue.setValue(i);
				}

				scroll.consume();
			}
		});

		if (parentPane != null) {
			parentPane.getChildren().add(txt);
		}

		return txt;
	}

	public static Slider addSlider(final Pane parentPane, final double min, final double max,
		final double defaultValue, final int ticks) {
		final Slider slider = new Slider();

		slider.setMin(min);
		slider.setMax(max);
		slider.setValue(defaultValue);

		slider.setShowTickLabels(false);
		slider.setShowTickMarks(true);

		slider.setMajorTickUnit(10 * ticks);
		slider.setMinorTickCount(ticks);
		slider.setBlockIncrement(1);

		slider.setOnMouseEntered(new EventHandler<MouseEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
				slider.requestFocus();
			}
		});

		slider.setOnScroll(new EventHandler<ScrollEvent>() {
			@Override
			public void handle(final ScrollEvent scroll) {
				int i = 1;

				// Increment by one full tick if CTRL pressed.
				if (scroll.isShortcutDown()) {
					i = ticks;
				}

				if (scroll.getDeltaY() > 0) {
					while ((i--) > 0) {
						slider.increment();
					}
				}

				if (scroll.getDeltaY() < 0) {
					while ((i--) > 0) {
						slider.decrement();
					}
				}

				scroll.consume();
			}
		});

		slider.setOnKeyPressed(new EventHandler<KeyEvent>() {
			@Override
			public void handle(final KeyEvent key) {
				int i = 1;

				// Increment by one full tick if CTRL pressed.
				if (key.isShortcutDown()) {
					i = ticks;
				}

				if (key.getCode() == KeyCode.RIGHT) {
					while ((i--) > 0) {
						slider.increment();
					}
				}

				if (key.getCode() == KeyCode.LEFT) {
					while ((i--) > 0) {
						slider.decrement();
					}
				}

				key.consume();
			}
		});

		if (parentPane != null) {
			parentPane.getChildren().add(slider);
		}

		return slider;
	}

	public static void runTasksCollection(final Collection<Runnable> tasks) {
		if (tasks != null) {
			for (final Runnable task : tasks) {
				GUISupport.runOnJavaFXThread(task);
			}
		}
	}

	public static void showDialog(final String title, final Node content,
		final Collection<Runnable> tasksDialogRefresh, final Collection<Runnable> tasksDialogOK,
		final Collection<Runnable> tasksUIRefresh) {
		GUISupport.runTasksCollection(tasksDialogRefresh);

		final Alert alert = new Alert(AlertType.CONFIRMATION);

		alert.setTitle(title);
		alert.getDialogPane().setContent(content);

		Optional<ButtonType> result = alert.showAndWait();

		GUISupport.logger.debug("Dialog: clicked on {}.", result.get());

		if (result.get() == ButtonType.OK) {
			GUISupport.runTasksCollection(tasksDialogOK);

			GUISupport.runTasksCollection(tasksUIRefresh);
		}
	}

	public static void showDialogInformation(final String message) {
		final Alert alert = new Alert(AlertType.INFORMATION);

		alert.setTitle("Information");
		alert.setContentText(message);
		alert.showAndWait();
	}

	public static void showDialogWarning(final String message) {
		final Alert alert = new Alert(AlertType.WARNING);

		alert.setTitle("Warning");
		alert.setContentText(message);
		alert.showAndWait();
	}

	public static void showDialogError(final String message) {
		final Alert alert = new Alert(AlertType.ERROR);

		alert.setTitle("Error");
		alert.setContentText(message);
		alert.showAndWait();
	}

	public static void showDialogException(final Throwable exception) {
		final ExceptionDialog alert = new ExceptionDialog(exception);

		alert.setTitle("Exception");
		alert.showAndWait();
	}

	public static void showDialogProgress(final Worker<?> worker) {
		final ProgressDialog progress = new ProgressDialog(worker);

		progress.setTitle("Progress ...");
	}

	public static File showDialogLoadFile(final String name, final List<String> allowedExtensions,
		final String initialFolderPath) {
		return showDialogLoadFile(Arrays.asList(PairRO.of(name, allowedExtensions)), initialFolderPath);
	}

	public static File showDialogLoadFile(final List<PairRO<String, List<String>>> allowedExtensions,
		final String initialFolderPath) {
		final FileChooser fileChooser = new FileChooser();

		fileChooser.setTitle("Select File to load from ...");

		if (allowedExtensions != null) {
			for (final PairRO<String, List<String>> ext : allowedExtensions) {
				fileChooser.getExtensionFilters().add(new ExtensionFilter(ext.getFirst(), ext.getSecond()));
			}
		}

		if (initialFolderPath != null) {
			final File initialFolder = new File(initialFolderPath);

			if (initialFolder.exists()) {
				if (initialFolder.isDirectory()) {
					fileChooser.setInitialDirectory(initialFolder);
				}
				else if (initialFolder.isFile()) {
					fileChooser.setInitialDirectory(initialFolder.getParentFile());
				}
			}
		}

		final File toLoad = fileChooser.showOpenDialog(null);

		if (toLoad == null) {
			return null;
		}

		if (!Files.checkReadPermissions(toLoad)) {
			GUISupport.showDialogError("Cannot read from file " + toLoad.getAbsolutePath());
			return null;
		}

		// Sanity check on file name extension.
		if (allowedExtensions != null) {
			for (final PairRO<String, List<String>> exts : allowedExtensions) {
				if (Files.checkExtensions(toLoad, exts.getSecond())) {
					return toLoad;
				}
			}

			GUISupport.showDialogError("Invalid file-name extension!");
			return null;
		}

		return toLoad;
	}

	public static File showDialogSaveFile(final String name, final List<String> allowedExtensions) {
		return showDialogSaveFile(Arrays.asList(PairRO.of(name, allowedExtensions)));
	}

	public static File showDialogSaveFile(final List<PairRO<String, List<String>>> allowedExtensions) {
		final FileChooser fileChooser = new FileChooser();

		fileChooser.setTitle("Select File to save to ...");

		if (allowedExtensions != null) {
			for (final PairRO<String, List<String>> ext : allowedExtensions) {
				fileChooser.getExtensionFilters().add(new ExtensionFilter(ext.getFirst(), ext.getSecond()));
			}
		}

		final File toSave = fileChooser.showSaveDialog(null);

		if (toSave == null) {
			return null;
		}

		if (!Files.checkWritePermissions(toSave)) {
			GUISupport.showDialogError("Cannot write to file " + toSave.getAbsolutePath());
			return null;
		}

		// Sanity check on file name extension.
		if (allowedExtensions != null) {
			for (final PairRO<String, List<String>> exts : allowedExtensions) {
				if (Files.checkExtensions(toSave, exts.getSecond())) {
					return toSave;
				}
			}

			GUISupport.showDialogError("Invalid file-name extension!");
			return null;
		}

		return toSave;
	}

	public static HBox addArrow(final Pane parentPane, final double lineLength, final double lineWidth,
		final double headLength, final double headAperture) {
		final HBox arrow = new HBox();
		arrow.setAlignment(Pos.TOP_LEFT);

		if (parentPane != null) {
			parentPane.getChildren().add(arrow);
		}

		final Line line = new Line(0, 0, lineLength, 0);
		line.setStrokeWidth(lineWidth);
		line.setFill(Color.BLACK);
		line.setTranslateY(headAperture - (lineWidth / 2));
		arrow.getChildren().add(line);

		final Polygon head = new Polygon(0, 0, headLength, headAperture, 0, 2 * headAperture);
		head.setFill(Color.BLACK);
		arrow.getChildren().add(head);

		return arrow;
	}

	public static void runOnJavaFXThread(final Runnable operationToRun) {
		if (operationToRun == null) {
			throw new NullPointerException();
		}

		if (Platform.isFxApplicationThread()) {
			operationToRun.run();
		}
		else {
			Platform.runLater(operationToRun);
		}
	}
}
