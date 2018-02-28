using Gtk;
using Gdk;

namespace AutovalaPlugin {
	/**
	 * This is a Gtk.Paned that can be set to a percentage value, instead of
	 * having to use absolute values (which depends on the current size of
	 * the panel).
	 */

	public class PanedPercentage : Gtk.Paned {
		private int current_paned_position;
		private int current_paned_size;
		private double desired_paned_percentage;
		private bool changed_paned_size;

		public PanedPercentage(Gtk.Orientation orientation, double percentage) {
			this.current_paned_position = -1;
			this.current_paned_size     = -1;
			this.changed_paned_size     = false;

			this.orientation = orientation;
			this.desired_paned_percentage = percentage;

			/*
			 * This is a trick to ensure that the paned remains with the same relative
			 * position, no mater if the user resizes the window
			 */

			this.size_allocate.connect_after((allocation) => {
				if (this.current_paned_size != allocation.height) {
				    this.current_paned_size = allocation.height;
				    this.changed_paned_size = true;
				}
			});

			this.draw.connect((cr) => {
				if (changed_paned_size) {
				    this.current_paned_position = (int) (this.current_paned_size * this.desired_paned_percentage);
				    this.set_position(this.current_paned_position);
				    this.changed_paned_size = false;
				} else {
				    if (this.position != this.current_paned_position) {
				        this.current_paned_position   = this.position;
				        this.desired_paned_percentage = ((double) this.current_paned_position) / ((double) this.current_paned_size);
					}
				}
				return false;
			});
		}
	}
}
