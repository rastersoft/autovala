using Gtk;
using Gdk;
using Peas;
using AutoVala;
using Gee;
using AutovalaPlugin;
using Scratch;

public const string NAME = N_("Autovala Project Manager");
public const string DESCRIPTION = N_("Manages Autovala projecs from Scratch");

namespace autovalascratch {
    
    public class AutovalaScratchPlugin : Peas.ExtensionBase, Peas.Activatable {

        public Scratch.Services.Interface plugins;
        
        private Box main_container=null;
		private AutovalaPlugin.FileViewer fileViewer;
		private AutovalaPlugin.ProjectViewer projectViewer;
		private AutovalaPlugin.ActionButtons actionButtons;
        private AutovalaPlugin.PanedPercentage container=null;
        private AutovalaPlugin.OutputView outputView;
		private AutovalaPlugin.SearchView searchView;
		
		private int go_to_line;

        public Object object { owned get; construct; }

        public AutovalaScratchPlugin () {
        }

		/*
		 * For some reason I don't understand, the constructor of objects in Peas plugins aren't called, but
		 * instead this "construct" element...
		 */
        construct {
            message ("Starting Autovala Plugin");
			Intl.bindtextdomain(autovalascratchConstants.GETTEXT_PACKAGE, Path.build_filename(autovalascratchConstants.DATADIR,"locale"));
			this.main_container = null;
			this.outputView = null;
			this.projectViewer = null;
			this.go_to_line = -1;
		}

        public void activate () {
            plugins = (Scratch.Services.Interface) object;
            plugins.hook_notebook_sidebar.connect (on_hook_sidebar);
            plugins.hook_document.connect (on_hook_document);
            plugins.hook_notebook_bottom.connect (on_hook_bottombar);
        }

        public void deactivate () {
            if (this.container != null) {
                container.destroy();
            }
        }

        public void update_state () {
        }

		void on_hook_document (Scratch.Services.Document doc) {

			string ? current_file;

			if (doc.file==null) {
				current_file = null;
			} else {
	            current_file = doc.file.get_parse_name();
	        }
			this.fileViewer.set_current_file(current_file);
			this.projectViewer.set_current_file(current_file);
			if (this.go_to_line != -1) {
				doc.source_view.go_to_line(this.go_to_line);
				this.go_to_line = -1;
			}
        }

		void on_hook_bottombar (Gtk.Notebook notebook) {
			if (this.outputView != null) {
				return;
			}
			this.outputView = new AutovalaPlugin.OutputView();
			
			this.searchView = new AutovalaPlugin.SearchView();
			this.searchView.open_file.connect(this.file_line_selected);
			
			if(this.projectViewer != null) {
				this.projectViewer.link_output_view(this.outputView);
				this.projectViewer.link_search_view(this.searchView);
			}
			notebook.append_page (this.outputView, new Gtk.Label (_("Autovala output")));
			notebook.append_page (this.searchView, new Gtk.Label (_("Autovala search")));
		}

        void on_hook_sidebar (Gtk.Notebook notebook) {
			if (this.main_container != null) {
				return;
			}
			
			this.main_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			this.main_container.spacing = 1;
			
			this.fileViewer = new FileViewer();
			this.fileViewer.clicked_file.connect(this.file_selected);

			this.projectViewer = new ProjectViewer();
			this.projectViewer.clicked_file.connect(this.file_selected);

			this.actionButtons = new ActionButtons();
			this.actionButtons.open_file.connect(this.file_selected);

			this.projectViewer.link_file_view(this.fileViewer);
			this.projectViewer.link_action_buttons(this.actionButtons);

			if (this.outputView != null) {
				this.projectViewer.link_output_view(this.outputView);
				this.projectViewer.link_search_view(this.searchView);
			}

			this.fileViewer.set_current_file(null);
			this.projectViewer.set_current_file(null);			

			var scroll1 = new Gtk.ScrolledWindow(null,null);
			scroll1.add(this.projectViewer);
			var scroll2 = new Gtk.ScrolledWindow(null,null);
			scroll2.add(this.fileViewer);

			this.container = new AutovalaPlugin.PanedPercentage(Gtk.Orientation.VERTICAL,0.5);
			this.container.border_width = 2;

			this.container.add1(scroll1);
			this.container.add2(scroll2);
			this.update_state();

			this.main_container.pack_start(this.actionButtons,false,true);
			this.main_container.pack_start(new Gtk.Separator (Gtk.Orientation.HORIZONTAL),false,true);
			this.main_container.pack_start(this.container,true,true);
			this.main_container.show_all();

            notebook.append_page (this.main_container, new Gtk.Label (_("Autovala Project")));
        }

        /**
		 * This callback is called whenever the user clicks on a file, both
		 * in the Project View, or in the File View
		 * @param filepath The file (with full path) clicked by the user
		 */
		public void file_selected(string filepath) {
			var file = GLib.File.new_for_path (filepath);
            plugins.open_file (file);
		}

		/**
		 * This callback is called whenever the user clicks on a file in the
		 * global search panel
		 * @param filepath The file (with full path) clicked by the user
		 * @param line The line to which move the cursor
		 */
		public void file_line_selected(string filepath, int line) {
			this.go_to_line = line;
			var file = GLib.File.new_for_path (filepath);
            plugins.open_file (file);
		}
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
  var objmodule = module as Peas.ObjectModule;
  objmodule.register_extension_type (typeof (Peas.Activatable), typeof (autovalascratch.AutovalaScratchPlugin));
}

