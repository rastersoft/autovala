using Gtk;
using Gdk;
using Gee;
using AutoVala;

// project version=0.99

namespace AutovalaPlugin {
	public enum ProjectEntryTypes { VALA_SOURCE_FILE, C_SOURCE_FILE, VAPI_FILE, C_HEADER_FILE, LIBRARY, EXECUTABLE, PROJECT_FILE, UNITEST, UNKNOWN, OTHER }

	/**
	 * This is a GTK3 widget that allows to manage an Autovala project
	 * It is useful to create plugins for GTK3-based editors
	 * The first plugins are for GEdit and Scratch
	 * This is the main widget. The other widgets (FileViewer, ActionButtons and
	 *  output_view widgets) are optional and complements this one.
	 */
	public class ProjectViewer : Gtk.TreeView {
		private TreeStore treeModel;
		private Gtk.CellRendererText renderer;

		private string ? current_file;
		private string current_project_file;
		private AutoVala.ManageProject current_project;
		private ProjectViewerMenu popupMenu;
		private ProjectProperties properties;

		private FileViewer ? fileViewer;
		private ActionButtons ? actionButtons;
		private OutputView ? output_view;
		private SearchView ? searchView;

		private CreateNewProject create_new_project;

		private string ? current_project_path;

		private bool running_command;
		private bool more_commands;
		private int current_status;

		/**
		 * This signal is emited when the user clicks on a file
		 * @param path The full path to the file clicked by the user
		 */
		public signal void clicked_file(string path);

		/**
		 * This signal is emited when the current project has changed
		 * @param path The full path to the project's base folder
		 */
		public signal void changed_base_folder(string ? path, string ? project_file);

		/**
		 * Constructor
		 */
		public ProjectViewer() {
			Intl.bindtextdomain(AutoValaConstants.GETTEXT_PACKAGE, Path.build_filename(AutoValaConstants.DATADIR, "locale"));

			this.current_project      = new AutoVala.ManageProject();
			this.current_project_file = null;
			this.current_project_path = null;
			this.current_file         = null;
			this.popupMenu            = null;
			this.fileViewer           = null;
			this.actionButtons        = null;
			this.output_view          = null;
			this.searchView           = null;
			this.create_new_project   = null;

			this.running_command = false;
			this.more_commands   = false;
			this.current_status  = 0;

			try {
				Gdk.Pixbuf pixbuf;
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/application.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-executable", -1, pixbuf);
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/c.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-c", -1, pixbuf);
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/h.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-h", -1, pixbuf);
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/library.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-library", -1, pixbuf);
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/project.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-project", -1, pixbuf);
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/vapi.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-vapi", -1, pixbuf);
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/vala.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-vala", -1, pixbuf);
				pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/test_vala.svg", -1, -1, false);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-unitestvala", -1, pixbuf);
			} catch (GLib.Error e) {}

			/*
			 * string: visible text (with markup)
			 * string: path to open when clicking (or NULL if it doesn't open a file)
			 * Pixbuf: icon to show
			 * string: binary/executable name to which it belongs
			 * ProjectEntryTypes: type of the entry
			 */
			this.treeModel = new TreeStore(5, typeof(string), typeof(string), typeof(string), typeof(string), typeof(ProjectEntryTypes));
			this.set_model(this.treeModel);
			var column = new Gtk.TreeViewColumn();
			this.renderer = new Gtk.CellRendererText();
			var pixbuf = new Gtk.CellRendererPixbuf();
			column.pack_start(pixbuf, false);
			column.add_attribute(pixbuf, "icon_name", 2);
			column.pack_start(this.renderer, false);
			column.add_attribute(this.renderer, "markup", 0);
			this.append_column(column);

			//this.activate_on_single_click = true;
			this.headers_visible      = false;
			this.get_selection().mode = SelectionMode.SINGLE;

			this.row_activated.connect(this.clicked);
			this.button_press_event.connect(this.click_event);
		}

