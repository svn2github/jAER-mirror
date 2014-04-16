package net.sf.jaer2;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import javafx.application.Application;
import javafx.geometry.Rectangle2D;
import javafx.scene.Scene;
import javafx.scene.layout.BorderPane;
import javafx.scene.paint.Color;
import javafx.stage.Screen;
import javafx.stage.Stage;

import javax.management.modelmbean.XMLParseException;

import net.sf.jaer2.util.Files;
import net.sf.jaer2.util.SSHS;

import org.xml.sax.SAXException;

import ch.unizh.ini.devices.ApsDvs10FX3;

public final class JAER2 extends Application {
	public static final String homeDirectory = System.getProperty("user.home") + File.separator + "jAER2";

	public static void main(final String[] args) {
		// Launch the JavaFX application: do initialization and call start()
		// when ready.
		Application.launch(args);
	}

	@Override
	public void start(final Stage primaryStage) {
		final String lastSessionDirectory = JAER2.homeDirectory + File.separator + "lastSession";
		final File savedSession = new File(lastSessionDirectory + File.separator + "net-last.xml");

		if (Files.checkReadPermissions(savedSession)) {
			// Restore configuration from saved file.
			try {
				SSHS.GLOBAL.getNode("/").importSubTreeFromXML(new FileInputStream(savedSession), true);
			}
			catch (SAXException | IOException | XMLParseException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		final ApsDvs10FX3 dvs = new ApsDvs10FX3(null);

		final BorderPane main = new BorderPane();
		main.setCenter(dvs.getConfigGUI());

		final Rectangle2D screen = Screen.getPrimary().getVisualBounds();
		final Scene rootScene = new Scene(main, screen.getWidth(), screen.getHeight(), Color.GRAY);

		// Add default CSS style-sheet.
		rootScene.getStylesheets().add("/styles/root.css");

		primaryStage.setTitle("jAER2 Device Configuration");
		primaryStage.setScene(rootScene);

		primaryStage.setOnCloseRequest((event) -> {
			// Try to save the current configuration to file.
			if (Files.checkWritePermissions(savedSession)) {
				try {
					savedSession.getParentFile().mkdirs();
					SSHS.GLOBAL.getNode("/").exportSubTreeToXML(new FileOutputStream(savedSession));
				}
				catch (final IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		});

		primaryStage.show();
	}
}
