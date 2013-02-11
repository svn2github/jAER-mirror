/**
 * 
 */
package ch.unizh.ini.jaer.projects.apsdvsfusion;

import java.util.ArrayList;

import ch.unizh.ini.jaer.projects.apsdvsfusion.gui.ParameterContainer;

/**
 * @author Dennis Goehlsdorf
 *
 */
public abstract class FiringModelMap extends ParameterContainer {
	/**
	 * 
	 */
	private static final long serialVersionUID = 3772350769713414996L;
	
	int sizeX = -1, sizeY = -1;
	FiringModelCreator firingModelCreator = null;
	SpikeHandlerSet spikeHandlerSet;
	ArrayList<SignalTransformationKernel> inputKernels = new ArrayList<SignalTransformationKernel>();
	
//	public class FiringModelMapParameterContainer extends ParameterContainer {
//		/**
//		 * 
//		 */
//		private static final long serialVersionUID = 1749152638935077965L;
//
//		public FiringModelMapParameterContainer(String name) {
//			super(name);
//		}
//
//		public void setSizeX
//		
//	}
//	
//	private FiringModelMapParameterContainer myParameterContainer = createParameterContainer();
	
	
	public FiringModelMap(int sizeX, int sizeY) {
		super("FiringModelMap");
		this.spikeHandlerSet = new SpikeHandlerSet()/*spikeHandler*/;
		changeSize(sizeX, sizeY);
	}
	
	public FiringModelMap(int sizeX, int sizeY, SpikeHandler spikeHandler) {
		this(sizeX, sizeY);
		this.spikeHandlerSet.addSpikeHandler(spikeHandler);
	}

//	protected FiringModelMapParameterContainer createParameterContainer() {
//		return new FiringModelMapParameterContainer("FiringModelMap");
//	}
	
	public FiringModelCreator getFiringModelCreator() {
		return firingModelCreator;
	}

	public void setFiringModelCreator(FiringModelCreator firingModelCreator) {
		this.firingModelCreator = firingModelCreator;
		buildUnits();
	}
	
	public abstract void buildUnits(); 

	public SpikeHandler getSpikeHandler() {
		return spikeHandlerSet;
	}

	public void addSpikeHandler(SpikeHandler spikeHandler) {
		this.spikeHandlerSet.addSpikeHandler(spikeHandler);
	}

	public void removeSpikeHandler(SpikeHandler spikeHandler) {
		this.spikeHandlerSet.removeSpikeHandler(spikeHandler);
	}
	
	
	public int getSizeX() {
		return sizeX;
	}
	public int getSizeY() {
		return sizeY;
	}

	
	//	public int getOffsetX();
//	public int getOffsetY();
	
	/**
	 * @param sizeX the sizeX to set
	 */
	public synchronized void setSizeX(int sizeX) {
		changeSize(sizeX, sizeY);
	}

	/**
	 * @param sizeY the sizeY to set
	 */
	public synchronized void setSizeY(int sizeY) {
		changeSize(sizeX, sizeY);
	}

	public synchronized void changeSize(int sizeX, int sizeY) {
		if (sizeX != this.sizeX || sizeY != this.sizeY) {
			int ox = this.sizeX, oy = this.sizeY;
			this.sizeX = sizeX;
			this.sizeY = sizeY;
			buildUnits();
			for (SignalTransformationKernel kernel : inputKernels) {
				kernel.outputSizeChanged(ox, oy, sizeX, sizeY);
			}
		}
	}

	public abstract FiringModel get(int x, int y);
	public abstract void reset();
}
