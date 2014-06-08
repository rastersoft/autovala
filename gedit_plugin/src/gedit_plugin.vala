using Gtk;
using Gdk;
using Gedit;
using Peas;
using AutoVala;
using Gee;
using AutovalaPlugin;

using Gtk.SourceUtils;

namespace autovalagedit {

	public class ValaWindow : Gedit.WindowActivatable, Peas.ExtensionBase {

		private AutovalaPlugin.FileViewer fileViewer;
		private AutovalaPlugin.ProjectViewer projectViewer;
		private AutovalaPlugin.ActionButtons actionButtons;
		private AutovalaPlugin.PanedPercentage container;
		private AutovalaPlugin.OutputView outputView;
		private AutovalaPlugin.SearchView searchView;
		private Box main_container;

		public ValaWindow() {
			GLib.Object ();
		}

		public Gedit.Window window {
			 owned get; construct;
		}

		construct {
			Intl.bindtextdomain(autovalageditConstants.GETTEXT_PACKAGE, Path.build_filename(autovalageditConstants.DATADIR,"locale"));
			this.container = null;
			this.main_container = null;
		}

		public void activate () {

			Gtk.Image icon = null;
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

			this.outputView = new AutovalaPlugin.OutputView();
			
			this.searchView = new AutovalaPlugin.SearchView();
			this.searchView.open_file.connect(this.file_line_selected);

			this.projectViewer.link_file_view(this.fileViewer);
			this.projectViewer.link_action_buttons(this.actionButtons);
			this.projectViewer.link_output_view(this.outputView);
			this.projectViewer.link_search_view(this.searchView);

			var scroll1 = new Gtk.ScrolledWindow(null,null);
			scroll1.add(this.projectViewer);
			var scroll2 = new Gtk.ScrolledWindow(null,null);
			scroll2.add(this.fileViewer);

			this.container = new AutovalaPlugin.PanedPercentage(Gtk.Orientation.VERTICAL,0.5);

			this.container.add1(scroll1);
			this.container.add2(scroll2);

			this.main_container.pack_start(this.actionButtons,false,true);
			this.main_container.pack_start(new Gtk.Separator (Gtk.Orientation.HORIZONTAL),false,true);
			this.main_container.pack_start(this.container,true,true);
			
			// the icon "autovala_plugin_vala" is added inside ProjectViewer
			icon = new Gtk.Image.from_icon_name("autovala-plugin-vala",Gtk.IconSize.MENU);
#if OLD_GEDIT
			Gedit.Panel panel = (Gedit.Panel)this.window.get_side_panel();
			panel.add_item(this.main_container, "Autovala", "Autovala", icon);

			Gedit.Panel bpanel = (Gedit.Panel)this.window.get_bottom_panel();
			bpanel.add_item(this.outputView, _("Autovala output"), _("Autovala output"), null);
			bpanel.add_item(this.searchView, _("Autovala search"), _("Autovala search"), null);
#else
			Gtk.Stack panel = (Gtk.Stack)this.window.get_side_panel();
			panel.add_titled(this.main_container, "Autovala", "Autovala");

			Gtk.Stack bpanel = (Gtk.Stack)this.window.get_bottom_panel();
			bpanel.add_titled(this.outputView, _("Autovala output"), _("Autovala output"));
			bpanel.add_titled(this.searchView, _("Autovala search"), _("Autovala search"));
#endif
			this.update_state();
			this.main_container.show_all();

		}

		public void deactivate () {
			if (this.main_container == null) {
				return;
			}

#if OLD_GEDIT
			Gedit.Panel panel = (Gedit.Panel)this.window.get_side_panel();
			panel.remove_item(this.main_container);
			Gedit.Panel bpanel = (Gedit.Panel)this.window.get_bottom_panel();
			bpanel.remove_item(this.outputView);
#else
			//Gtk.Stack panel = (Gtk.Stack)this.window.get_side_panel();
			this.main_container.dispose();
			//Gtk.Stack bpanel = (Gtk.Stack)this.window.get_bottom_panel();
			this.outputView.dispose;
			this.searchView.dispose;
#endif
			this.main_container = null;
			this.outputView = null;
			this.searchView = null;
		}

		public void update_state() {

			var current_tab = this.window.get_active_tab();

			if ((current_tab == null) || (current_tab.get_document() == null) || (current_tab.get_document().location == null) || (current_tab.get_document().location.get_path()==null)) {
				// if there is no file open, just empty everything
				this.fileViewer.set_base_folder(null);
				this.fileViewer.set_current_file(null);
				this.projectViewer.set_current_file(null);
				return;
			}

			var current_file = current_tab.get_document().location.get_path();
			this.fileViewer.set_current_file(current_file);
			this.projectViewer.set_current_file(current_file);
		}


		/**
		 * This callback is called whenever the user clicks on a file, both
		 * in the Project View, or in the File View
		 * @param filepath The file (with full path) clicked by the user
		 */
		public void file_selected(string filepath) {
			this.goto_file_line(filepath,0);
		}

		/**
		 * This callback is called whenever the user clicks on a file in the search
		 * @param filepath The file (with full path) clicked by the user
		 * @param line The line to which the cursor must be moved
		 */
		public void file_line_selected(string filepath, int line) {
			this.goto_file_line(filepath,line);
	
		}

		private void goto_file_line(string filepath, int line) {

			var file = File.new_for_path(filepath);
			if (file==null) {
				return;
			}
			var tab = this.window.get_tab_from_location(file);
			if (tab == null) {
				this.window.create_tab_from_location(file, null, line+1,0,false,true);
			} else {
				this.window.set_active_tab(tab);
			}
			if (tab != null) {
				var document = tab.get_document();
				document.goto_line(line);
				var view = tab.get_view();
				view.scroll_to_cursor();
			}
		}

	}
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
	var objmodule = module as Peas.ObjectModule;

	// Register my plugin extension
	objmodule.register_extension_type (typeof (Gedit.WindowActivatable), typeof (autovalagedit.ValaWindow));
}