		/**
		 * Links the signals and callbacks of this ProjectViewer and a FileViewer, to allow
		 * a ProjectViewer to know when a file has been added or removed in the project's folder,
		 * and to allow the FileViewer to change its root folder when the current project changes.
		 * @param fileViewer The FileViewer widget to link to this ProjectViewer
		 * @return true if all went fine; false if there was a FileViewer object already registered
		 */
		public bool link_file_view(FileViewer fileViewer) {
			if (this.fileViewer != null) {
				return false;
			}

			this.fileViewer = fileViewer;
			this.fileViewer.changed_file.connect(() => {
				this.refresh_project(true);
			});
			this.changed_base_folder.connect((path, project_file) => {
				this.fileViewer.set_base_folder(path);
			});

			return true;
		}

		/**
		 * Links the signals and callbacks of this ProjectViewer and an OutputView, to allow
		 * the OutputView to receive the texts from running a command
		 * @param output_view The OutputView widget to link to this ProjectViewer
		 * @return true if all went fine; false if there was an OutputView object already registered
		 */
		public bool link_output_view(OutputView output_view) {
			if (this.output_view != null) {
				return false;
			}

			this.output_view = output_view;
			this.output_view.ended_command.connect(this.program_ended);
			return true;
		}

		/**
		 * Links the signals and callbacks of this ProjectViewer and a SearchView
		 * @param searchView The SearchView widget to link to this ProjectViewer
		 * @return true if all went fine; false if there was a SearchView object already registered
		 */

		public bool link_search_view(SearchView searchView) {
			if (this.searchView != null) {
				return false;
			}

			this.searchView = searchView;
			this.changed_base_folder.connect((path, project_file) => {
				this.searchView.set_current_project_file(project_file);
			});
			return true;
		}

		/**
		 * Click event callback, to detect when the user clicks with the right button
		 * @param event The mouse event
		 * @return true to stop processing the event; false to continue processing the event.
		 */
		private bool click_event(EventButton event) {
			if (event.button == 3) {
				// right click
				TreePath       path;
				TreeViewColumn column;
				int            x;
				int            y;
				TreeIter       iter;

				if (this.get_path_at_pos((int) event.x, (int) event.y, out path, out column, out x, out y)) {
					if (!this.treeModel.get_iter(out iter, path)) {
						return false;
					}

					string ? file_path;
					string ? binary_name;
					ProjectEntryTypes type;

					this.treeModel.get(iter, 1, out file_path, 3, out binary_name, 4, out type, -1);
					this.popupMenu = new ProjectViewerMenu(this.current_project_file, file_path, binary_name, type);
					this.popupMenu.open.connect((file_path) => {
						this.clicked_file(file_path);
					});
					this.popupMenu.new_binary.connect(() => {
						if (this.properties != null) {
						    return;
						}
						this.properties = new ProjectProperties(null, this.current_project_file, this.current_project);
						this.properties.run();
						this.properties.destroy();
						this.properties = null;
					});
					this.popupMenu.edit_binary.connect((binary_name2) => {
						if (this.properties != null) {
						    return;
						}
						this.properties = new ProjectProperties(binary_name2, this.current_project_file, this.current_project);
						this.properties.run();
						this.properties.destroy();
						this.properties = null;
					});
					this.popupMenu.remove_binary.connect((binary_name2) => {
						this.current_project.remove_binary(this.current_project_file, binary_name2);
					});
					this.popupMenu.popup(null, null, null, event.button, event.time);
					this.popupMenu.show_all();
					return false;
				}
			}
			return false;
		}

		/**
		 * Click event callback for the "classic" left button
		 * @param path The path of the clicked element
		 * @param column The column of the clicked element
		 */

