using Gtk;
using Gdk;
using Gee;

namespace AutovalaPlugin {

	/**
	 * This is a GTK3 widget that allows to show all the files and folders
	 * starting in a specific folder, in an hierarchical fashion
	 * It is useful to create plugins for GTK3-based editors
	 * The first plugins are for GEdit and Scratch
	 * This widget complements the ProjectViewer widget
	 */

	public class FileViewer : Gtk.TreeView {

		private TreeStore treeModel;
		private Gee.ArrayList<FileMonitor> monitors;
		private Gtk.CellRendererText renderer;
		private string? current_file;
		private string? current_folder;
		private bool show_hiden;
		private FileViewerMenu folder_menu;
		private Gee.ArrayList<string> open_folders;
		TreeIter[] elements_to_expand;

		/**
		 * This signal is emited when the user clicks on a file
		 */
		public signal void clicked_file(string path);

		/**
		 * This signal is emited when a file or folder has been created or
		 * deleted in the file tree
		 */
		public signal void changed_file();

		/**
		 * Constructor
		 */
		public FileViewer() {

			Intl.bindtextdomain(AutoValaConstants.GETTEXT_PACKAGE, Path.build_filename(AutoValaConstants.DATADIR,"locale"));

			this.monitors = new Gee.ArrayList<FileMonitor>();
			this.current_file = null;
			this.current_folder = null;
			this.show_hiden = false;
			this.folder_menu = null;
			this.open_folders = new Gee.ArrayList<string>();

			/*
			 * string: visible text (with markup)
			 * string: path to open when clicking
			 * bool: if TRUE, this entry is editable; if FALSE, it is not
			 * string: named icon
			 * bool: if TRUE, is a file (this is, openable); if FALSE, is a folder (not openable)
			 */
			this.treeModel = new TreeStore(5,typeof(string),typeof(string),typeof(bool),typeof(string),typeof(bool));
			this.set_model(this.treeModel);
			var column = new Gtk.TreeViewColumn();
			this.renderer = new Gtk.CellRendererText();
			var pixbuf = new Gtk.CellRendererPixbuf();
			column.pack_start(pixbuf,false);
			column.add_attribute(pixbuf,"icon_name",3);
			column.pack_start(this.renderer,false);
			column.add_attribute(this.renderer,"markup",0);
			column.add_attribute(this.renderer,"editable",2);
			this.append_column(column);

			this.activate_on_single_click = true;
			this.headers_visible = false;
			this.get_selection().mode = SelectionMode.SINGLE;

			this.renderer.edited.connect(this.cell_edited);
			this.row_activated.connect(this.clicked);
			this.button_press_event.connect(this.click_event);
			this.row_expanded.connect((iter, path) => {
				string filepath;
				this.treeModel.get(iter,1,out filepath,-1);
				if(!this.open_folders.contains(filepath)) {
					this.open_folders.add(filepath);
				}
			});
			this.row_collapsed.connect((iter, path) => {
				string filepath;
				this.treeModel.get(iter,1,out filepath,-1);
				if(this.open_folders.contains(filepath)) {
					this.open_folders.remove(filepath);
				}
			});
		}

		/**
		 * This method must be called each time the user changes the current file.
		 * Is important to know which is the current file, because GEdit do some weird things
		 * when saving, which launches filesystem events.
		 * @param file The full path to the current file being edited
		 */
		public void set_current_file(string? file) {
			this.current_file = file;
		}

		/**
		 * Sets the base folder that will be shown in this file view
		 * @param folder The top folder
		 */
		public void set_base_folder(string? folder) {

			if (folder == null) {
				this.open_folders.clear();
				this.current_folder = null;
				this.treeModel.clear();
				this.folder_menu = null;
			} else {
				if (this.current_folder != folder) {
					this.open_folders.clear();
					this.current_folder = folder;
					this.fill_files(folder,null);
				}
			}
		}

		/**
		 * This callback is called whenever a cell is edited, which happens when a file is
		 * renamed. It do the renaming process.
		 * @param path The TreeView path of the edited cell
		 * @param new_name The new value of the cell
		 */
		public void cell_edited(string path, string new_name) {
			TreeIter iter;
			if (new_name == "") {
				return;
			}
			if (!this.treeModel.get_iter_from_string(out iter,path)) {
				return;
			}
			string old_file;
			this.treeModel.get(iter,1,out old_file,-1);
			var new_file = Path.build_filename(Path.get_dirname(old_file),new_name);
			// there is no change
			if (old_file == new_file) {
				return;
			}
			var file = File.new_for_path(old_file);
			var opFile = File.new_for_path(new_file);
			try {
				file.move(opFile,FileCopyFlags.NONE);
			} catch (GLib.Error e) {
			}
		}

