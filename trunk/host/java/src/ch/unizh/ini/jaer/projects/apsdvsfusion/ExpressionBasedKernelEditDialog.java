/**
 * 
 */
package ch.unizh.ini.jaer.projects.apsdvsfusion;

import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.Frame;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;
import java.awt.event.FocusEvent;
import java.awt.event.FocusListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;

import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JSpinner;
import javax.swing.JTextField;
import javax.swing.SpinnerModel;
import javax.swing.SpinnerNumberModel;
import javax.swing.Spring;
import javax.swing.SpringLayout;
import javax.swing.SwingUtilities;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

import ch.unizh.ini.jaer.projects.apsdvsfusion.gui.NonGLImageDisplay;

//import net.sf.jaer.graphics.ImageDisplay;

/**
 * @author Dennis
 *
 */
public class ExpressionBasedKernelEditDialog extends JDialog implements ActionListener, PropertyChangeListener {
	/**
	 * 
	 */
	private static final long serialVersionUID = -5468936818753278940L;
	JTextField onExpressionField = new JTextField();
//	JTextField offExpressionField = new JTextField();
	NonGLImageDisplay onConvolutionDisplay = NonGLImageDisplay.createNonGLDisplay();
//	NonGLImageDisplay offConvolutionDisplay = NonGLImageDisplay.createNonGLDisplay();
	//	int width = 5, height = 5;

	ExpressionBasedSpatialInputKernel myExpressionKernel = new ExpressionBasedSpatialInputKernel(7, 7);
//	JFrame kernelFrame;
	
	int outWidth = 128;
	int outHeight = 128;
	
	boolean valuesAccepted = false;
	
	public int getOutWidth() {
		return outWidth;
	}

	public void setOutWidth(int outWidth) {
		this.outWidth = outWidth;
	}

	public int getOutHeight() {
		return outHeight;
	}

	public void setOutHeight(int outHeight) {
		this.outHeight = outHeight;
	}

//	
//	public String getOffString() {
//		return offExpressionField.getText();
//	}
	public String getOnString() {
		return onExpressionField.getText();
	}
	public int getKernelWidth() {
		return myExpressionKernel.getWidth();
	}
	public int getKernelHeight() {
		return myExpressionKernel.getHeight();
	}
	public String getOnExpressionString() {
		return onExpressionField.getText();
	}
//	public String getOffExpressionString() {
//		return offExpressionField.getText();
//	}
	public boolean isValuesAccepted() {
		return valuesAccepted;
	}
	public void setParameters(int width, int height, int inWidth, int inHeight, int outWidth, int outHeight, String onExpressionString, String offExpressionString) {
		myExpressionKernel.changeSize(width, height);
		myExpressionKernel.setInputOutputSizes(inWidth, inHeight, outWidth, outHeight);
		myExpressionKernel.setExpressionString(onExpressionString);
//		myExpressionKernel.setOffExpressionString(offExpressionString);
		onExpressionField.setText(onExpressionString);
//		offExpressionField.setText(offExpressionString);
		widthSpinner.setValue(width);
		heightSpinner.setValue(height);
		outWidthSpinner.setValue(outWidth);
		outHeightSpinner.setValue(outHeight);
		updatePlots();
	}
	
	
//	private String typedText = null;
//	private JTextField textField;
//
//	private String magicWord;
	private JOptionPane optionPane;
//
	private String btnString1 = "Ok";
	private String btnString2 = "Cancel";

	JSpinner widthSpinner;
	JSpinner heightSpinner;

	JSpinner outWidthSpinner;
	JSpinner outHeightSpinner;

