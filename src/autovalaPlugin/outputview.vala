using Gtk;
using Gdk;
using Gee;
using Vte;

namespace AutovalaPlugin {

	/**
	 * This is a GTK3 widget that allows to show the warnings and errors when
	 * building a project.
	 * This widget needs a ProjectView widget in order to work.
	 */
	public class OutputView : Gtk.Box {

		public bool running;

		private Vte.Terminal view;
		private Gtk.ScrolledWindow scroll;
		private int current_pid;

		public signal void running_command(int pid);
		public signal void ended_command(int pid, int retval);

		public OutputView() {
			this.current_pid = -1;
			this.view = null;
			this.scroll = new Gtk.ScrolledWindow(null,null);
			this.pack_start(this.scroll,true,true);
			this.clear_buffer();
			this.show_all();
		}

		public void clear_buffer() {

			if (this.view != null) {
				this.scroll.remove(this.view);
			}
			this.view = new Vte.Terminal();
			this.view.child_exited.connect( (status) => {
				this.running = false;
				this.ended_command(this.current_pid,status);
			});
			this.scroll.add(this.view);
			this.view.show_all();
			this.view.set_scrollback_lines(-1);
			this.view.set_scroll_on_output(true);
			this.view.set_scroll_on_keystroke(false);
			this.view.set_input_enabled(false);
		}

		public void append_text(string text) {
			this.view.feed((uint8[]) text.replace("\n","\r\n"));
		}

		public int run_command(string[] command, string working_path, bool clear = true) {

			if (this.running) {
				return -1;
			}

			this.running = true;
			if (clear) {
				this.clear_buffer();
			}

			var retval = this.view.spawn_sync(Vte.PtyFlags.DEFAULT,working_path,command,Environ.get(),GLib.SpawnFlags.SEARCH_PATH,null, out this.current_pid);

			if (retval) {
				return this.current_pid;
			} else {
				return -1;
			}
		}
	}
}