		private void clicked(TreePath path, TreeViewColumn column) {
			TreeModel model;
			TreeIter  iter;

			var selection = this.get_selection();
			if (!selection.get_selected(out model, out iter)) {
				return;
			}

			string filepath;
			model.get(iter, 1, out filepath, -1);
			if (filepath == null) {
				return;
			}

			this.clicked_file(filepath);
		}

		/**
		 * This method allows to indicate to the widget which file is being edited by the user.
		 * The widget uses this to search for an Autovala project file associated to that file,
		 * and update the project view.
		 * @param file The full path of the current file
		 */
		public void set_current_file(string ? file) {
			if (file == null) {
				this.treeModel.clear();
				this.current_project_file = null;
				this.current_file         = null;
				this.current_project_path = null;
				this.changed_base_folder(null, null);
				this.update_buttons();
				return;
			}

			// If the file is the same, do nothing
			if (file == this.current_file) {
				return;
			}

			// If the new file is in the same path than the old one, do nothing
			if ((this.current_file != null) && (Path.get_dirname(file) == Path.get_dirname(this.current_file))) {
				this.update_buttons();
				return;
			}

			this.current_file = file;
			this.refresh_project(false);
			this.update_buttons();

			var data = this.current_project.get_binaries_list(this.current_project_file);
			if (data == null) {
				this.current_project_path = null;
			} else {
				this.current_project_path = data.projectPath;
			}
		}

		/**
		 * This method refreshes the project view
		 * @param force If false, will refresh the project only if the project file has changed; if true, will refresh always
		 */
		public void refresh_project(bool force = true) {
			AutoVala.ValaProject ? project;
			if (this.current_file != null) {
				project = this.current_project.get_binaries_list(this.current_file);
			} else {
				project = null;
			}

			if (project == null) {
				if (this.searchView != null) {
					this.searchView.del_source_files();
				}
				this.treeModel.clear();
				this.popupMenu            = null;
				this.current_project_file = null;
				this.changed_base_folder(null, null);
				var errors = this.current_project.getErrors();
				foreach (var error in errors) {
					this.output_view.append_text(error);
				}
			} else if ((this.current_project_file == null) || (this.current_project_file != project.projectFile) || force) {
				if (this.searchView != null) {
					this.searchView.del_source_files();
				}
				this.treeModel.clear();
				this.popupMenu = null;
				this.set_current_project(project);
				this.set_model(this.treeModel);
				this.expand_all();
			}
		}

		/**
		 * Reads all the files in a folder and its childs. Is a recursive method.
		 * @param first If true, the path is the top_level folder, so it won't be checked aginst ignorePaths; if false, is a child
		 * @param path The path to read
		 * @param ignorePaths Contains a list of paths to ignore when traversing recursively. The top level folder is never checked, so it will be read even if is in this list
		 * @param project An Autovala project object
		 * @param fileList A list where all the files will be stored
		 */
		private void fill_vala_files(PublicBinary element, string path, ValaProject project, Gee.ArrayList<ElementProjectViewer> fileList) {
			if ((element.type != ConfigType.VALA_BINARY) && (element.type != ConfigType.VALA_LIBRARY)) {
				return;
			}
			//OTHER, VALA_SOURCE_FILE, VAPI_FILE, C_SOURCE_FILE, C_HEADER_FILE, LIBRARY, EXECUTABLE, PROJECT_FILE
			foreach (var file in element.sources) {
				var fElements   = file.elementName.split(".");
				var extension   = fElements[fElements.length - 1].casefold();
				var full_path   = Path.build_filename(path, file.elementName);
				var new_element = new ElementProjectViewer(GLib.Path.get_basename(file.elementName), full_path, extension, ProjectEntryTypes.VALA_SOURCE_FILE);
				fileList.add(new_element);
			}
			foreach (var file in element.c_sources) {
				var fElements   = file.elementName.split(".");
				var extension   = fElements[fElements.length - 1].casefold();
				var full_path   = Path.build_filename(path, file.elementName);
				var new_element = new ElementProjectViewer(GLib.Path.get_basename(file.elementName), full_path, extension, ProjectEntryTypes.C_SOURCE_FILE);
				fileList.add(new_element);
			}
			foreach (var file in element.unitests) {
				var fElements   = file.elementName.split(".");
				var extension   = fElements[fElements.length - 1].casefold();
				var full_path   = Path.build_filename(path, file.elementName);
				var new_element = new ElementProjectViewer(GLib.Path.get_basename(file.elementName), full_path, extension, ProjectEntryTypes.UNITEST);
				fileList.add(new_element);
			}
			foreach (var file in element.vapis) {
				var fElements   = file.elementName.split(".");
				var extension   = fElements[fElements.length - 1].casefold();
				var full_path   = Path.build_filename(path, file.elementName);
				var new_element = new ElementProjectViewer(GLib.Path.get_basename(file.elementName), full_path, extension, ProjectEntryTypes.VAPI_FILE);
				fileList.add(new_element);
			}
		}