	/** Creates the reusable dialog. */
	public ExpressionBasedKernelEditDialog(Frame aFrame) {
		super(aFrame, "Edit kernel expressions", true);

//        onConvolutionDisplay.setBorderSpacePixels(18);
//        offConvolutionDisplay.setBorderSpacePixels(18);

//		onConvolutionDisplay.setSize(300,300);
		onConvolutionDisplay.setPreferredSize(new Dimension(250,250));
//        onConvolutionDisplay.setImageSize(7,7);
//		offConvolutionDisplay.setPreferredSize(new Dimension(250,250));
//        onConvolutionDisplay.setTitleLabel("Range: [ "+myFormatter.format(min)+"   "+myFormatter.format(max)+" ] ");

		JPanel inputPanel = new JPanel(new SpringLayout());
//		this.setContentPane(myPanel);
		JLabel jLabelOn = new JLabel("Expression for ON-Events:");
		inputPanel.add(jLabelOn);
		inputPanel.add(onExpressionField);
		onExpressionField.setText(myExpressionKernel.getExpressionString());
		jLabelOn.setLabelFor(onExpressionField);
//		JLabel jLabelOff = new JLabel("Expression for OFF-Events:");
//		inputPanel.add(jLabelOff);
//		inputPanel.add(offExpressionField);
//		offExpressionField.setText("0");//myExpressionKernel.getOffExpressionString());
//		jLabelOff.setLabelFor(offExpressionField);
		widthSpinner = addLabeledSpinner(inputPanel, "Width", new SpinnerNumberModel(7, 1, 101, 2));
		heightSpinner = addLabeledSpinner(inputPanel, "Height", new SpinnerNumberModel(7, 1, 101, 2));

		outWidthSpinner = addLabeledSpinner(inputPanel, "Output field width", new SpinnerNumberModel(128, 1, 200, 1));
		outHeightSpinner = addLabeledSpinner(inputPanel, "Output field height", new SpinnerNumberModel(128, 1, 200, 1));
		
		
		
//		kernelFrame = new JFrame("Kernel values (left: ON, right: OFF)");
		JPanel kernelFramePanel = new JPanel();
//		kernelFrame.setContentPane(kernelFramePanel);
//        kernelFramePanel.setBackground(Color.BLACK);
//        kernelFramePanel.setLayout(new FlowLayout());
        kernelFramePanel.setLayout(new GridBagLayout());
        GridBagConstraints c = new GridBagConstraints();
        c.fill = GridBagConstraints.BOTH;
        c.weightx = 0.5;
        c.weighty = 0.5;
        c.gridx = 0;
        c.gridy = 0;
        c.ipadx = 5;
        kernelFramePanel.add(onConvolutionDisplay,c);
        c.gridx = 1;
        c.insets = new Insets(0,10,0,0);
  //      kernelFramePanel.add(offConvolutionDisplay,c);
//        c.gridx = 2;
//        kernelFramePanel.add(new JButton("Test"),c);
        
//        JPanel onPanel = new JPanel();
//        onPanel.setPreferredSize(new Dimension(250,250));
//        onPanel.add(onConvolutionDisplay);
//        JPanel offPanel = new JPanel();
//        offPanel.add(offConvolutionDisplay);
//        offPanel.setPreferredSize(new Dimension(250,250));
//		kernelFramePanel.add(onPanel);
//		kernelFramePanel.add(offPanel);
//		kernelFrame.pack();
//		kernelFrame.setSize(450, 250);
//		kernelFrame.setVisible(true);
		
//		JButton addKernelButton = new JButton("Add kernel");
//		myPanel.add(addKernelButton);
//		myPanel.add(new JLabel(""));
//		
//		
//		addKernelButton.addActionListener(new ActionListener() {
//			
//			@Override
//			public void actionPerformed(ActionEvent arg0) {
//				// TODO Auto-generated method stub
//				
//			}
//		});

		widthSpinner.addChangeListener(new ChangeListener() {
			public void stateChanged(ChangeEvent arg0) {
				myExpressionKernel.setWidth((Integer)widthSpinner.getModel().getValue());
				plot(myExpressionKernel.getConvolutionValues(), onConvolutionDisplay);
//				plot(myExpressionKernel.getOffConvolutionValues(), offConvolutionDisplay);
			}
		});
		
		
		heightSpinner.addChangeListener(new ChangeListener() {
			public void stateChanged(ChangeEvent arg0) {
				myExpressionKernel.setHeight((Integer)heightSpinner.getModel().getValue());
				plot(myExpressionKernel.getConvolutionValues(), onConvolutionDisplay);
//				plot(myExpressionKernel.getOffConvolutionValues(), offConvolutionDisplay);
			}
		});
		
		
		outWidthSpinner.addChangeListener(new ChangeListener() {
			public void stateChanged(ChangeEvent arg0) {
				setOutWidth((Integer)outWidthSpinner.getModel().getValue());
			}
		});
		
		outHeightSpinner.addChangeListener(new ChangeListener() {
			public void stateChanged(ChangeEvent arg0) {
				setOutHeight((Integer)outHeightSpinner.getModel().getValue());
			}
		});

		
		onExpressionField.addActionListener(new ActionListener() {
			@Override
			public void actionPerformed(ActionEvent arg0) {
				myExpressionKernel.setExpressionString(onExpressionField.getText());
//				myExpressionKernel.setOffExpressionString(offExpressionField.getText());
				plot(myExpressionKernel.getConvolutionValues(), onConvolutionDisplay);
//				plot(myExpressionKernel.getOffConvolutionValues(), offConvolutionDisplay);
			}
		});
//		offExpressionField.addActionListener(new ActionListener() {
//			@Override
//			public void actionPerformed(ActionEvent arg0) {
//				updatePlots();
//			}
//		});
//		offExpressionField.addFocusListener(new FocusListener() {
//			@Override
//			public void focusLost(FocusEvent arg0) {
//				updatePlots();
//			}
//			@Override
//			public void focusGained(FocusEvent arg0) {
//			}
//		});
		onExpressionField.addFocusListener(new FocusListener() {
			@Override
			public void focusLost(FocusEvent arg0) {
				updatePlots();
			}
			@Override
			public void focusGained(FocusEvent arg0) {
			}
		});
		
		
		makeCompactGrid(inputPanel,5, 2, //rows, cols
				10, 10,        //initX, initY
                6, 10);       //xPad, yPad			
		
		JPanel combinedPanel = new JPanel(new BorderLayout());
		combinedPanel.add(inputPanel, BorderLayout.NORTH);
		combinedPanel.add(kernelFramePanel, BorderLayout.CENTER);
		
		
		Object[] array = {combinedPanel};
		 
        //Create an array specifying the number of dialog buttons
        //and their text.
        Object[] options = {btnString1, btnString2};
 
		//Create the JOptionPane.
		optionPane = new JOptionPane(array,
				JOptionPane.QUESTION_MESSAGE,
				JOptionPane.YES_NO_OPTION,
				null,
				options,
				options[0]);

		//Make this dialog display it.
		updatePlots();
		setContentPane(optionPane);

		//Handle window closing correctly.
		setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
		addWindowListener(new WindowAdapter() {
			public void windowClosing(WindowEvent we) {
				/*
				 * Instead of directly closing the window,
				 * we're going to change the JOptionPane's
				 * value property.
				 */
				optionPane.setValue(new Integer(
						JOptionPane.CLOSED_OPTION));
			}
		});

		//Ensure the text field always gets the first focus.
		addComponentListener(new ComponentAdapter() {
			public void componentShown(ComponentEvent ce) {
				onExpressionField.requestFocusInWindow();
			}
		});

		//Register an event handler that puts the text into the option pane.
		onExpressionField.addActionListener(this);

		//Register an event handler that reacts to option pane state changes.
		optionPane.addPropertyChangeListener(this);
		this.pack();
		setLocationRelativeTo(aFrame);
//		onConvolutionDisplay.display();
//		onConvolutionDisplay.repaint();
	}

