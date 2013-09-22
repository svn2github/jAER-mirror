package net.sf.jaer2;

import java.io.File;

import javafx.application.Application;
import javafx.event.EventHandler;
import javafx.geometry.Rectangle2D;
import javafx.scene.Scene;
import javafx.scene.layout.BorderPane;
import javafx.scene.paint.Color;
import javafx.stage.Screen;
import javafx.stage.Stage;
import javafx.stage.WindowEvent;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.XMLconf;
import ch.unizh.ini.devices.ApsDvs10;

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

		final ApsDvs10 dvs;

		if (GUISupport.checkReadPermissions(savedSession)) {
			// Restore last network from saved file.
			dvs = XMLconf.fromXML(ApsDvs10.class, savedSession);
		}
		else {
			// Create new empty network.
			dvs = new ApsDvs10(null);
		}

		final BorderPane main = new BorderPane();
		main.setCenter(dvs.getConfigGUI());

		final Rectangle2D screen = Screen.getPrimary().getVisualBounds();
		final Scene rootScene = new Scene(main, screen.getWidth(), screen.getHeight(), Color.GRAY);

		// Add default CSS style-sheet.
		rootScene.getStylesheets().add("/styles/root.css");

		primaryStage.setTitle("jAER2 Device Configuration");
		primaryStage.setScene(rootScene);

		primaryStage.setOnCloseRequest(new EventHandler<WindowEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final WindowEvent event) {
				// Try to save the current network to file.
				if (GUISupport.checkWritePermissions(savedSession)) {
					// XMLconf.toXML(dvs, null, savedSession);
				}
			}
		});

		primaryStage.show();
	}
}