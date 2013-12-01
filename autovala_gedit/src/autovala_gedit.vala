/*
 Copyright 2013 (C) Raster Software Vigo (Sergio Costas)

 This file is part of AutoVala

 AutoVala is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.

 AutoVala is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>. */

using GLib;
using Gedit;
using Peas;
using Gee;
using Gtk;
using AutoVala;

// project version=0.27

namespace AutoVala_gedit {

	public class ask_to_continue: Object {

		private Gtk.Dialog main_w;

		public ask_to_continue() {
			Intl.bindtextdomain(AutoVala_geditConstants.GETTEXT_PACKAGE, Path.build_filename(AutoVala_geditConstants.DATADIR,"locale"));
			Intl.bind_textdomain_codeset(AutoVala_geditConstants.GETTEXT_PACKAGE, "utf-8" );
			var builder = new Builder();
			builder.add_from_file(GLib.Path.build_filename(AutoVala_geditConstants.PKGDATADIR,"ask_to_continue.ui"));
			this.main_w = (Gtk.Dialog) builder.get_object("dialog1");
			this.main_w.set_title(_("Delete 'install' folder"));
			var label=(Gtk.Label)builder.get_object("text_inside");
			label.set_text(_("All the content of the 'install' folder will be deleted. Continue?"));
		}

		public bool run() {
			this.main_w.show();
			var retval=this.main_w.run();
			this.main_w.hide();
			this.main_w.destroy();
			if (retval==2) {
				return true;
			} else {
				return false;
			}
		}
	}

	public class window : Gedit.WindowActivatable, Peas.ExtensionBase {

		private Gtk.Action action_menu_entry;
		private Gtk.Action action_open_project;
		private Gtk.Action action_update_project;
		private Gtk.Action action_cmake_project;
		private Gtk.Action action_build_project;
		private Gtk.Action action_makeclean_project;
		private Gtk.Action action_fullclean_project;
		private Gtk.Action action_fullbuild_project;
		private Gtk.ActionGroup _action_group;
		private uint ui_id;
		private string ?last_filename;
		private Gtk.TextView output;
		private Gtk.TextBuffer t_buffer;
		private Gtk.ScrolledWindow scrolled;
		private Gedit.Panel panel;

		public window () {
			GLib.Object ();
		}

		construct {

			this.action_menu_entry=new Gtk.Action("Autovala",_("Autovala"),null,null);

			this.action_open_project=new Gtk.Action("autovala_open",_("Open project file"),_("Opens the project file for the current source file"),null);
			this.action_open_project.activate.connect(this.open_project);

			this.action_update_project=new Gtk.Action("autovala_update",_("Update project"),_("Updates the .avprj project file and CMakeLists files"),null);
			this.action_update_project.activate.connect(this.update_project);

			this.action_cmake_project=new Gtk.Action("autovala_cmake",_("Run CMake"),_("Runs CMake to create the Makefile"),null);
			this.action_cmake_project.activate.connect(this.cmake_project);

			this.action_build_project=new Gtk.Action("autovala_build",_("Build project"),_("Builds the project running MAKE"),null);
			this.action_build_project.activate.connect(this.build_project);

			this.action_makeclean_project=new Gtk.Action("autovala_makeclean",_("Make clean"),_("Cleans the project folder with 'make clean'"),null);
			this.action_makeclean_project.activate.connect(this.makeclean_project);

			this.action_fullclean_project=new Gtk.Action("autovala_fullclean",_("Full clean"),_("Deletes the 'install' folder, to recreate the cmake system from scratch"),null);
			this.action_fullclean_project.activate.connect(this.fullclean_project);

			this.action_fullbuild_project=new Gtk.Action("autovala_fullbuild",_("Full build"),_("Deletes the 'install' folder, updates the Autovala .avprj project file, runs cmake and launches make for a full build"),null);
			this.action_fullbuild_project.activate.connect(this.fullbuild_project);

			this._action_group=new Gtk.ActionGroup("AutoVala");
			this._action_group.add_action(this.action_menu_entry);
			this._action_group.add_action(this.action_open_project);
			this._action_group.add_action(this.action_update_project);
			this._action_group.add_action(this.action_cmake_project);
			this._action_group.add_action(this.action_build_project);
			this._action_group.add_action(this.action_makeclean_project);
			this._action_group.add_action(this.action_fullclean_project);
			this._action_group.add_action(this.action_fullbuild_project);
		}