	protected void updatePlots() {
		myExpressionKernel.setExpressionString(onExpressionField.getText());
//		myExpressionKernel.setOffExpressionString(offExpressionField.getText());
		plot(myExpressionKernel.getConvolutionValues(), onConvolutionDisplay);
//		plot(myExpressionKernel.getOffConvolutionValues(), offConvolutionDisplay);
	}
	
	public ExpressionBasedSpatialInputKernel createInputKernel() {
		ExpressionBasedSpatialInputKernel kernel = new SpaceableExpressionBasedSpatialIK(
				myExpressionKernel.getWidth(), myExpressionKernel.getHeight());
//		kernel.setOffExpressionString(myExpressionKernel.getOffExpressionString());
		kernel.setExpressionString(myExpressionKernel.getExpressionString());
		return kernel;
	}
	
//	public void setVisible(boolean visible) {
//		super.setVisible(visible);
////		kernelFrame.setVisible(visible);
//	}
	
    public void plot(final float[][] convolutionValues, final NonGLImageDisplay display) {
        float max=Float.NEGATIVE_INFINITY;
        float min=Float.POSITIVE_INFINITY;
        for (int i=0; i<convolutionValues.length; i++)
            for (int j=0; j<convolutionValues[i].length; j++)
            {   max=Math.max(max,convolutionValues[i][j]);
                min=Math.min(min,convolutionValues[i][j]);
            }
        
        max=Math.max(max,min+Float.MIN_VALUE);
        
        max=Math.abs(max);
        min=Math.abs(min);
        final float absmax=Math.max(min,max);
        
        max=absmax;
        min=-absmax;

        if (display.getSizeX() != convolutionValues.length || display.getSizeY() != convolutionValues[0].length)
        	display.setImageSize(convolutionValues.length,convolutionValues[0].length);
                
//        disp.setPreferredSize(new Dimension(300,300));
        SwingUtilities.invokeLater(new Runnable() {
			
			@Override
			public void run() {
				for (int x = 0; x < convolutionValues.length; x++)
					for (int y = 0; y < convolutionValues[x].length; y++) {
						float val = convolutionValues[x][y];
						if (val > 0)
							display.setPixmapRGB(x, y, val / absmax, 0, 0);
						else
							display.setPixmapRGB(x, y, 0, 0, -val / absmax);
					}
		        display.repaint();
			}
		});
		for (int x = 0; x < convolutionValues.length; x++)
			for (int y = 0; y < convolutionValues[x].length; y++) {
				float val = convolutionValues[x][y];
				if (val > 0)
					display.setPixmapRGB(x, y, val / absmax, 0, 0);
				else
					display.setPixmapRGB(x, y, 0, 0, -val / absmax);
			}
        display.repaint();
    }

