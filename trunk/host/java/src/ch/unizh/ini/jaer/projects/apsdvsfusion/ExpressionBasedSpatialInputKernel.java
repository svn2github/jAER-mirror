/**
 * 
 */
package ch.unizh.ini.jaer.projects.apsdvsfusion;

import java.util.HashMap;
import java.util.prefs.Preferences;

import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.event.PolarityEvent.Polarity;

import ch.unizh.ini.jaer.projects.apsdvsfusion.mathexpression.ExpressionTreeBuilder;
import ch.unizh.ini.jaer.projects.apsdvsfusion.mathexpression.ExpressionTreeNode;
import ch.unizh.ini.jaer.projects.apsdvsfusion.mathexpression.IllegalExpressionException;

/**
 * @author Dennis
 *
 */
public class ExpressionBasedSpatialInputKernel implements InputKernel {
	int width = -1, height = -1;

	int centerX, centerY;
	int offsetX, offsetY;

	String onExpressionString = "0.01";
	String offExpressionString = "0.01";
	
//	ExpressionTreeNode onExpressionTree = null;
//	ExpressionTreeNode offExpressionTree = null;
	
	boolean evaluateExpressionAsReceptiveField = true;
	float[][] onConvolutionValues = null;
	public synchronized float[][] getOnConvolutionValues() {
		return onConvolutionValues;
	}

	public synchronized float[][] getOffConvolutionValues() {
		return offConvolutionValues;
	}

	float[][] offConvolutionValues = null;

	/**
	 * 
	 */
	public ExpressionBasedSpatialInputKernel(int width, int height) {
		changeSize(width, height);
	}
	
	public String getOnExpressionString() {
		return onExpressionString;
	}


	public void setOnExpressionString(String onExpressionString) {
		try {
			this.onConvolutionValues = evaluateExpression(onExpressionString, onConvolutionValues, this.onExpressionString);
			this.onExpressionString = onExpressionString;
		} catch (IllegalExpressionException e) {
		}
	}

	public String getOffExpressionString() {
		return offExpressionString;
	}

	public void setOffExpressionString(String offExpressionString) {
		try {
			this.offConvolutionValues = evaluateExpression(offExpressionString, offConvolutionValues, this.offExpressionString);
			this.offExpressionString = offExpressionString;
		} catch (IllegalExpressionException e) {
		}
	}
	
	protected synchronized float[][] evaluateExpression(String expressionString, float[][] oldConvolutionValues, String oldString) throws IllegalExpressionException {
		ExpressionTreeNode et = ExpressionTreeBuilder.parseString(expressionString);
		float[][] newValues = new float[oldConvolutionValues.length][oldConvolutionValues[0].length];
		try {
			HashMap<String, Double> map = new HashMap<String, Double>();
			for (int x = 0; x < width; x++) {
				map.put("x", (double)(x - centerX));
				for (int y = 0; y < height; y++) {
					map.put("y", (double)(y - centerY));
					newValues[x][y] = (float)et.evaluate(map);
				}
			}
			
			if (evaluateExpressionAsReceptiveField) {
				// reflect if in receptive field mode:
				for (int x = 0; x < width; x++) {
					for (int y = 0; y < height; y++) {
						oldConvolutionValues[width-x-1][height-y-1] = newValues[x][y];
					}
				}
				return oldConvolutionValues;
			}
			else
				return newValues;
		}
		catch (RuntimeException e) {
			throw new IllegalExpressionException("Runtime Exception returned while evaluating expression tree!: "+e.toString());
		}
	}
	
	public synchronized void setWidth(int width) {
		changeSize(width, height);
	}
	public synchronized void setHeight(int height) {
		changeSize(width, height);
	}

	public synchronized int getWidth() {
		return width;
	}

	public synchronized int getHeight() {
		return height;
	}
	
	public synchronized void changeSize(int width, int height) {
		if (width != this.width || height != this.height && width >= 0 && height >= 0) {
			this.width = width;
			this.height = height;
			try {
				onConvolutionValues = evaluateExpression(onExpressionString, new float[width][height], "0");
				offConvolutionValues = evaluateExpression(offExpressionString, new float[width][height], "0");
			} catch (IllegalExpressionException e) {
			}
			
			this.centerX = width/2;
			this.centerY = height/2;
			recomputeMappings();
		}
	}
	
	protected void recomputeMappings() {
		
	}
	
	public synchronized void setInputOutputSizes(int inputX, int inputY, int outputX, int outputY) {
		changeOffset((outputX - inputX) / 2 ,(outputX - outputY) / 2);
	}
	public synchronized void changeOffset(int offsetX, int offsetY) {
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}
	
	public synchronized int getCenterX() {
		return centerX;
	}

	public synchronized int getCenterY() {
		return centerY;
	}

	public synchronized void setCenterX(int centerX) {
		this.centerX = centerX;
		recomputeMappings();
	}
	
	public synchronized void setCenterY(int centerY) {
		this.centerY = centerY;
		recomputeMappings();
	}

	@Override
	public synchronized void apply(int tx, int ty, int time, Polarity polarity,
			FiringModelMap map, SpikeHandler spikeHandler) {
		tx = tx - centerX + offsetX;
		ty = ty - centerY + offsetY;
		int minx = Math.max(0, -tx), maxx = Math.min(width, map.getSizeX()-tx);
		int miny = Math.max(0, -ty), maxy = Math.min(height, map.getSizeY()-ty);
		tx += minx; ty += miny;
		float[][] convolutionValues;
		if (polarity == Polarity.On) 
			convolutionValues = onConvolutionValues;
		else
			convolutionValues = offConvolutionValues;
//		tx -= map.getOffsetX();
//		ty -= map.getOffsetY();
		for (int x = minx; x < maxx; x++, tx++) {
			for (int y = miny, ity = ty; y < maxy; y++, ity++) {
				if (map.get(tx,ity).receiveSpike(convolutionValues[x][y], time)) {
					spikeHandler.spikeAt(tx,ity,time, Polarity.On);
				}
			}
		}
	}

	@Override
	public int getOffsetX() {
		return offsetX;
	}

	@Override
	public int getOffsetY() {
		return offsetY;
	}

	@Override
	public void setOffsetX(int offsetX) {
		this.offsetX = offsetX;
	}

	@Override
	public void setOffsetY(int offsetY) {
		this.offsetY = offsetY;
	}

	public synchronized void savePrefs(Preferences prefs, String prefString) {
		prefs.put(prefString+"onExpressionString", onExpressionString);
		prefs.put(prefString+"offExpressionString", offExpressionString);
		prefs.putInt(prefString+"width", width);
		prefs.putInt(prefString+"height", height);
		prefs.putInt(prefString+"centerX", centerX);
		prefs.putInt(prefString+"centerY", centerY);
		prefs.putInt(prefString+"offsetX", offsetX);
		prefs.putInt(prefString+"offsetY", offsetY);
	}
	
	public synchronized void loadPrefs(Preferences prefs, String prefString) {
		int width = prefs.getInt(prefString+"width", this.width);
		int height = prefs.getInt(prefString+"height", this.height);
		changeSize(width, height);
		centerX = prefs.getInt(prefString+"centerX", centerX);
		centerY = prefs.getInt(prefString+"centerY", centerY);
		offsetX = prefs.getInt(prefString+"offsetX", offsetX);
		offsetY = prefs.getInt(prefString+"offsetY", offsetY);
		setOnExpressionString(prefs.get(prefString+"onExpressionString", onExpressionString));
		setOffExpressionString(offExpressionString = prefs.get(prefString+"offExpressionString", offExpressionString));
	}

}