		/**
		 * Compare function to sort the files, first by extension, then alphabetically
		 * @param a The first file to compare
		 * @param b The second file to compare
		 * @result wheter a must be before (-1), after (1) or no matter (0), b
		 */
		public static int CompareFiles(ElementProjectViewer a, ElementProjectViewer b) {
			if (a.type < b.type) {
				return -1;
			}

			if (a.type > b.type) {
				return 1;
			}

			if (a.extension < b.extension) {
				return -1;
			}
			if (a.extension > b.extension) {
				return 1;
			}

			if (a.filename_casefold < b.filename_casefold) {
				return -1;
			}
			if (a.filename_casefold > b.filename_casefold) {
				return 1;
			}
			return 0;
		}

		/**
		 * Adds the files to a binary (executable or library)
		 * @param tmpIter The parent iter into which to add the files
		 * @param fileList The list of files to add
		 * @param element The data of the parent binary element
		 */
		private void add_files(TreeIter tmpIter, Gee.ArrayList<ElementProjectViewer> fileList, AutoVala.PublicBinary ? element) {
			string ? pixbuf        = null;
			TreeIter ? elementIter = null;

			// sort files alphabetically
			fileList.sort(ProjectViewer.CompareFiles);
			foreach (var item in fileList) {
				switch (item.type) {
				case ProjectEntryTypes.VALA_SOURCE_FILE:
					pixbuf = "autovala-plugin-vala";
					if (this.searchView != null) {
						this.searchView.append_source(item.filename, item.fullPath);
					}
					break;

				case ProjectEntryTypes.VAPI_FILE:
					pixbuf = "autovala-plugin-vapi";
					if (this.searchView != null) {
						this.searchView.append_source(item.filename, item.fullPath);
					}
					break;

				case ProjectEntryTypes.C_SOURCE_FILE:
					pixbuf = "autovala-plugin-c";
					if (this.searchView != null) {
						this.searchView.append_source(item.filename, item.fullPath);
					}
					break;

				case ProjectEntryTypes.UNITEST:
					pixbuf = "autovala-plugin-unitestvala";
					if (this.searchView != null) {
						this.searchView.append_source(item.filename, item.fullPath);
					}
					break;

				default:
					pixbuf = "text-x-generic";
					break;
				}
				this.treeModel.append(out elementIter, tmpIter);
				this.treeModel.set(elementIter, 0, item.filename, 1, item.fullPath, 2, pixbuf, 3, element.name, 4, element.type, -1);
			}
		}