		public Gedit.Window window {
			owned get; construct;
		}

		private void clear_text() {
			this.t_buffer=new Gtk.TextBuffer(null);
			this.output.set_buffer(this.t_buffer);
		}

		private void insert_text(string text,bool add_cr,bool add_date=true) {
			time_t datetime;
			time_t(out datetime);
			if (add_date) {
				var localtime=GLib.Time.local(datetime);
				this.t_buffer.insert_at_cursor("[%02d:%02d:%02d] ".printf(localtime.hour,localtime.minute,localtime.second),-1);
			}
			if (add_cr) {
				this.t_buffer.insert_at_cursor(text+"\n",-1);
			} else {
				this.t_buffer.insert_at_cursor(text,-1);
			}
			var vadj=this.scrolled.vadjustment;
			vadj.value=vadj.upper;
		}

		private void show_errors(string[] error_list) {
			foreach(var e in error_list) {
				this.insert_text(e,true);
			}
		}

		private bool process_line(IOChannel channel, IOCondition condition, string stream_name) {
			if (condition == IOCondition.HUP) {
					return false;
				}
				try {
					string line;
					channel.read_line (out line, null, null);
					insert_text(line,false);
				} catch (IOChannelError e) {
					stdout.printf ("%s: IOChannelError: %s\n", stream_name, e.message);
					return false;
				} catch (ConvertError e) {
					stdout.printf ("%s: ConvertError: %s\n", stream_name, e.message);
					return false;
				}
				return true;
		}

		public delegate void plugin_callback_func ();

		private void launch_child(string[] parameters,string working_path,plugin_callback_func callback=null) {
			string[] spawn_env = Environ.get ();
			Pid child_pid;

			int standard_input;
			int standard_output;
			int standard_error;
			string params2="";
			bool other=false;
			foreach(var l in parameters) {
				if (other) {
					params2+=" ";
				}
				other=true;
				params2+=l;
			}
			insert_text(_("Launching '%s' at folder '%s'\n").printf(params2,working_path),false,false);
			try {
				Process.spawn_async_with_pipes (working_path,
					parameters,
					spawn_env,
					SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
					null,
					out child_pid,
					out standard_input,
					out standard_output,
					out standard_error);
			} catch(SpawnError e) {
				insert_text(_("Failed\n"),false);
				return;
			}

			// stdout:
			IOChannel output = new IOChannel.unix_new (standard_output);
			output.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
				return process_line (channel, condition, "stdout");
			});

