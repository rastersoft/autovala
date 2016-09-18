using Gtk;
using Gdk;
using Gee;
using AutoVala;
//using GIO
namespace AutovalaPlugin {

	/**
	 * Shows the upper action buttons that allows to create a new project,
	 * update the CMake files, translations, and so on.
	 * This widget needs a ProjectView widget in order to work.
	 */
	public class ActionButtons : Gtk.Box {

		private Gtk.Button new_project;
		private Gtk.Button refresh_project;
		private Gtk.Button update_project;
		private Gtk.Button update_translations;
		private Gtk.Button build_project;
		private Gtk.Button full_build_project;

		private CreateNewProject create_new_project;

		private AutoVala.ManageProject current_project;
		private string ? current_project_file;

		/**
		 * This signal is emited when a new project has been created
		 * @param path The full path to the default source file
		 */
		public signal void open_file(string path);

		public signal void action_new_project();
		public signal void action_refresh_project(bool retval);
		public signal void action_update_project(bool retval);
		public signal void action_update_gettext(bool retval);
		public signal void action_build(bool retval);
		public signal void action_full_build(bool retval);

		/**
		 * This signal is emited when the output view must be clear
		 * because a new job is going to be launch
		 */
		public signal void output_message_clear();
		/**
		 * This signal is emited when there is output from a job
		 */
		public signal void output_message_append(string msg);

		public signal void set_project_status(ProjectStatus status);

		public ActionButtons() {

			int iconsize = 30;
			int sep_margin = 2;

			Gdk.Pixbuf pixbuf;
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/build.svg",iconsize,iconsize,false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-build",-1,pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/full_build.svg",iconsize,iconsize,false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-full-build",-1,pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/refresh.svg",iconsize,iconsize,false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-refresh",-1,pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/refresh_langs.svg",iconsize,iconsize,false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-refresh-langs",-1,pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/update.svg",iconsize,iconsize,false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-update",-1,pixbuf);

			this.create_new_project = null;
			this.orientation = Gtk.Orientation.HORIZONTAL;

			this.new_project = new Gtk.Button.from_icon_name("document-new",Gtk.IconSize.LARGE_TOOLBAR);
			this.new_project.tooltip_text =_("Creates a new Autovala project");
			this.pack_start(this.new_project,false,false);

			var sep1 = new Gtk.Separator(Gtk.Orientation.VERTICAL);
			sep1.margin_start = sep_margin;
			sep1.margin_end = sep_margin;

			this.pack_start(sep1,false,false);

			this.refresh_project = new Gtk.Button.from_icon_name("autovala-plugin-refresh",Gtk.IconSize.LARGE_TOOLBAR);
			this.refresh_project.tooltip_text =_("Refreshes the Autovala project");
			this.pack_start(this.refresh_project,false,false);

			this.update_project = new Gtk.Button.from_icon_name("autovala-plugin-update",Gtk.IconSize.LARGE_TOOLBAR);
			this.update_project.tooltip_text =_("Updates the project and rebuilds the CMake files");
			this.pack_start(this.update_project,false,false);

			this.build_project = new Gtk.Button.from_icon_name("autovala-plugin-build",Gtk.IconSize.LARGE_TOOLBAR);
			this.build_project.tooltip_text =_("Builds the Autovala project");
			this.pack_start(this.build_project,false,false);

			this.full_build_project = new Gtk.Button.from_icon_name("autovala-plugin-full-build",Gtk.IconSize.LARGE_TOOLBAR);
			this.full_build_project.tooltip_text =_("Builds the Autovala project");
			this.pack_start(this.full_build_project,false,false);

			sep1 = new Gtk.Separator(Gtk.Orientation.VERTICAL);
			sep1.margin_start = sep_margin;
			sep1.margin_end = sep_margin;

			this.pack_start(sep1,false,false);

			this.update_translations = new Gtk.Button.from_icon_name("autovala-plugin-refresh-langs",Gtk.IconSize.LARGE_TOOLBAR);
			this.update_translations.tooltip_text =_("Updates the language translation files");
			this.pack_start(this.update_translations,false,false);

			this.new_project.clicked.connect( () => {
				if (this.create_new_project != null) {
					return;
				}

				string? project_name;
				string? project_path;
				this.current_project = new AutoVala.ManageProject();
				this.create_new_project = new CreateNewProject(this.current_project);
				if (this.create_new_project.run(out project_name, out project_path)) {
					this.current_project.refresh(Path.build_filename(project_path,project_name+".avprj"));
					var base_name = Path.build_filename(project_path,"src",project_name+".vala");
					this.open_file(base_name);
					this.output_message_clear();
				}
				this.create_new_project.destroy();
				this.create_new_project = null;
			});