		/**
		 * Refreshes the view, adding each top element
		 * @param project A ValaProject object already initializated
		 */
		private void set_current_project(ValaProject ? project) {
			Gee.ArrayList<ElementProjectViewer> fileList = null;
			TreeIter ? fileIter = null;
			TreeIter ? tmpIter  = null;

			this.current_project_file = project.projectFile;

			if (project.projectFile == null) {
				return;
			}

			var ignorePaths = new Gee.ArrayList<string>();
			var list        = project.binaries;

			this.treeModel.append(out tmpIter, null);
			this.treeModel.set(tmpIter, 0, _("%s <b>(Project file)</b>").printf(GLib.Path.get_basename(project.projectFile)), 1, project.projectFile, 2, "autovala-plugin-project", 4, ProjectEntryTypes.PROJECT_FILE, -1);

			foreach (var element in list) {
				if (element.fullPath != null) {
					ignorePaths.add(Path.build_filename(project.projectPath, element.fullPath));
				}
			}

			foreach (var element in list) {
				tmpIter = null;
				switch (element.type) {
				case ConfigType.VALA_BINARY:
					fileList = new Gee.ArrayList<ElementProjectViewer>();
					this.treeModel.append(out tmpIter, null);
					this.treeModel.set(tmpIter, 0, _("%s <b>(executable)</b>").printf(element.name), 2, "autovala-plugin-executable", 3, element.name, 4, ProjectEntryTypes.EXECUTABLE, -1);
					this.fill_vala_files(element, Path.build_filename(project.projectPath, element.fullPath), project, fileList);
					this.add_files(tmpIter, fileList, element);
					break;

				case ConfigType.VALA_LIBRARY:
					fileList = new Gee.ArrayList<ElementProjectViewer>();
					this.treeModel.append(out tmpIter, null);
					this.treeModel.set(tmpIter, 0, _("%s <b>(library)</b>").printf(element.name), 2, "autovala-plugin-library", 3, element.name, 4, ProjectEntryTypes.LIBRARY, -1);
					this.fill_vala_files(element, Path.build_filename(project.projectPath, element.fullPath), project, fileList);
					this.add_files(tmpIter, fileList, element);
					break;
				}
			}
			this.treeModel.append(out fileIter, null);
			this.changed_base_folder(project.projectPath, this.current_project_file);
		}

		/**
		 * Clears the output view if there is one assigned
		 */
		private void output_view_clear_buffer() {
			if (this.output_view != null) {
				this.output_view.clear_buffer();
			}
		}

		/**
		 * Appends some text to the output view, if it exists
		 * @param text The text to append
		 */
		private void output_view_append_text(string text) {
			if (this.output_view != null) {
				this.output_view.append_text(text);
			}
		}

		/**
		 * Links the signals and callbacks of this ProjectViewer and an ActionButtons, to allow
		 * a ProjectViewer to know when the user asked to create a new project, update the current one...
		 * and to allow the ActionButtons to change its status
		 * @param actionButtons The ActionButtons widget to link to this ProjectViewer
		 * @return true if all went fine; false if there was an ActionButtons object already registered
		 */
		public bool link_action_buttons(ActionButtons actionButtons) {
			if (this.actionButtons != null) {
				return false;
			}

			this.actionButtons = actionButtons;

			actionButtons.action_new_project.connect(() => {
				string ? project_name;
				string ? project_path;

				if (this.create_new_project != null) {
				    return;
				}

				this.current_project    = new AutoVala.ManageProject();
				this.create_new_project = new CreateNewProject(this.current_project);
				if (this.create_new_project.run(out project_name, out project_path)) {
				    this.current_project.refresh(Path.build_filename(project_path, project_name + ".avprj"));
				    var base_name = Path.build_filename(project_path, "src", project_name + ".vala");
				    this.clicked_file(base_name);
				    this.output_view_clear_buffer();
				}
				this.create_new_project.destroy();
				this.create_new_project = null;
				this.refresh_project(true);
			});

			actionButtons.action_refresh_project.connect(() => {
				this.current_project = new AutoVala.ManageProject();
				if (this.refresh_project_func()) {
				    this.output_view_append_text(_("Aborting\n"));
				} else {
				    this.output_view_append_text(_("Done\n"));
				}
			});

			actionButtons.action_update_project.connect(() => {
				this.current_project = new AutoVala.ManageProject();
				if (this.update_project_func()) {
				    this.output_view_append_text(_("Aborting\n"));
				} else {
				    this.output_view_append_text(_("Done\n"));
				}
			});

			actionButtons.action_build.connect(() => {
				this.output_view_clear_buffer();
				if (this.current_project_path == null) {
				    this.update_buttons();
				    return;
				}
				this.current_project = new AutoVala.ManageProject();
				this.build_func();
			});

			actionButtons.action_full_build.connect(() => {
				this.output_view_clear_buffer();
				if (this.current_project_path == null) {
				    this.update_buttons();
				    return;
				}
				this.current_project = new AutoVala.ManageProject();
				this.full_build_func(true);
			});

			actionButtons.action_update_gettext.connect(() => {
				this.output_view_clear_buffer();
				this.current_project = new AutoVala.ManageProject();
				var retval = this.current_project.gettext(this.current_project_file);
				var msgs   = this.current_project.getErrors();
				foreach (var msg in msgs) {
				    this.output_view_append_text(msg + "\n");
				}
			});

			this.update_buttons();
			return true;
		}

