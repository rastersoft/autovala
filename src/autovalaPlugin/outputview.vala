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

		private Gtk.TextBuffer buffer;
		private Gtk.TextView view;

		public OutputView() {
			this.buffer = new Gtk.TextBuffer(null);
			this.view = new Gtk.TextView();
			this.view.buffer = this.buffer;
			this.view.editable = false;
			var scroll = new Gtk.ScrolledWindow(null,null);
			scroll.add(this.view);
			this.pack_start(scroll,true,true);
			this.show_all();
		}

		public void clear_buffer() {

			Gtk.TextIter start;
			Gtk.TextIter end;
			this.buffer.get_start_iter(out start);
			this.buffer.get_end_iter(out end);
			this.buffer.delete(ref start, ref end);
		}

		public void append_text(string text) {

			Gtk.TextIter end;
			this.buffer.get_end_iter(out end);
			this.buffer.insert(ref end,text,-1);
		}
	}
}