			this.refresh_project.clicked.connect( () => {
				this.current_project = new AutoVala.ManageProject();
				if (this.refresh_project_cb()) {
					this.output_message_append(_("Aborting\n"));
				} else {
					this.output_message_append(_("Done\n"));
				}
			});

			this.update_project.clicked.connect( () => {
				this.current_project = new AutoVala.ManageProject();
				if (this.update_project_cb()) {
					this.output_message_append(_("Aborting\n"));
				} else {
					this.output_message_append(_("Done\n"));
				}
			});

			this.update_translations.clicked.connect( () => {
				this.output_message_clear();
				this.current_project = new AutoVala.ManageProject();
				var retval = this.current_project.gettext(this.current_project_file);
				var msgs = this.current_project.getErrors();
				foreach(var msg in msgs) {
					this.output_message_append(msg+"\n");
				}
				this.action_update_gettext(retval);
			});

			this.build_project.clicked.connect( () => {
				this.output_message_clear();
				this.current_project = new AutoVala.ManageProject();
				if (this.update_project_cb(false)) {
					this.output_message_append(_("Aborting\n"));
					return;
				}
				this.build_cb();
			});

			this.show_all();
		}

		private bool build_cb() {
			var data = this.current_project.get_binaries_list(this.current_project_file);
			if (data == null) {
				return true;
			}

			var install_path = GLib.Path.build_filename(data.projectPath,"install");

			var install_file = GLib.File.new_for_path(install_path);
			if (false == install_file.query_exists()) {
				install_file.make_directory();
			}

			string[] command = {"make"};

			this.launch_program(install_path,command);
			return false;
		}

		private void launch_program(string working_directory, string[] command_args) {

			this.output_message_append(_("Launching %s at %s folder\n").printf(command_args[0],working_directory));

			this.set_buttons(false);

			string[] spawn_env = Environ.get ();
			Pid child_pid;

			int standard_input;
			int standard_output;
			int standard_error;

			Process.spawn_async_with_pipes (working_directory,command_args,spawn_env,
				SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
				null,	out child_pid,	out standard_input, out standard_output, out standard_error);

			// stdout:
			IOChannel output = new IOChannel.unix_new (standard_output);
			output.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
				return this.send_line (channel, condition);
			});

			// stderr:
			IOChannel error = new IOChannel.unix_new (standard_error);
			error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
				return this.send_line (channel, condition);
			});

			ChildWatch.add (child_pid, (pid, status) => {
				// Triggered when the child indicated by child_pid exits
				Process.close_pid (pid);
				this.set_buttons(true);
			});
		}

		private bool send_line(IOChannel channel, IOCondition condition) {
			if (condition == IOCondition.HUP) {
				return false;
			}

			try {
				string line;
				channel.read_line (out line, null, null);
				this.output_message_append(line);
			} catch (IOChannelError e) {
				stdout.printf ("IOChannelError: %s\n", e.message);
				return false;
			} catch (ConvertError e) {
				stdout.printf ("ConvertError: %s\n", e.message);
				return false;
			}

			return true;
		}

		/**
		 * This method refreshes a project
		 * @return True if it failed; False if it was refreshed
		 */

		private bool refresh_project_cb(bool send_action = true) {
			string[] msgs;

			this.output_message_clear();
			var retval=this.current_project.refresh(this.current_project_file);

			msgs = this.current_project.getErrors();
			this.output_message_append(_("Refreshing project file\n"));
			foreach(var msg in msgs) {
				this.output_message_append(msg+"\n");
			}
			if (send_action) {
				this.action_refresh_project(retval);
			}
			return (retval);
		}

		/**
		 * This method refreshes a project and updates the CMAKE files
		 * @return True if it failed; False if it worked fine
		 */

		private bool update_project_cb(bool send_action = true) {

			if (this.refresh_project_cb(false)) {
				return true;
			}

			var retval=this.current_project.cmake(this.current_project_file);
			var msgs = this.current_project.getErrors();
			this.output_message_append(_("Updating CMake files\n"));
			foreach(var msg in msgs) {
				this.output_message_append(msg+"\n");
			}

			if (send_action) {
				this.action_update_project(retval);
			}
			return (retval);
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
				this.set_buttons(false);
			} else {
				this.set_buttons(true);
			}
		}

		private void set_buttons(bool mode) {

			this.refresh_project.sensitive=mode;
			this.update_project.sensitive=mode;
			this.update_translations.sensitive=mode;
			this.build_project.sensitive=mode;
			this.full_build_project.sensitive=mode;
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