		/**
		 * This callback is used for detecting the right-click, for the contextual menu.
		 * @param event The mouse event
		 * @return true to stop processing the event; false to continue processing the event.
		 */
		public bool click_event(EventButton event) {
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

					string? element_path;
					bool is_file;
					this.treeModel.get(iter,1,out element_path,4,out is_file,-1);
					this.folder_menu = new FileViewerMenu(element_path, is_file, this.show_hiden, this, this.treeModel,iter);
					this.folder_menu.set_hiden.connect(this.changed_hide_status);
					this.folder_menu.open.connect( (file_path) => {
						this.clicked_file (file_path);
					});
					this.folder_menu.popup(null,null,null,event.button,event.time);
					this.folder_menu.show_all();
					return false;
				}
			}
			return false;
		}

		/**
		 * This callback is called when the user changes the hiden files visibility with the contextual menu
		 * @param new_status If true, the hiden files will be visible; if false, they won't
		 */
		public void changed_hide_status(bool new_status) {

			if (new_status != this.show_hiden) {
				this.show_hiden = new_status;
				this.fill_files(this.current_folder);
			}
		}

		/**
		 * This callback manages the classic click over an element
		 * @param path The path of the clicked element
		 * @param column The column of the clicked element
		 */
		public void clicked(TreePath path, TreeViewColumn column) {
			TreeModel model;
			TreeIter iter;

			var selection = this.get_selection();
			if (!selection.get_selected(out model, out iter)) {
				return;
			}

			string filepath;
			bool is_file;
			model.get(iter,1,out filepath,4,out is_file,-1);
			if(!is_file) {
				return;
			}

			this.clicked_file(filepath);
		}

		/**
		 * Removes all the current file monitors
		 */
		private void cancel_monitors() {
			foreach(var mon in this.monitors) {
				mon.cancel();
			}
			this.monitors = new Gee.ArrayList<FileMonitor>();
		}

		/**
		 * This callback is called by the file monitors whenever a file in the filesystem
		 * has been modified
		 * @param file The file that has been modified
		 * @param other_file
		 * @param event_type The event that happened (created, deleted...)
		 */
		public void folder_changed (File file, File? other_file, FileMonitorEvent event_type) {

			if ((event_type!=FileMonitorEvent.CREATED) &&
				(event_type!=FileMonitorEvent.DELETED) &&
				(event_type!=FileMonitorEvent.MOVED)) {
				return;
			}

			var filename = file.get_basename();
			if((filename[0]=='.')&&(this.show_hiden==false)) {
				// don't check hiden files
				return;
			}

			// For some reason, a CREATE event is sent when we save the current file
			// But we don't need to refresh in that case, because the file is already there
			if((file.get_path()==this.current_file)&&(event_type==FileMonitorEvent.CREATED)) {
				return;
			}
			this.fill_files(this.current_folder,null);
			if(filename.has_suffix("~")) {
				// don't inform about backup files
				return;
			}
			this.changed_file();
		}

		/**
		 * This method reads all the files in a path and insert them in the TreeView.
		 * It also creates file monitors for each folder in the file tree.
		 * It is called recursively. First it reads and fills the folders, and then the files
		 *
		 * @param path The full path of the directory to read
		 * @param iter The parent iterator. The files and folders will be inserted inside it
		 * @param top If true, this is the top folder, so the TreeView will be cleared and the
		 * file monitors will be destroyed before starting. If false, it is being called recursively
		 */
		private void fill_files(string path, TreeIter? iter=null, bool top=true) {
			if (top) {
				this.cancel_monitors();
				this.treeModel.clear();
				this.folder_menu = null;
				this.elements_to_expand = {};
			}
			this.fill_files2(path,iter,true,top);
			this.fill_files2(path,iter,false,top);
			if (top) {
				foreach (var tmpIter in this.elements_to_expand) {
					this.expand_row(this.treeModel.get_path(tmpIter),false);
				}
			}
		}

		/**
		 * This method is the one that reads the files or folders in a folder
		 * and adds them inside the Iter specified
		 * @param path The full path of the folder to read
		 * @param parent The parent iterator. These files or folders will be inserted as childs of it
		 * @param folders If true, only the folders will be inserted; if false, only the regular files
		 * @param top If true, path is the top folder of our file tree; if false, means that the
		 * method is being called recursively
		 */
		private void fill_files2(string path,TreeIter? parent,bool folders,bool top) {

			FileType type;
			TreeIter tmpIter;
			FileEnumerator enumerator;
			FileInfo info_file;

			if(folders) {
				type = FileType.DIRECTORY;
			} else {
				type = FileType.REGULAR;
			}

			var directory = File.new_for_path(path);
			try {
				var monitor = directory.monitor(FileMonitorFlags.NONE, null);
				monitor.changed.connect(this.folder_changed);
				this.monitors.add(monitor);
			} catch (GLib.Error e) {
			}
			var fileList = new Gee.ArrayList<ElementFileViewer>();
			try {
				enumerator = directory.enumerate_children(GLib.FileAttribute.STANDARD_NAME+","+GLib.FileAttribute.STANDARD_TYPE,GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
				while ((info_file = enumerator.next_file(null)) != null) {

					var typeinfo=info_file.get_file_type();
					if (typeinfo!=type) {
						continue;
					}
					var filename=info_file.get_name();
					if((filename[0]=='.')&&(this.show_hiden==false)) {
						continue;
					}
					var full_path=Path.build_filename(path,filename);
					var element = new ElementFileViewer(filename,full_path);
					fileList.add(element);
				}
				// sort files alphabetically
				fileList.sort(FileViewer.CompareFiles);
				foreach (var element in fileList) {
					this.treeModel.append(out tmpIter,parent);
					if (folders) {
						this.treeModel.set(tmpIter,0,element.filename,1,element.fullPath,3,"folder",4,false,-1);
						if(this.open_folders.contains(element.fullPath)) {
							this.elements_to_expand+=tmpIter;
						}
						this.fill_files(element.fullPath,tmpIter,false);
					} else {
						this.treeModel.set(tmpIter,0,element.filename,1,element.fullPath,3,"text-x-generic",4,true,-1);
					}
				}
			} catch (Error e) {
				return;
			}
		}

		/**
		 * Compare function to sort the files, first by being hiden or not, then alphabetically
		 * @param a The first file to compare
		 * @param b The second file to compare
		 * @result wheter a must be before (-1), after (1) or no matter (0), b
		 */
		public static int CompareFiles(ElementFileViewer a, ElementFileViewer b) {

			if ((a.filename[0]=='.') && (b.filename[0]!='.')) {
				return -1;
			}
			if ((a.filename[0]!='.') && (b.filename[0]=='.')) {
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
	}

	/**
	 * Class used to store the data of one file
	 */
	public class ElementFileViewer : Object {

		public string filename;
		public string filename_casefold;
		public string fullPath;

		public ElementFileViewer(string fName, string fPath) {

			this.filename = fName;
			this.fullPath = fPath;
			this.filename_casefold = this.filename.casefold();
		}
	}

	/**
	 * This class manages the popup menu in the file view
	 */
	public class FileViewerMenu : Gtk.Menu {

		private TreeIter element;
		private TreeStore treeModel;
		private TreeView view;
		private string file_path;
		private bool is_file;
		private bool show_hiden;
		private Gtk.MenuItem action_open;
		private Gtk.MenuItem action_showhide;
		private Gtk.MenuItem action_new_file;
		private Gtk.MenuItem action_new_folder;
		private Gtk.MenuItem rename_file;
		private Gtk.MenuItem delete_file;

		public signal void set_hiden(bool new_hiden);
		public signal void open(string file);

		public FileViewerMenu(string path, bool is_file, bool show_hiden, TreeView view, TreeStore model, TreeIter element) {

			this.file_path = path;
			this.is_file = is_file;
			this.show_hiden = show_hiden;
			this.element = element;
			this.treeModel = model;
			this.view = view;

			this.action_open = new Gtk.MenuItem.with_label(_("Open"));
			this.action_showhide = new Gtk.MenuItem.with_label(show_hiden ? _("Don't show hiden files") : _("Show hiden files"));
			this.rename_file = new Gtk.MenuItem.with_label(_("Rename"));
			this.delete_file = new Gtk.MenuItem.with_label(_("Delete"));
			this.action_new_file = new Gtk.MenuItem.with_label(_("Create file"));
			this.action_new_folder = new Gtk.MenuItem.with_label(_("Create folder"));

			if (is_file) {
				this.append(this.action_open);
				this.append(new Gtk.SeparatorMenuItem());
			}

			this.append(this.action_new_file);
			this.append(this.action_new_folder);
			this.append(new Gtk.SeparatorMenuItem());

			this.append(this.action_showhide);
			this.append(new Gtk.SeparatorMenuItem());
			this.append(this.rename_file);
			this.append(this.delete_file);

			this.action_open.activate.connect( () => {
				this.open(this.file_path);
			});
			this.action_showhide.activate.connect( () => {
				this.set_hiden(this.show_hiden ? false : true);
			});
			this.rename_file.activate.connect( () => {
				this.treeModel.set(this.element,2,true,-1);
				this.view.set_cursor(this.treeModel.get_path(this.element),this.view.get_column(0),true);
			});
			this.action_new_file.activate.connect( () => {
				string basepath;
				if (this.is_file) {
					basepath = Path.get_dirname(this.file_path);
				} else {
					basepath = this.file_path;
					this.view.expand_row(this.treeModel.get_path(this.element),false);
				}
				var file = File.new_for_path(Path.build_filename(basepath,_("Untitled file")));
				try{
					file.create(FileCreateFlags.NONE);
				} catch (GLib.Error e) {
				}
			});
			this.action_new_folder.activate.connect( () => {
				string basepath;
				if (this.is_file) {
					basepath = Path.get_dirname(this.file_path);
				} else {
					basepath = this.file_path;
					this.view.expand_row(this.treeModel.get_path(this.element),false);
				}
				var folder = File.new_for_path(Path.build_filename(basepath,_("Untitled folder")));
				try {
					folder.make_directory();
				} catch (GLib.Error e) {
				}
			});
			this.delete_file.activate.connect( () => {
				var file = File.new_for_path(this.file_path);
				try {
					file.delete();
				} catch (GLib.Error e) {
				}
			});
		}
	}
}
