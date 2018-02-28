using Gtk;
using Gdk;
using Gee;
using AutoVala;
//using GIO
namespace AutovalaPlugin {
	enum ButtonNames { NEW = 1, REFRESH = 2, UPDATE = 4, BUILD = 8, FULL_BUILD = 16, PO = 32 }

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

		/**
		 * This signal is emited when a new project has been created
		 * @param path The full path to the default source file
		 */
		public signal void open_file(string path);

		public signal void action_new_project();
		public signal void action_refresh_project();
		public signal void action_update_project();
		public signal void action_update_gettext();
		public signal void action_build();
		public signal void action_full_build();

		public ActionButtons() {
			int iconsize   = 30;
			int sep_margin = 2;

			Gdk.Pixbuf pixbuf;
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/build.svg", iconsize, iconsize, false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-build", -1, pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/full_build.svg", iconsize, iconsize, false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-full-build", -1, pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/refresh.svg", iconsize, iconsize, false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-refresh", -1, pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/refresh_langs.svg", iconsize, iconsize, false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-refresh-langs", -1, pixbuf);
			pixbuf = new Gdk.Pixbuf.from_resource_at_scale("/com/rastersoft/autovala/pixmaps/update.svg", iconsize, iconsize, false);
			Gtk.IconTheme.add_builtin_icon("autovala-plugin-update", -1, pixbuf);

			this.orientation = Gtk.Orientation.HORIZONTAL;

			this.new_project = new Gtk.Button.from_icon_name("document-new", Gtk.IconSize.LARGE_TOOLBAR);
			this.new_project.tooltip_text = _("Creates a new Autovala project");
			this.pack_start(this.new_project, false, false);

			var sep1 = new Gtk.Separator(Gtk.Orientation.VERTICAL);
			sep1.margin_start = sep_margin;
			sep1.margin_end   = sep_margin;

			this.pack_start(sep1, false, false);

			this.refresh_project = new Gtk.Button.from_icon_name("autovala-plugin-refresh", Gtk.IconSize.LARGE_TOOLBAR);
			this.refresh_project.tooltip_text = _("Refreshes the Autovala project");
			this.pack_start(this.refresh_project, false, false);

			this.update_project = new Gtk.Button.from_icon_name("autovala-plugin-update", Gtk.IconSize.LARGE_TOOLBAR);
			this.update_project.tooltip_text = _("Updates the project and rebuilds the CMake files");
			this.pack_start(this.update_project, false, false);

			this.build_project = new Gtk.Button.from_icon_name("autovala-plugin-build", Gtk.IconSize.LARGE_TOOLBAR);
			this.build_project.tooltip_text = _("Builds the Autovala project");
			this.pack_start(this.build_project, false, false);

			this.full_build_project = new Gtk.Button.from_icon_name("autovala-plugin-full-build", Gtk.IconSize.LARGE_TOOLBAR);
			this.full_build_project.tooltip_text = _("Builds the Autovala project");
			this.pack_start(this.full_build_project, false, false);

			sep1 = new Gtk.Separator(Gtk.Orientation.VERTICAL);
			sep1.margin_start = sep_margin;
			sep1.margin_end   = sep_margin;

			this.pack_start(sep1, false, false);

			this.update_translations = new Gtk.Button.from_icon_name("autovala-plugin-refresh-langs", Gtk.IconSize.LARGE_TOOLBAR);
			this.update_translations.tooltip_text = _("Updates the language translation files");
			this.pack_start(this.update_translations, false, false);

			this.new_project.clicked.connect(() => {
				this.action_new_project();
			});

			this.refresh_project.clicked.connect(() => {
				this.action_refresh_project();
			});

			this.update_project.clicked.connect(() => {
				this.action_update_project();
			});

			this.update_translations.clicked.connect(() => {
				this.action_update_gettext();
			});

			this.build_project.clicked.connect(() => {
				this.action_build();
			});

			this.full_build_project.clicked.connect(() => {
				this.action_full_build();
			});

			this.show_all();
		}

		public void update_buttons(uint32 mode) {
			this.new_project.sensitive         = ((mode & ButtonNames.NEW) == 0) ? false : true;
			this.refresh_project.sensitive     = ((mode & ButtonNames.REFRESH) == 0) ? false : true;
			this.update_project.sensitive      = ((mode & ButtonNames.UPDATE) == 0) ? false : true;
			this.update_translations.sensitive = ((mode & ButtonNames.PO) == 0) ? false : true;
			this.build_project.sensitive       = ((mode & ButtonNames.BUILD) == 0) ? false : true;
			this.full_build_project.sensitive  = ((mode & ButtonNames.FULL_BUILD) == 0) ? false : true;
		}
	}
}