		/**
		 * This method refreshes a project
		 * @return True if it failed; False if it was refreshed
		 */

		private bool refresh_project_func(bool send_action = true) {
			string[] msgs;

			this.output_view_clear_buffer();
			var retval = this.current_project.refresh(this.current_project_file);

			msgs = this.current_project.getErrors();
			this.output_view_append_text(_("Refreshing project file\n"));
			foreach (var msg in msgs) {
				this.output_view_append_text(msg + "\n");
			}
			if (send_action) {
				this.refresh_project(true);
			}
			return (retval);
		}

		/**
		 * This method refreshes a project and updates the CMAKE files
		 * @return True if it failed; False if it worked fine
		 */

		private bool update_project_func(bool send_action = true) {
			if (this.refresh_project_func(false)) {
				return true;
			}
			var retval = this.current_project.cmake(this.current_project_file);
			var msgs   = this.current_project.getErrors();
			this.output_view_append_text(_("Updating CMake files\n"));
			foreach (var msg in msgs) {
				this.output_view_append_text(msg + "\n");
			}

			if (send_action) {
				this.refresh_project(true);
			}
			return (retval);
		}

		private bool build_func(bool clear = true) {
			if (this.current_project_path == null) {
				return true;
			}

			var install_path = GLib.Path.build_filename(this.current_project_path, "install");

			var install_file = GLib.File.new_for_path(install_path);
			if (false == install_file.query_exists()) {
				install_file.make_directory();
			}

			var makefile = GLib.File.new_for_path(GLib.Path.build_filename(install_path, "Makefile"));
			if (false == makefile.query_exists()) {
				return this.full_build_func(false);
			}

			string[] command = { "make" };
			this.more_commands = false;
			this.launch_program(install_path, command, clear);

			return false;
		}

		private bool full_build_func(bool clear = true) {
			if (this.update_project_func(false)) {
				this.output_view_append_text(_("Aborting\n"));
				return true;
			}

			this.more_commands  = true;
			this.current_status = 0;

			var install_path = GLib.Path.build_filename(this.current_project_path, "install");
			var install_file = GLib.File.new_for_path(install_path);
			if (false == install_file.query_exists()) {
				install_file.make_directory();
			}

			if (this.delete_recursive(install_path, false)) {
				this.output_view_append_text(_("Aborting\n"));
				return true;
			}

			string[] command = { "cmake", ".." };
			this.more_commands = true;
			this.launch_program(install_path, command, clear);
			return false;
		}

