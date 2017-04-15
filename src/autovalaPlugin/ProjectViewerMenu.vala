using Gtk;
using Gdk;
using Gee;
using AutoVala;

namespace AutovalaPlugin {
	/**
	 * This class manages the popup menu in the project view
	 */
	private class ProjectViewerMenu : Gtk.Menu {

		private string project_path;
		private string? file_path;
		private string binary_name;
		private ProjectEntryTypes type;
		private Gtk.MenuItem action_open;
		private Gtk.MenuItem action_new_binary;
		private Gtk.MenuItem action_edit_binary;
		private Gtk.MenuItem action_delete_binary;

		public signal void open(string file);
		public signal void new_binary();
		public signal void edit_binary(string ?binary_name);
		public signal void remove_binary(string ?binary_name);

		public ProjectViewerMenu(string ?project_path, string ?file_path, string ?binary_name, ProjectEntryTypes type) {

			this.project_path = project_path;
			this.file_path = file_path;
			this.binary_name = binary_name;
			this.type = type;

			this.action_open = new Gtk.MenuItem.with_label(_("Open"));
			this.action_new_binary = new Gtk.MenuItem.with_label(_("New executable/library"));
			this.action_edit_binary = new Gtk.MenuItem.with_label((type == ProjectEntryTypes.LIBRARY) ? _("Edit library properties") : _("Edit executable properties"));
			this.action_delete_binary = new Gtk.MenuItem.with_label((type == ProjectEntryTypes.LIBRARY) ? _("Remove library") : _("Remove executable"));

			switch (type) {
			case ProjectEntryTypes.VALA_SOURCE_FILE:
			case ProjectEntryTypes.C_SOURCE_FILE:
			case ProjectEntryTypes.C_HEADER_FILE:
			case ProjectEntryTypes.VAPI_FILE:
			case ProjectEntryTypes.PROJECT_FILE:
				this.append(this.action_open);
				this.append(new Gtk.SeparatorMenuItem());
			break;
			}

			this.append(this.action_new_binary);

			if ((type == ProjectEntryTypes.EXECUTABLE)||(type == ProjectEntryTypes.LIBRARY)) {
				this.append(this.action_edit_binary);
				this.append(this.action_delete_binary);
			}

			this.action_open.activate.connect( () => {
				this.open(this.file_path);
			});
			this.action_new_binary.activate.connect( () => {
				this.new_binary();
			});
			this.action_edit_binary.activate.connect( () => {
				this.edit_binary(binary_name);
			});
			this.action_delete_binary.activate.connect( () => {
				this.remove_binary(binary_name);
			});
		}
	}
}