	protected JSpinner addLabeledSpinner(Container c,
			String label,
			SpinnerModel model) {
		JLabel l = new JLabel(label);
		c.add(l);

		JSpinner spinner = new JSpinner(model);
		l.setLabelFor(spinner);
		c.add(spinner);

		return spinner;
	}
	/* Used by makeCompactGrid. */
    private SpringLayout.Constraints getConstraintsForCell(
                                                int row, int col,
                                                Container parent,
                                                int cols) {
        SpringLayout layout = (SpringLayout) parent.getLayout();
        Component c = parent.getComponent(row * cols + col);
        return layout.getConstraints(c);
    }

    /**
     * Aligns the first <code>rows</code> * <code>cols</code>
     * components of <code>parent</code> in
     * a grid. Each component in a column is as wide as the maximum
     * preferred width of the components in that column;
     * height is similarly determined for each row.
     * The parent is made just big enough to fit them all.
     *
     * @param rows number of rows
     * @param cols number of columns
     * @param initialX x location to start the grid at
     * @param initialY y location to start the grid at
     * @param xPad x padding between cells
     * @param yPad y padding between cells
     */
    private void makeCompactGrid(Container parent,
                                       int rows, int cols,
                                       int initialX, int initialY,
                                       int xPad, int yPad) {
        SpringLayout layout;
        try {
            layout = (SpringLayout)parent.getLayout();
        } catch (ClassCastException exc) {
            System.err.println("The first argument to makeCompactGrid must use SpringLayout.");
            return;
        }

        //Align all cells in each column and make them the same width.
        Spring x = Spring.constant(initialX);
        for (int c = 0; c < cols; c++) {
            Spring width = Spring.constant(0);
            for (int r = 0; r < rows; r++) {
                width = Spring.max(width,
                                   getConstraintsForCell(r, c, parent, cols).
                                       getWidth());
            }
            for (int r = 0; r < rows; r++) {
                SpringLayout.Constraints constraints =
                        getConstraintsForCell(r, c, parent, cols);
                constraints.setX(x);
                constraints.setWidth(width);
            }
            x = Spring.sum(x, Spring.sum(width, Spring.constant(xPad)));
        }

        //Align all cells in each row and make them the same height.
        Spring y = Spring.constant(initialY);
        for (int r = 0; r < rows; r++) {
            Spring height = Spring.constant(0);
            for (int c = 0; c < cols; c++) {
                height = Spring.max(height,
                                    getConstraintsForCell(r, c, parent, cols).
                                        getHeight());
            }
            for (int c = 0; c < cols; c++) {
                SpringLayout.Constraints constraints =
                        getConstraintsForCell(r, c, parent, cols);
                constraints.setY(y);
                constraints.setHeight(height);
            }
            y = Spring.sum(y, Spring.sum(height, Spring.constant(yPad)));
        }

        //Set the parent's size.
        SpringLayout.Constraints pCons = layout.getConstraints(parent);
        pCons.setConstraint(SpringLayout.SOUTH, y);
        pCons.setConstraint(SpringLayout.EAST, x);
    }		
	
	
	///////////////////////////// JDIalog-Quatsch
	
