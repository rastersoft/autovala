using Gtk;
using Gdk;
using Gee;
using AutoVala;

// project version=0.97

namespace AutovalaPlugin {

	public enum ProjectEntryTypes { OTHER, VALA_SOURCE_FILE, VAPI_FILE, C_SOURCE_FILE, C_HEADER_FILE, LIBRARY, EXECUTABLE, PROJECT_FILE }

	public class ProjectViewer : Gtk.TreeView {

		private TreeStore treeModel;
		private Gtk.CellRendererText renderer;
		private string current_file;
		private string current_project_file;
		private AutoVala.ManageProject current_project;
		private ProjectViewerMenu menu;
		private ProjectProperties properties;

		/**
		 * This signal is emited when the user clicks on a file
		 * @param path The full path to the file clicked by the user
		 */
		public signal void clicked_file(string path);

		/**
		 * This signal is emited when the current project has changed
		 * @param path The full path to the project's base folder
		 */
		public signal void changed_base_folder(string? path);

		/**
		 * Constructor
		 */
		public ProjectViewer() {

			this.current_project = new AutoVala.ManageProject();
			this.current_project_file = null;
			this.current_file = null;
			this.menu = null;

			try {
				Gdk.Pixbuf pixbuf;
				pixbuf = new Gdk.Pixbuf.from_file_at_size(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","application.svg"),-1,-1);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-executable",-1,pixbuf);
				pixbuf = new Gdk.Pixbuf.from_file_at_size(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","c.svg"),-1,-1);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-c",-1,pixbuf);
				pixbuf = new Gdk.Pixbuf.from_file_at_size(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","h.svg"),-1,-1);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-h",-1,pixbuf);
				pixbuf = new Gdk.Pixbuf.from_file_at_size(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","library.svg"),-1,-1);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-library",-1,pixbuf);
				pixbuf = new Gdk.Pixbuf.from_file_at_size(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","project.svg"),-1,-1);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-project",-1,pixbuf);
				pixbuf = new Gdk.Pixbuf.from_file_at_size(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","vapi.svg"),-1,-1);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-vapi",-1,pixbuf);
				pixbuf = new Gdk.Pixbuf.from_file_at_size(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","vala.svg"),-1,-1);
				Gtk.IconTheme.add_builtin_icon("autovala-plugin-vala",-1,pixbuf);
			} catch (GLib.Error e) {}

			/*
			 * string: visible text (with markup)
			 * string: path to open when clicking (or NULL if it doesn't open a file)
			 * Pixbuf: icon to show
			 * string: binary/executable name to which it belongs
			 * ProjectEntryTypes: type of the entry
			 */
			this.treeModel = new TreeStore(5,typeof(string),typeof(string),typeof(string),typeof(string),typeof(ProjectEntryTypes));
			this.set_model(this.treeModel);
			var column = new Gtk.TreeViewColumn();
			this.renderer = new Gtk.CellRendererText();
			var pixbuf = new Gtk.CellRendererPixbuf();
			column.pack_start(pixbuf,false);
			column.add_attribute(pixbuf,"icon_name",2);
			column.pack_start(this.renderer,false);
			column.add_attribute(this.renderer,"markup",0);
			this.append_column(column);

			this.activate_on_single_click = true;
			this.headers_visible = false;
			this.get_selection().mode = SelectionMode.SINGLE;

			this.row_activated.connect(this.clicked);
			this.button_press_event.connect(this.click_event);
		}

		/**
		 * Click event callback, to detect when the user clicks with the right button
		 * @param event The mouse event
		 * @return true to stop processing the event; false to continue processing the event.
		 */
		private bool click_event(EventButton event) {

			if (event.button == 3) { // right click
				TreePath path;
				TreeViewColumn column;
				int x;
				int y;
				TreeIter iter;

				if (this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out x, out y)) {
					if (!this.treeModel.get_iter(out iter, path)) {
						return true;
					}

					string ?file_path;
					string ?binary_name;
					ProjectEntryTypes type;

					this.treeModel.get(iter,1,out file_path,3,out binary_name,4,out type,-1);
					this.menu = new ProjectViewerMenu(this.current_project_file,file_path, binary_name,type);
					this.menu.open.connect( (file_path) => {
						this.clicked_file (file_path);
					});
					this.menu.update_project.connect( () => {
						var retval=this.current_project.refresh(this.current_project_file);
						this.current_project.showErrors();
						if (!retval) {
							retval=this.current_project.cmake(this.current_project_file);
							this.current_project.showErrors();
						}
					});
					this.menu.update_gettext.connect( () => {
						this.current_project.gettext(this.current_project_file);
						this.current_project.showErrors();
					});
					this.menu.new_binary.connect( () => {
						if (this.properties != null) {
							return;
						}
						this.properties = new ProjectProperties(null,this.current_project_file, this.current_project);
						this.properties.run();
						this.properties.destroy();
						this.properties = null;
					});
					this.menu.edit_binary.connect( (binary_name2) => {
						if (this.properties != null) {
							return;
						}
						this.properties = new ProjectProperties(binary_name2,this.current_project_file, this.current_project);
						this.properties.run();
						this.properties.destroy();
						this.properties = null;
					});
					this.menu.remove_binary.connect( (binary_name2) => {
						this.current_project.remove_binary(this.current_project_file,binary_name2);
					});
					this.menu.popup(null,null,null,event.button,event.time);
					this.menu.show_all();
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
			TreeIter iter;

			var selection = this.get_selection();
			if (!selection.get_selected(out model, out iter)) {
				return;
			}

			string filepath;
			model.get(iter,1,out filepath,-1);
			if(filepath==null) {
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
		public void set_current_file(string? file) {

			if (file == null) {
				this.treeModel.clear();
				this.current_project_file = null;
				this.current_file = null;
				this.changed_base_folder(null);
				return;
			}

			// If the file is the same, do nothing
			if (file == this.current_file) {
				return;
			}

			// If the new file is in the same path than the old one, do nothing
			if ((this.current_file != null) && (Path.get_dirname(file) == Path.get_dirname(this.current_file))) {
				return;
			}

			this.current_file = file;
			this.refresh_project(false);
		}

		/**
		 * This method refreshes the project view
		 * @param force If false, will refresh the project only if the project file has changed; if true, will refresh always
		 */
		public void refresh_project(bool force) {

			var project = this.current_project.get_binaries_list(this.current_file);

			if (project==null) {
				this.treeModel.clear();
				this.menu = null;
				this.current_project_file = null;
				this.changed_base_folder(null);
			} else if ((this.current_project_file==null) || (this.current_project_file!=project.projectFile) || force) {
				this.treeModel.clear();
				this.menu = null;
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
		private void fill_vala_files(bool first, string path,Gee.ArrayList<string> ignorePaths, ValaProject project,Gee.ArrayList<ElementProjectViewer> fileList) {

			FileEnumerator enumerator;
			FileInfo info_file;

			if (!first && (ignorePaths.contains(path))) {
				return;
			}

			var directory = File.new_for_path(path);
			try {
				enumerator = directory.enumerate_children(GLib.FileAttribute.STANDARD_NAME+","+GLib.FileAttribute.STANDARD_TYPE,GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
				while ((info_file = enumerator.next_file(null)) != null) {
					var typeinfo=info_file.get_file_type();
					var filename=info_file.get_name();
					if (typeinfo==FileType.DIRECTORY) {
						var newPath=Path.build_filename(path,filename);
						this.fill_vala_files(false,newPath,ignorePaths,project,fileList);
						continue;
					}
					if (typeinfo!=FileType.REGULAR) {
						continue;
					}
					// hiden files must not be added
					if (filename[0]=='.') {
						continue;
					}
					// neither the backup files
					if (filename.has_suffix("~")) {
						continue;
					}
					var fElements = filename.split(".");
					var extension=fElements[fElements.length-1].casefold();
					var full_path=Path.build_filename(path,filename);
					var new_element = new ElementProjectViewer(filename,full_path,extension);
					if (new_element.type == ProjectEntryTypes.OTHER) {
						continue;
					}

					fileList.add(new_element);
				}
			} catch (Error e) {
				return;
			}
		}

		/**
		 * Compare function to sort the files, first by extension, then alphabetically
		 * @param a The first file to compare
		 * @param b The second file to compare
		 * @result wheter a must be before (-1), after (1) or no matter (0), b
		 */
		public static int CompareFiles(ElementProjectViewer a, ElementProjectViewer b) {

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
		 * Adds the files 
		 */
		private void add_files(TreeIter tmpIter,Gee.ArrayList<ElementProjectViewer> fileList, AutoVala.PublicElement? element) {

			string? pixbuf = null;
			TreeIter? elementIter = null;

			// sort files alphabetically
			fileList.sort(ProjectViewer.CompareFiles);
			foreach (var item in fileList) {
				switch (item.type) {
				case ProjectEntryTypes.VALA_SOURCE_FILE:
					pixbuf = "autovala-plugin-vala";
				break;
				case ProjectEntryTypes.VAPI_FILE:
					pixbuf = "autovala-plugin-vapi";
				break;
				case ProjectEntryTypes.C_SOURCE_FILE:
					pixbuf = "autovala-plugin-c";
				break;
				case ProjectEntryTypes.C_HEADER_FILE:
					pixbuf = "autovala-plugin-h";
				break;
				default:
					pixbuf = "text-x-generic";
				break;
				}
				this.treeModel.append(out elementIter,tmpIter);
				this.treeModel.set(elementIter,0,item.filename,1,item.fullPath,2,pixbuf,3,element.name,4,element.type,-1);
			}
		}

		private void set_current_project(ValaProject? project) {

			Gee.ArrayList<ElementProjectViewer> fileList = null;
			TreeIter? fileIter = null;
			TreeIter? tmpIter = null;

			this.current_project_file=project.projectFile;
			
			if (project.projectFile == null) {
				return;
			}
			
			var ignorePaths = new Gee.ArrayList<string>();
			var list = project.elements;

			this.treeModel.append(out tmpIter,null);
			this.treeModel.set(tmpIter,0,_("%s <b>(Project file)</b>").printf(GLib.Path.get_basename(project.projectFile)),1,project.projectFile,2,"autovala-plugin-project",4,ProjectEntryTypes.PROJECT_FILE,-1);

			foreach(var element in list) {
				ignorePaths.add(Path.build_filename(project.projectPath,element.fullPath));
			}

			foreach(var element in list) {
				tmpIter = null;
				switch (element.type) {
				case ConfigType.VALA_BINARY:
					fileList = new Gee.ArrayList<ElementProjectViewer>();
					this.treeModel.append(out tmpIter,null);
					this.treeModel.set(tmpIter,0,_("%s <b>(executable)</b>").printf(element.name),2,"autovala-plugin-executable",3,element.name,4,ProjectEntryTypes.EXECUTABLE,-1);
					this.fill_vala_files(true,Path.build_filename(project.projectPath,element.fullPath),ignorePaths,project,fileList);
					this.add_files(tmpIter,fileList,element);
					break;
				case ConfigType.VALA_LIBRARY:
					fileList = new Gee.ArrayList<ElementProjectViewer>();
					this.treeModel.append(out tmpIter,null);
					this.treeModel.set(tmpIter,0,_("%s <b>(library)</b>").printf(element.name),2,"autovala-plugin-library",3,element.name,4,ProjectEntryTypes.LIBRARY,-1);
					this.fill_vala_files(true,Path.build_filename(project.projectPath,element.fullPath),ignorePaths,project,fileList);
					this.add_files(tmpIter,fileList,element);
				break;
				}
			}
			this.treeModel.append(out fileIter,null);
			this.changed_base_folder(project.projectPath);
		}
	}

	public class ElementProjectViewer : Object {

		public string filename;
		public string filename_casefold;
		public string extension;
		public string fullPath;
		public ProjectEntryTypes type;

		public ElementProjectViewer(string fName, string fPath, string ext) {

			this.filename = fName;
			this.fullPath = fPath;
			this.extension = ext;
			this.filename_casefold = this.filename.casefold();

			if(ext == "vala".casefold()) {
				this.type = ProjectEntryTypes.VALA_SOURCE_FILE;
			} else if(ext == "vapi".casefold()) {
				this.type = ProjectEntryTypes.VAPI_FILE;
			} else if(ext == "c".casefold()) {
				this.type = ProjectEntryTypes.C_SOURCE_FILE;
			} else if(ext == "h".casefold()) {
				this.type = ProjectEntryTypes.C_HEADER_FILE;
			} else {
				this.type = ProjectEntryTypes.OTHER;
			}
		}
	}

	private class ProjectViewerMenu : Gtk.Menu {

		private string project_path;
		private string? file_path;
		private string binary_name;
		private ProjectEntryTypes type;
		private Gtk.MenuItem action_open;
		private Gtk.MenuItem action_new_binary;
		private Gtk.MenuItem action_edit_binary;
		private Gtk.MenuItem action_delete_binary;
		private Gtk.MenuItem action_update_project;
		private Gtk.MenuItem action_update_translations;

		public signal void open(string file);
		public signal void update_project();
		public signal void update_gettext();
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
			this.action_update_project = new Gtk.MenuItem.with_label(_("Update project"));
			this.action_update_translations = new Gtk.MenuItem.with_label(_("Update translations"));

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
			
			this.append(new Gtk.SeparatorMenuItem());
			this.append(this.action_update_project);
			this.append(this.action_update_translations);

			this.action_open.activate.connect( () => {
				this.open(this.file_path);
			});
			this.action_update_project.activate.connect( () => {
				this.update_project();
			});
			this.action_update_translations.activate.connect( () => {
				this.update_gettext();
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

	private class ProjectProperties : Object {

		private Gtk.Dialog main_window;
		private Gtk.Entry name;
		private Gtk.FileChooserButton path;
		private Gtk.RadioButton is_library;
		private Gtk.RadioButton is_executable;
		private AutoVala.ManageProject project;
		private Gtk.Entry vala_options;
		private Gtk.Entry c_options;
		private Gtk.Button accept_button;
		private Gtk.Label error_message;
		private string project_file;
		private string? binary_name;
		private bool editing;

		/**
		 * Creates a dialog to add a new binary to a project, or to modify a current one
		 *
		 * @param binary_name The name of the executable/library to edit, or null to create a new one
		 * @param project_file The full path to the current project file where to edit or create the binary
		 * @param project A project class
		 */
		public ProjectProperties(string? binary_name, string project_file, AutoVala.ManageProject project) {

			this.project = project;
			this.project_file = project_file;
			this.binary_name = binary_name;
			if (binary_name == null) {
				this.editing = false;
			} else {
				this.editing = true;
			}

			var builder = new Gtk.Builder();
			builder.set_translation_domain(AutovalaPluginConstants.GETTEXT_PACKAGE);
			builder.add_from_file(Path.build_filename(AutovalaPluginConstants.DATADIR,"autovala","binary_properties.ui"));
			this.main_window = (Gtk.Dialog) builder.get_object("binary_properties");
			this.name = (Gtk.Entry) builder.get_object("binary_name");
			this.path = (Gtk.FileChooserButton) builder.get_object("path");
			this.is_library = (Gtk.RadioButton) builder.get_object("is_library");
			this.is_executable = (Gtk.RadioButton) builder.get_object("is_executable");
			this.vala_options = (Gtk.Entry) builder.get_object("vala_compile_options");
			this.c_options = (Gtk.Entry) builder.get_object("c_compile_options");
			this.accept_button = (Gtk.Button) builder.get_object("button_accept");
			this.error_message = (Gtk.Label) builder.get_object("error_message");

			if(this.editing) {
				var project_data = project.get_binaries_list(project_file);
				if (project_data != null) {
					foreach(var element in project_data.elements) {
						if (((element.type == AutoVala.ConfigType.VALA_BINARY) || (element.type == AutoVala.ConfigType.VALA_LIBRARY)) && (element.name == binary_name)) {
							this.name.text = element.name;
							this.path.set_filename(Path.build_filename(project_data.projectPath,element.fullPath));
							if (element.type == AutoVala.ConfigType.VALA_BINARY) {
								this.is_executable.active = true;
							} else {
								this.is_library.active = true;
							}
							this.vala_options.text=element.vala_opts;
							this.c_options.text=element.c_opts;
						}
					}
				}
			} else {
				this.path.set_filename(Path.get_dirname(project_file));
			}
			this.main_window.show_all();
			builder.connect_signals(this);
			this.set_status();
		}

		public void run() {
			if (this.main_window == null) {
				return;
			}
			while(true) {
				var retval = this.main_window.run();
				if (retval != 2) {
					break;
				}
				var retMsg = this.project.process_binary(this.binary_name,this.project_file,this.name.text,this.is_library.active,this.path.get_filename(),this.vala_options.text,this.c_options.text);
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

		[CCode(instance_pos=-1)]
		public void name_changed(Gtk.Entry entry) {
			this.set_status();
		}

		[CCode(instance_pos=-1)]
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

