using Gtk;
using Gdk;
using Gee;

namespace AutovalaPlugin {

	public enum ProjectSearchTypes { VALA_SEARCH, VALA_ENTRY_FOUND }

	/**
	 * This is a GTK3 widget that allows to show the result of a search in
	 * all the files in a project.
	 * This widget needs a ProjectView widget in order to work.
	 */
	public class SearchView : Gtk.Box {

		private Gtk.TreeView treeView;
		private TreeStore treeModel;
		private Gtk.CellRendererText renderer;
		private Gtk.Entry entry;
		private Gtk.Button searchButton;
		
		private string? current_project_file;
		private Gee.List<path_element> path_list;
		
		public signal void open_file(string path, int line);
		
		public SearchView() {

			this.path_list = new Gee.ArrayList<path_element>();

			this.orientation = Gtk.Orientation.VERTICAL;
			var content = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
			this.current_project_file = null;

			var label = new Gtk.Label(_("Global search:"));
			this.entry = new Gtk.Entry();
			this.searchButton = new Gtk.Button.with_label(_("Search"));
			this.searchButton.clicked.connect(this.do_search);
			this.entry.activate.connect(this.do_search);
			content.pack_start(label,false,true);
			content.pack_start(this.entry,true,true);
			content.pack_start(this.searchButton,false,true);

			this.treeView = new Gtk.TreeView();

			/*
			 * string: visible text (with markup)
			 * string: path to open when clicking (or NULL if it doesn't open a file)
			 * Int: line
			 * ProjectSearchTypes: type of the entry
			 */
			this.treeModel = new TreeStore(4,typeof(string),typeof(string),typeof(int),typeof(ProjectSearchTypes));
			this.treeView.set_model(this.treeModel);
			var column = new Gtk.TreeViewColumn();
			this.renderer = new Gtk.CellRendererText();
			column.pack_start(this.renderer,false);
			column.add_attribute(this.renderer,"markup",0);
			this.treeView.append_column(column);

			this.treeView.activate_on_single_click = true;
			this.treeView.headers_visible = false;
			this.treeView.get_selection().mode = SelectionMode.SINGLE;
			this.treeView.row_activated.connect(this.clicked);
			
			var scroll = new Gtk.ScrolledWindow(null,null);
			scroll.add(this.treeView);

			this.pack_start(content,false,true);
			this.pack_start(scroll,true,true);
			this.show_all();
		}

		/**
		 * Click event callback for the "classic" left button
		 * @param path The path of the clicked element
		 * @param column The column of the clicked element
		 */

		private void clicked(TreePath path, TreeViewColumn column) {
			TreeModel model;
			TreeIter iter;

			var selection = this.treeView.get_selection();
			if (!selection.get_selected(out model, out iter)) {
				return;
			}

			string filepath;
			int line;
			model.get(iter,1,out filepath,2,out line,-1);
			if(filepath==null) {
				return;
			}

			this.open_file(filepath,line);
		}

		/**
		 * This method allows to indicate to the widget which file is being edited by the user.
		 * The widget uses this to search for an Autovala project file associated to that file,
		 * @param file The full path of the current file
		 */
		public void set_current_project_file(string? file) {

			this.current_project_file = file;
			if (file == null) {
				this.searchButton.sensitive = false;
			} else {
				this.searchButton.sensitive = true;
			}
		}

		/**
		 * Callback for the SEARCH button
		 */
		public void do_search() {

			TreeIter? elementIter = null;
			TreeIter? elementBaseIter = null;

			this.treeModel.clear();
			string search_line = this.entry.text;
			bool put_filename;
			int line_count;
			int occurrences;

			foreach(var file_element in this.path_list) {
				put_filename = false;
				var file = File.new_for_path (file_element.file_path);
				if (!file.query_exists ()) {
					continue;
				}
				try {
					var dis = new DataInputStream (file.read ());
					string line;
					line_count = 0;
					occurrences = 0;
					while ((line = dis.read_line (null)) != null) {
						if (line.contains(search_line)) {
							occurrences++;
							if (!put_filename) {
								put_filename = true;
								this.treeModel.append(out elementBaseIter,null);
							}
							this.treeModel.append(out elementIter,elementBaseIter);
							this.treeModel.set(elementIter,0,"    "+_("Found element at line %d").printf(line_count+1),1,file_element.file_path,2,line_count,3,ProjectSearchTypes.VALA_ENTRY_FOUND,-1);
						}
						line_count++;
					}
					if (put_filename) {
						this.treeModel.set(elementBaseIter,0,_("Search result for file %s: found %d occurrences").printf(file_element.file_name,occurrences),1,file_element.file_path,2,0,3,ProjectSearchTypes.VALA_SEARCH,-1);
					}
				} catch (Error e) {
					continue;
				}
			}
			this.treeView.expand_all();
		}

		public void del_source_files() {
			this.path_list.clear();
		}
		
		public void append_source(string file_name, string file_path) {
			var element = new path_element(file_name,file_path);
			this.path_list.add(element);
		}

	}

	private class path_element : GLib.Object {
	
		public string file_name;
		public string file_path;

		public path_element(string name,string path) {
			this.file_name = name;
			this.file_path = path;
		}

	}

}