			// stderr:
			IOChannel error = new IOChannel.unix_new (standard_error);
			error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
				return process_line (channel, condition, "stderr");
			});

			ChildWatch.add (child_pid, (pid, status) => {
				// Triggered when the child indicated by child_pid exits
				Process.close_pid (pid);
				insert_text(_("Done (return value %d)\n".printf(status)),false);
				this.update_state2(true);
				if (callback!=null) {
					callback();
				}
			});
		}

		public void open_project(Gtk.Action action) {
			bool opened=false;
			var document=this.window.get_active_document();
			if (document!=null) {
				var openfile=document.get_location();
				if (openfile!=null) {
					var current_filename=openfile.get_path();
					var config=new AutoVala.configuration();
					bool retval=config.read_configuration(current_filename);
					if (retval==false) {
						foreach(var a_document in this.window.get_documents()) {
							var path=a_document.get_location();
							if (path.get_path()==config.config_path) {
								opened=true;
								break; // already opened
							}
						}
						File prj_file=File.new_for_path(config.config_path);
						if (opened==false) {
							this.window.create_tab_from_location (prj_file, null, 0, 0, false, true);
						} else {
							this.window.set_active_tab(this.window.get_tab_from_location(prj_file));
						}
					}
				}
			}
		}

		public void update_project(Gtk.Action action) {
			this.clear_text();
			this.update_project2();
		}

		private void update_project2() {
			bool opened=false;
			var document=this.window.get_active_document();
			if (document!=null) {
				var openfile=document.get_location();
				if (openfile!=null) {
					opened=true;
					var current_filename=openfile.get_path();
					var gen = new AutoVala.manage_project();
					this.clear_text();
					this.insert_text(_("Updating project and cmake files\n"),false);
					var retval=gen.refresh(current_filename);
					this.show_errors(gen.get_error_list());
					gen.clear_errors();
					if (retval) {
						this.insert_text(_("Aborting\n"),false);
					} else {
						this.insert_text(_("Updating CMake files\n"),false);
						retval=gen.cmake(current_filename);
						this.show_errors(gen.get_error_list());
						if (retval) {
							this.insert_text(_("Aborting\n"),false);
						} else {
							this.insert_text(_("Done\n"),false);
						}
					}
					panel.activate_item(this.output);
					panel.show();
				}
			}
			if (opened==false) {
				this.insert_text(_("Failed to get access to the project file\n"),false);
				panel.activate_item(this.output);
				panel.show();
			}
			this.update_state2(true);
		}

		private void launch_command(string[] parameters,string? final_path=null,plugin_callback_func callback=null) {
			bool opened=false;
			var document=this.window.get_active_document();
			if (document!=null) {
				var openfile=document.get_location();
				if (openfile!=null) {
					opened=true;
					var current_filename=openfile.get_path();
					var config=new AutoVala.configuration();
					var enable=config.read_configuration(current_filename) ? false : true;
					if (enable) {
						string final_path2;
						if (final_path==null) {
							final_path2=Path.build_filename(config.basepath,"install");
						} else {
							final_path2=final_path;
						}
						var final_filepath=File.new_for_path(final_path2);
						if (final_filepath.query_exists()==false) {
							try {
								final_filepath.make_directory();
							} catch (Error e) {
							}
						}
						this.launch_child(parameters,final_path2,callback);
					}
				}
			}
		}

		public void cmake_project(Gtk.Action action) {
			this.clear_text();
			string[] parameters={};
			parameters+="cmake";
			parameters+="..";
			this.launch_command(parameters);
		}

		public void build_project(Gtk.Action action) {
			this.clear_text();
			string[] parameters={};
			parameters+="make";
			this.launch_command(parameters);
		}

		public void makeclean_project(Gtk.Action action) {
			this.clear_text();
			string[] parameters={};
			parameters+="make";
			parameters+="clean";
			this.launch_command(parameters);
		}

		private void delete_recursive(string path,bool delete_main) {
			var filepath=File.new_for_path(path);
			if (filepath.query_exists()==false) {
				return;
			}
			FileInfo info_file;
			if (filepath.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS)==FileType.DIRECTORY) {
				var enumerator = filepath.enumerate_children(FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
				while ((info_file = enumerator.next_file(null)) != null) {
					var full_path=Path.build_filename(path,info_file.get_name());
					this.delete_recursive(full_path,true);
				}
			}
			if (delete_main) {
				filepath.delete();
			}
		}

		private void delete_install() {
			var document=this.window.get_active_document();
			if (document!=null) {
				var openfile=document.get_location();
				if (openfile!=null) {
					var current_filename=openfile.get_path();
					var config=new AutoVala.configuration();
					var enable=config.read_configuration(current_filename);
					if (enable==false) {
						var final_path2=Path.build_filename(config.basepath,"install");
						this.delete_recursive(final_path2,false); // don't delete 'install', only its content
					}
				}
			}
			this.update_state2(true);
		}

		public void fullclean_project(Gtk.Action action) {
			var window=new ask_to_continue();
			if (window.run()) {
				this.clear_text();
				this.delete_install();
			}
		}

		public void fullbuild_project(Gtk.Action action) {
			var window=new ask_to_continue();
			if (window.run()) {
				this.clear_text();
				this.delete_install();
				this.update_project2();
				string[] parameters={};
				parameters+="cmake";
				parameters+="..";
				this.launch_command(parameters,null,this.continue_fullbuild);
			}
		}

		public void continue_fullbuild() {
			string[] parameters={};
			parameters+="make";
			this.launch_command(parameters);
		}


		public void activate () {
			this.last_filename=null;
			var manager=this.window.get_ui_manager();
			manager.insert_action_group(this._action_group,-1);
			try {
				this.ui_id=manager.add_ui_from_string("""<ui><menubar name="MenuBar"><menu name="AutovalaMenu" action="Autovala"><placeholder name="AutoValaToolsOps"><menuitem name="Open Project" action="autovala_open"/><menuitem name="update Project" action="autovala_update"/><menuitem name="CMake Project" action="autovala_cmake"/><menuitem name="Build Project" action="autovala_build"/><menuitem name="Clean Project" action="autovala_makeclean"/><menuitem name="Clear directory" action="autovala_fullclean"/><menuitem name="Full build" action="autovala_fullbuild"/></placeholder></menu></menubar></ui>""",-1);
			} catch (Error e) {
			}
			this._action_group.set_sensitive(true);
			this.t_buffer=new Gtk.TextBuffer(null);
			this.output=new Gtk.TextView.with_buffer(this.t_buffer);
			this.output.hexpand=true;
			this.output.vexpand=true;
			this.output.show();
			this.output.set_editable(false);
			this.scrolled=new Gtk.ScrolledWindow(null,null);
			this.scrolled.vscrollbar_policy=PolicyType.ALWAYS;
			this.scrolled.hscrollbar_policy=PolicyType.ALWAYS;
			this.panel=this.window.get_bottom_panel();
			this.scrolled.add(this.output);
			this.panel.add_item(this.scrolled,"autovala_output","Autovala",null);
		}
 
		public void deactivate () {
			var manager=this.window.get_ui_manager();
			manager.remove_ui(this.ui_id);
			manager.remove_action_group(this._action_group);
			manager.ensure_update();
			this.panel.remove_item(this.output);
		}

		public void update_state() {
			this.update_state2(false);
		}

		public void update_state2(bool force) {
			bool disable_all=false;
			var document=this.window.get_active_document();
			if (document!=null) {
				var openfile=document.get_location();
				if (openfile!=null) {
					var current_filename=openfile.get_path();
					if ((current_filename!=this.last_filename)||(force==true)) {
						this.last_filename=current_filename;
						var config=new AutoVala.configuration();
						var enable=config.read_configuration(current_filename) ? false : true;
						if (enable) {
							this.action_open_project.set_sensitive(true);
							this.action_update_project.set_sensitive(true);
							this.action_fullclean_project.set_sensitive(true);
							this.action_fullbuild_project.set_sensitive(true);
							var cmakelists=File.new_for_path(Path.build_filename(config.basepath,"CMakeLists.txt"));
							if (cmakelists.query_exists()) {
								this.action_cmake_project.set_sensitive(true);
								var makefile=File.new_for_path(Path.build_filename(config.basepath,"install","Makefile"));
								if (makefile.query_exists()) {
									this.action_build_project.set_sensitive(true);
									this.action_makeclean_project.set_sensitive(true);
								} else {
									this.action_build_project.set_sensitive(false);
									this.action_makeclean_project.set_sensitive(false);
								}
							} else {
								this.action_cmake_project.set_sensitive(false);
								this.action_build_project.set_sensitive(false);
								this.action_makeclean_project.set_sensitive(false);
							}
						} else {
							disable_all=true;
						}
					}
				} else {
					disable_all=true;
					this.last_filename=null;
				}
			} else {
				disable_all=true;
				this.last_filename=null;
			}
			if (disable_all) {
				this.action_open_project.set_sensitive(false);
				this.action_update_project.set_sensitive(false);
				this.action_cmake_project.set_sensitive(false);
				this.action_build_project.set_sensitive(false);
				this.action_makeclean_project.set_sensitive(false);
				this.action_fullclean_project.set_sensitive(false);
				this.action_fullbuild_project.set_sensitive(false);
			}
		}
	}
}

[ModuleInit]
public void peas_register_types (TypeModule module) {

	Intl.bindtextdomain(AutoVala_geditConstants.GETTEXT_PACKAGE, Path.build_filename(AutoVala_geditConstants.DATADIR,"locale"));
	Intl.bind_textdomain_codeset(AutoVala_geditConstants.GETTEXT_PACKAGE, "utf-8" );
	var objmodule = module as Peas.ObjectModule;

	// Register my plugin extension
	objmodule.register_extension_type (typeof (Gedit.WindowActivatable), typeof (AutoVala_gedit.window));
}
