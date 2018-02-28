using Gtk;
using Gdk;
using Gee;
using AutoVala;

namespace AutovalaPlugin {
	/**
	 * Creates a dialog to add a new binary to a project, or to modify a current one
	 */
	private class ProjectProperties : Object {
		private Gtk.Dialog main_window;
		private Gtk.Entry name;
		private Gtk.FileChooserButton path;
		private Gtk.RadioButton is_library;
		private Gtk.RadioButton is_executable;
		private AutoVala.ManageProject project;
		private Gtk.Entry vala_options;
		private Gtk.Entry c_options;
		private Gtk.Entry libraries;
		private Gtk.Button accept_button;
		private Gtk.Label error_message;
		private string project_file;
		private string ? binary_name;
		private bool editing;

		/**
		 * Constructor
		 *
		 * @param binary_name The name of the executable/library to edit, or null to create a new one
		 * @param project_file The full path to the current project file where to edit or create the binary
		 * @param project A project class
		 */
		public ProjectProperties(string ? binary_name, string project_file, AutoVala.ManageProject project) {
			this.project      = project;
			this.project_file = project_file;
			this.binary_name  = binary_name;
			if (binary_name == null) {
				this.editing = false;
			} else {
				this.editing = true;
			}

			var builder = new Gtk.Builder();
			builder.set_translation_domain(AutovalaPluginConstants.GETTEXT_PACKAGE);
			builder.add_from_resource("/com/rastersoft/autovala/interface/binary_properties.ui");
			this.main_window   = (Gtk.Dialog)builder.get_object("binary_properties");
			this.name          = (Gtk.Entry)builder.get_object("binary_name");
			this.path          = (Gtk.FileChooserButton)builder.get_object("path");
			this.is_library    = (Gtk.RadioButton)builder.get_object("is_library");
			this.is_executable = (Gtk.RadioButton)builder.get_object("is_executable");
			this.vala_options  = (Gtk.Entry)builder.get_object("vala_compile_options");
			this.c_options     = (Gtk.Entry)builder.get_object("c_compile_options");
			this.libraries     = (Gtk.Entry)builder.get_object("libraries");
			this.accept_button = (Gtk.Button)builder.get_object("button_accept");
			this.error_message = (Gtk.Label)builder.get_object("error_message");

			this.path.file_set.connect(this.path_changed);
			this.path.current_folder_changed.connect(this.path_changed);
			this.name.changed.connect(this.name_changed);

			if (this.editing) {
				var project_data = project.get_binaries_list(project_file);
				if (project_data != null) {
					foreach (var element in project_data.binaries) {
						if (((element.type == AutoVala.ConfigType.VALA_BINARY) || (element.type == AutoVala.ConfigType.VALA_LIBRARY)) && (element.name == binary_name)) {
							this.name.text = element.name;
							this.path.set_filename(Path.build_filename(project_data.projectPath, element.fullPath));
							if (element.type == AutoVala.ConfigType.VALA_BINARY) {
								this.is_executable.active = true;
							} else {
								this.is_library.active = true;
							}
							this.vala_options.text = element.vala_opts;
							this.c_options.text    = element.c_opts;
							this.libraries.text    = element.libraries;
						}
					}
				}
			} else {
				this.path.set_filename(Path.get_dirname(project_file));
			}
			this.main_window.show_all();
			this.set_status();
		}

		public void run() {
			if (this.main_window == null) {
				return;
			}
			while (true) {
				var retval = this.main_window.run();
				if (retval != 2) {
					break;
				}
				var retMsg = this.project.process_binary(this.binary_name, this.project_file, this.name.text, this.is_library.active, this.path.get_filename(), this.vala_options.text, this.c_options.text, this.libraries.text);
				if (null == retMsg) {
					break;
				} else {
					this.error_message.set_text(retMsg);
				}
			}
		}

		public void destroy() {
			this.main_window.destroy();
			this.main_window = null;
		}

		[CCode(instance_pos = -1)]
		public void name_changed() {
			this.set_status();
		}

		[CCode(instance_pos = -1)]
		public void path_changed(Gtk.FileChooser entry) {
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
