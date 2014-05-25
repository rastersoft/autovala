using Gtk;
using Gdk;
using Gedit;
using Peas;
using AutoVala;
using Gee;
using AutovalaPlugin;

namespace AutovalaGeditPlugin {

	public class ValaWindow : Gedit.WindowActivatable, Peas.ExtensionBase {

		private string current_file=null;
		private string current_project_file=null;
		private AutovalaPlugin.FileViewer fileViewer;
		private AutovalaPlugin.ProjectViewer projectViewer;
		private Paned container;
		private bool set_size;
		private int current_paned_position;
		private int current_paned_size;
		private double desired_paned_percentage;
		private bool changed_paned_size;

		public ValaWindow() {
			GLib.Object ();
		}

		public Gedit.Window window {
			 owned get; construct;
		}

		construct {
			Intl.bindtextdomain(AutovalaPluginConstants.GETTEXT_PACKAGE, Path.build_filename(AutovalaPluginConstants.DATADIR,"locale"));
			this.current_file = null;
			this.current_project_file = null;
			this.container = null;
			this.current_paned_position = -1;
			this.current_paned_size = -1;
			this.desired_paned_percentage = 0.5;
			this.changed_paned_size = false;
		}

		public void activate () {

			Gtk.Image icon = null;
			if (this.container != null) {
				return;
			}
			this.set_size = false;

			this.fileViewer = new FileViewer();
			this.fileViewer.clicked_file.connect(this.file_selected);

			this.projectViewer = new ProjectViewer();
			this.projectViewer.clicked_file.connect(this.file_selected);

			this.projectViewer.link_file_view(this.fileViewer);

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
			// the icon "autovala_plugin_vala" is added inside ProjectViewer
			icon = new Gtk.Image.from_icon_name("autovala-plugin-vala",Gtk.IconSize.MENU);
#if OLD_GEDIT
			var panel = this.window.get_side_panel();
			panel.add_item(this.container, "Autovala", "Autovala", icon);
#else
			var panel = (Gtk.Stack)this.window.get_side_panel();
			panel.add_titled(this.container, "Autovala", "Autovala");
#endif
			this.update_state();
			this.container.show_all();
		}

		public void deactivate () {
			if (this.container == null) {
				return;
			}

#if OLD_GEDIT
			var panel = this.window.get_side_panel();
			panel.remove_item(this.container);
#else
			this.container.unparent();
#endif
			this.container = null;
			this.projectViewer = null;
			this.fileViewer = null;
		}

		public void update_state() {

			var current_tab = this.window.get_active_tab();

			if ((current_tab == null) || (current_tab.get_document() == null) || (current_tab.get_document().location == null) || (current_tab.get_document().location.get_path()==null)) {
				// if there is no file open, just empty everything
				this.current_file = null;
				this.fileViewer.set_base_folder(null);
				this.fileViewer.set_current_file(null);
				this.projectViewer.set_current_file(null);
				return;
			}

			this.current_file = current_tab.get_document().location.get_path();
			this.fileViewer.set_current_file(this.current_file);
			this.projectViewer.set_current_file(this.current_file);
		}


		/**
		 * This callback is called whenever the user clicks on a file, both
		 * in the Project View, or in the File View
		 * @param filepath The file (with full path) clicked by the user
		 */
		public void file_selected(string filepath) {

			var file = File.new_for_path(filepath);
			if (file==null) {
				return;
			}
			var tab = this.window.get_tab_from_location(file);
			if (tab == null) {
				this.window.create_tab_from_location(file, null, 0,0,false,true);
			} else {
				this.window.set_active_tab(tab);
			}
		}
	}
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
	var objmodule = module as Peas.ObjectModule;

	// Register my plugin extension
	objmodule.register_extension_type (typeof (Gedit.WindowActivatable), typeof (AutovalaGeditPlugin.ValaWindow));
}
