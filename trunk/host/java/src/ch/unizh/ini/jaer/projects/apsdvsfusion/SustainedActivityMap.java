/**
 * 
 */
package ch.unizh.ini.jaer.projects.apsdvsfusion;

/**
 * @author Dennis
 *
 */
public abstract class SustainedActivityMap implements FiringModelMap {

	DynamicHeap<PostponedFireEvent> heap = new DynamicHeap<PostponedFireEvent>();
	
	/**
	 * 
	 */
	public SustainedActivityMap() {
		// TODO Auto-generated constructor stub
	}

	
	public void processEvents(int uptoTime) {
		while (!heap.isEmpty() && heap.peek().getContent().getFireTime() <= uptoTime) {
			PostponedFireEvent event = heap.poll().getContent();
			// TODO: 
			event.getFiringModel().postponedEvent(event.getFireTime());
		}
	}
	

	public DynamicHeap<PostponedFireEvent>.Entry createEntry(PostponedFireEvent event) {
		return heap.createEntry(event);
	}
	/* (non-Javadoc)
	 * @see ch.unizh.ini.jaer.projects.apsdvsfusion.FiringModelMap#get(int, int)
	 */
//	@Override
	public abstract SustainedActivityFiringModel get(int x, int y);

	/* (non-Javadoc)
	 * @see ch.unizh.ini.jaer.projects.apsdvsfusion.FiringModelMap#getSizeX()
	 */
	@Override
	public int getSizeX() {
		// TODO Auto-generated method stub
		return 0;
	}

	/* (non-Javadoc)
	 * @see ch.unizh.ini.jaer.projects.apsdvsfusion.FiringModelMap#getSizeY()
	 */
	@Override
	public int getSizeY() {
		// TODO Auto-generated method stub
		return 0;
	}

	/* (non-Javadoc)
	 * @see ch.unizh.ini.jaer.projects.apsdvsfusion.FiringModelMap#changeSize(int, int)
	 */
	@Override
	public void changeSize(int sizeX, int sizeY) {
		// TODO Auto-generated method stub

	}

	/* (non-Javadoc)
	 * @see ch.unizh.ini.jaer.projects.apsdvsfusion.FiringModelMap#reset()
	 */
	@Override
	public void reset() {
		// TODO Auto-generated method stub

	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub

	}

}
