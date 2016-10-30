using Gtk;
using Gdk;
using Gee;
using AutoVala;

namespace AutovalaPlugin {

	/**
	 * Creates a dialog to create a new project
	 */
	private class CreateNewProject : Object {

		private Gtk.Dialog main_window;
		private Gtk.Entry name;
		private Gtk.FileChooserButton path;
		private AutoVala.ManageProject project;
		private Gtk.Button accept_button;
		private Gtk.Label error_message;
		private string? project_name;
		private string? project_path;

		/**
		 * Constructor
		 */
		public CreateNewProject(AutoVala.ManageProject project) {

			this.project = project;
			this.project_name = null;
			this.project_path = null;

			var builder = new Gtk.Builder();
			builder.set_translation_domain(AutovalaPluginConstants.GETTEXT_PACKAGE);
			builder.add_from_resource("/com/rastersoft/autovala/interface/new_project.ui");
			this.main_window = (Gtk.Dialog) builder.get_object("new_project");
			this.name = (Gtk.Entry) builder.get_object("project_name");
			this.path = (Gtk.FileChooserButton) builder.get_object("project_folder");
			this.accept_button = (Gtk.Button) builder.get_object("button_accept");
			this.error_message = (Gtk.Label) builder.get_object("error_message");

            this.path.file_set.connect(this.folder_changed);
            this.path.current_folder_changed.connect(this.folder_changed);
            this.name.changed.connect(this.name_changed);

			this.main_window.show_all();
			this.set_status();
		}

		public bool run(out string? project_name, out string? project_path) {
			project_name = null;
			project_path = null;
			if (this.main_window == null) {
				return false;
			}
			while(true) {
				var retval = this.main_window.run();
				if (retval != 2) {
					return false;
				}
				if(this.project.init(this.name.text,this.path.get_filename())) {
					var messages = this.project.getErrors();
					string text = "";
					bool first = true;
					foreach (var msg in messages) {
						if (!first) {
							text+="\n";
							first = false;
						}
						text += msg;
					}
					this.error_message.set_text(text);
				} else {
					project_name = this.name.text;
					project_path = this.path.get_filename();
					return true;
				}
			}
		}

		public void destroy() {
			this.main_window.destroy();
			this.main_window = null;
		}

		[CCode(instance_pos=-1)]
		public void name_changed() {
			this.set_status();
		}

		[CCode(instance_pos=-1)]
		public void folder_changed(Gtk.FileChooser entry) {
			this.set_status();
		}

		public void set_status() {
			bool status = true;
			if (this.name.text == "") {
				status = false;
			}
			if ((this.path.get_filename() == "") || (this.path.get_filename() == null)) {
				status = false;
			}
			this.accept_button.sensitive = status;
		}
	}
}