	/** This method handles events for the text field. */
	public void actionPerformed(ActionEvent e) {
		optionPane.setValue(btnString1);
	}

	/** This method reacts to state changes in the option pane. */
	public void propertyChange(PropertyChangeEvent e) {
		String prop = e.getPropertyName();

		if (isVisible()
				&& (e.getSource() == optionPane)
				&& (JOptionPane.VALUE_PROPERTY.equals(prop) ||
						JOptionPane.INPUT_VALUE_PROPERTY.equals(prop))) {
			Object value = optionPane.getValue();

			if (value == JOptionPane.UNINITIALIZED_VALUE) {
				//ignore reset
				return;
			}

			//Reset the JOptionPane's value.
			//If you don't do this, then if the user
			//presses the same button next time, no
			//property change event will be fired.
			optionPane.setValue(
					JOptionPane.UNINITIALIZED_VALUE);

			if (btnString1.equals(value)) {
				valuesAccepted = true;
				clearAndHide();
//				typedText = textField.getText();
//				String ucText = typedText.toUpperCase();
//				if (magicWord.equals(ucText)) {
//					//we're done; clear and dismiss the dialog
//					clearAndHide();
//				} else {
//					//text was invalid
//					textField.selectAll();
//					JOptionPane.showMessageDialog(
//							ExpressionBasedKernelEditDialog.this,
//							"Sorry, \"" + typedText + "\" "
//							+ "isn't a valid response.\n"
//							+ "Please enter "
//							+ magicWord + ".",
//							"Try again",
//							JOptionPane.ERROR_MESSAGE);
//					typedText = null;
//					textField.requestFocusInWindow();
//				}
			} else { //user closed dialog or clicked cancel
////				dd.setLabel("It's OK.  "
////						+ "We won't force you to type "
////						+ magicWord + ".");
//				typedText = null;
				valuesAccepted = false;
				clearAndHide();
			}
		}
	}

	/** This method clears the dialog and hides it. */
	public void clearAndHide() {
//		textField.setText(null);
		setVisible(false);
	}
	public static void main(String[] args) {
		ExpressionBasedKernelEditDialog dialog = new ExpressionBasedKernelEditDialog(null);
		dialog.setVisible(true);
	}
}