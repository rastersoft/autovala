using Gtk;
using Gdk;
using Gee;
using AutoVala;

namespace AutovalaPlugin {

	/**
	 * Shows the upper action buttons that allows to create a new project,
	 * update the CMake files, translations, and so on.
	 */
	public class ActionButtons : Gtk.Box {

		private Gtk.Button new_project;
		private Gtk.MenuButton expand_menu;
		private Gtk.Menu popupMenu;
		private Gtk.MenuItem update_project;
		private Gtk.MenuItem update_translations;
		
		private CreateNewProject create_new_project;

		private AutoVala.ManageProject current_project;
		private string ? current_project_file;

		/**
		 * This signal is emited when a new project has been created
		 * @param path The full path to the default source file
		 */
		public signal void open_file(string path);

		public signal void action_new_project();
		public signal void action_update_project();
		public signal void action_update_gettext();

		public ActionButtons() {

			this.create_new_project = null;
			this.orientation = Gtk.Orientation.HORIZONTAL;
		
			this.new_project = new Gtk.Button.with_label(_("New project"));
			this.new_project.tooltip_text =_("Creates a new Autovala project");
			this.pack_start(this.new_project,false,false);

			this.expand_menu = new Gtk.MenuButton();
			this.pack_start(this.expand_menu,false,false);

			this.popupMenu = new Gtk.Menu();

			this.update_project = new Gtk.MenuItem.with_label(_("Update project"));
			this.update_translations = new Gtk.MenuItem.with_label(_("Update translations"));

			this.new_project.clicked.connect( () => {
				if (this.create_new_project != null) {
					return;
				}

				string? project_name;
				string? project_path;
				this.create_new_project = new CreateNewProject(this.current_project);
				if (this.create_new_project.run(out project_name, out project_path)) {
					this.current_project.refresh(Path.build_filename(project_path,project_name+".avprj"));
					var base_name = Path.build_filename(project_path,"src",project_name+".vala");
					this.open_file(base_name);
				}
				this.create_new_project.destroy();
				this.create_new_project = null;
			});

			this.update_project.activate.connect( () => {
				var retval=this.current_project.refresh(this.current_project_file);
				this.current_project.showErrors();
				if (!retval) {
					retval=this.current_project.cmake(this.current_project_file);
					this.current_project.showErrors();
				}
				this.action_update_project();
			});

			this.update_translations.activate.connect( () => {
				this.current_project.gettext(this.current_project_file);
				this.current_project.showErrors();
				this.action_update_gettext();
			});
			this.popupMenu.append(this.update_project);
			this.popupMenu.append(this.update_translations);
			this.popupMenu.show_all();
			this.expand_menu.set_popup(this.popupMenu);
			this.show_all();
		}
		
		/**
		 * This method allows to indicate to the widget which file is being edited by the user.
		 * The widget uses this to search for an Autovala project file associated to that file,
		 * and update the project view.
		 * @param file The full path of the current file
		 */
		public void set_current_project_file(string? file) {

			this.current_project_file = file;
			if (file == null) {
				this.update_project.sensitive=false;
				this.update_translations.sensitive=false;
			} else {
				this.update_project.sensitive=true;
				this.update_translations.sensitive=true;
			}
		}

		/**
		 * This method sets the ManageProject object, allowing to share it
		 * with the ProjectView object
		 * @param project The ManageProject created by the ProjectView
		 */
		public void set_current_project(AutoVala.ManageProject project) {
		
			this.current_project = project;
		}
	}

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
			builder.add_from_file(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","new_project.ui"));
			this.main_window = (Gtk.Dialog) builder.get_object("new_project");
			this.name = (Gtk.Entry) builder.get_object("project_name");
			this.path = (Gtk.FileChooserButton) builder.get_object("project_folder");
			this.accept_button = (Gtk.Button) builder.get_object("button_accept");
			this.error_message = (Gtk.Label) builder.get_object("error_message");

			this.main_window.show_all();
			builder.connect_signals(this);
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
		public void name_changed(Gtk.Entry entry) {
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