		private bool delete_recursive(string fileFolder, bool delete_this) {
			var src = File.new_for_path(fileFolder);

			GLib.FileType srcType = src.query_file_type(GLib.FileQueryInfoFlags.NONE, null);
			if (srcType == GLib.FileType.DIRECTORY) {
				string srcPath = src.get_path();
				try {
					GLib.FileEnumerator enumerator = src.enumerate_children(GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, null);
					for (GLib.FileInfo ? info = enumerator.next_file(null); info != null; info = enumerator.next_file(null)) {
						if (delete_recursive(GLib.Path.build_filename(srcPath, info.get_name()), true)) {
							return true;
						}
					}
				} catch (Error e) {
					this.output_view_append_text(_("Failed when deleting recursively the folder %s").printf(fileFolder));
					return true;
				}
			}
			if (delete_this) {
				try {
					src.delete();
				} catch (Error e) {
					if (srcType != GLib.FileType.DIRECTORY) {
						this.output_view_append_text(_("Failed when deleting the file %s").printf(fileFolder));
					}
					return true;
				}
			}
			return false;
		}

		private void launch_program(string working_directory, string[] command_args, bool clear) {
			this.running_command = true;
			this.update_buttons();
			if (this.output_view != null) {
				var retval = this.output_view.run_command(command_args, working_directory, clear);
				if (retval == -1) {
					this.running_command = false;
					this.update_buttons();
				}
				return;
			}

			string[] spawn_env = Environ.get();
			Pid      child_pid;
			Process.spawn_async(working_directory, command_args, spawn_env, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid);
			ChildWatch.add(child_pid, (pid, status) => {
				Process.close_pid(pid);
				this.program_ended(pid, status);
			});
		}

		public void program_ended(int pid, int retval) {
			this.running_command = false;
			if (retval != 0) {
				this.output_view_append_text(_("Aborting\n"));
			} else {
				if (this.more_commands) {
					var install_path = GLib.Path.build_filename(this.current_project_path, "install");
					switch (this.current_status) {
					case 0 :
						string[] command = { "make" };
						this.more_commands = false;
						this.launch_program(install_path, command, false);
						break;

					default:
						this.more_commands = false;
						this.update_buttons();
						break;
					}
					this.current_status++;
					return;
				} else {
					this.output_view_append_text(_("Done\n"));
				}
			}
			this.update_buttons();
		}

		private void update_buttons() {
			uint32 mode = 0;

			mode |= ButtonNames.NEW;
			if (this.current_project_file != null) {
				mode |= ButtonNames.REFRESH;
				mode |= ButtonNames.UPDATE;
				mode |= ButtonNames.BUILD;
				mode |= ButtonNames.FULL_BUILD;
				mode |= ButtonNames.PO;
			}
			if (this.running_command) {
				mode |= ButtonNames.REFRESH;
				mode |= ButtonNames.UPDATE;
				mode |= ButtonNames.BUILD;
				mode |= ButtonNames.FULL_BUILD;
				mode |= ButtonNames.PO;
			}

			if (this.actionButtons != null) {
				this.actionButtons.update_buttons(mode);
			}
		}
	}

	/**
	 * Class used to store the data for one file
	 */
	public class ElementProjectViewer : Object {
		public string filename;
		public string filename_casefold;
		public string extension;
		public string fullPath;
		public ProjectEntryTypes type;

		public ElementProjectViewer(string fName, string fPath, string ext, ProjectEntryTypes type) {
			this.filename          = fName;
			this.fullPath          = fPath;
			this.extension         = ext;
			this.filename_casefold = this.filename.casefold();

			if (type == ProjectEntryTypes.UNKNOWN) {
				if (ext == "vala".casefold()) {
					this.type = ProjectEntryTypes.VALA_SOURCE_FILE;
				} else if (ext == "vapi".casefold()) {
					this.type = ProjectEntryTypes.VAPI_FILE;
				} else if (ext == "c".casefold()) {
					this.type = ProjectEntryTypes.C_SOURCE_FILE;
				} else if (ext == "h".casefold()) {
					this.type = ProjectEntryTypes.C_HEADER_FILE;
				} else {
					this.type = ProjectEntryTypes.OTHER;
				}
			} else {
				this.type = type;
			}
		}
	}
}
