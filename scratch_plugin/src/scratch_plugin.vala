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
        
        private Paned container=null;
        private Box main_container=null;
		private int current_paned_position;
		private int current_paned_size;
		private double desired_paned_percentage;
		private bool changed_paned_size;
		private AutovalaPlugin.FileViewer fileViewer;
		private AutovalaPlugin.ProjectViewer projectViewer;
		private AutovalaPlugin.ActionButtons actionButtons;

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
			this.current_paned_position = -1;
			this.current_paned_size = -1;
			this.desired_paned_percentage = 0.5;
			this.changed_paned_size = false;
		}

        public void activate () {
            plugins = (Scratch.Services.Interface) object;
            plugins.hook_notebook_sidebar.connect (on_hook_sidebar);
            plugins.hook_document.connect (on_hook_document);
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
        }

        void on_hook_sidebar (Gtk.Notebook notebook) {
			if (this.main_container != null) {
				return;
			}
			
			this.main_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			
			this.fileViewer = new FileViewer();
			this.fileViewer.clicked_file.connect(this.file_selected);

			this.projectViewer = new ProjectViewer();
			this.projectViewer.clicked_file.connect(this.file_selected);

			this.actionButtons = new ActionButtons();
			this.actionButtons.open_file.connect(this.file_selected);

			this.projectViewer.link_file_view(this.fileViewer);
			this.projectViewer.link_action_buttons(this.actionButtons);

			this.fileViewer.set_current_file(null);
			this.projectViewer.set_current_file(null);

			var scroll1 = new Gtk.ScrolledWindow(null,null);
			scroll1.add(this.projectViewer);
			var scroll2 = new Gtk.ScrolledWindow(null,null);
			scroll2.add(this.fileViewer);

			this.container = new Gtk.Paned(Gtk.Orientation.VERTICAL);

			/*
			 * This is a trick to ensure that the paned remains with the same relative
			 * position, no mater if the user resizes the window
			 */
			 
			this.container.size_allocate.connect_after((allocation) => {

				if (this.current_paned_size != allocation.height) {
					this.current_paned_size = allocation.height;
					this.changed_paned_size = true;
				}
			});

			this.container.draw.connect((cr) => {

				if (changed_paned_size) {
					this.current_paned_position=(int)(this.current_paned_size*this.desired_paned_percentage);
					this.container.set_position(this.current_paned_position);
					this.changed_paned_size = false;
				} else {
					if (this.container.position != this.current_paned_position) {
						this.current_paned_position = this.container.position;
						this.desired_paned_percentage = ((double)this.current_paned_position)/((double)this.current_paned_size);
					}
				}
				return false;
			});

			this.container.add1(scroll1);
			this.container.add2(scroll2);
			this.update_state();

			this.main_container.pack_start(this.actionButtons,false,true);
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
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
  var objmodule = module as Peas.ObjectModule;
  objmodule.register_extension_type (typeof (Peas.Activatable), typeof (autovalascratch.AutovalaScratchPlugin));
}

