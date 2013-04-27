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

// project version=0.15

namespace AutoVala_gedit {

	public class window : Gedit.WindowActivatable, Peas.ExtensionBase {

		private Gtk.ActionGroup _action_group;
		private Gtk.ActionGroup _action_group1;
		private Gtk.ActionGroup _action_group2;
		private uint ui_id;
		private Gtk.ActionEntry[] entry_list;
		private Gtk.ActionEntry[] entry_list1;
		private Gtk.ActionEntry[] entry_list2;
		private string ?last_filename;
		private Gtk.TextView output;
		private Gtk.TextBuffer t_buffer;
		private Gedit.Panel panel;

		public window () {
			GLib.Object ();
		}

		public Gedit.Window window {
			owned get; construct;
		}

		public void new_project(Gtk.Action action) {
			print("Nuevo proyecto\n");
		}

		private void clear_text() {
			this.t_buffer=new Gtk.TextBuffer(null);
			this.output.set_buffer(this.t_buffer);
		}

		private void insert_text(string text,bool add_cr) {
			time_t datetime;
			time_t(out datetime);
			var localtime=GLib.Time.local(datetime);
			this.t_buffer.insert_at_cursor("[%d:%d:%d] ".printf(localtime.hour,localtime.minute,localtime.second),-1);
			if (add_cr) {
				this.t_buffer.insert_at_cursor(text+"\n",-1);
			} else {
				this.t_buffer.insert_at_cursor(text,-1);
			}
		}

		private void show_errors(string[] error_list) {
			foreach(var e in error_list) {
				this.insert_text(e,true);
			}
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

		public void refresh_project(Gtk.Action action) {
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
						retval=gen.cmake();
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
		}

		public void cmake_project(Gtk.Action action) {
			print("CMake proyecto\n");
		}

		public void build_project(Gtk.Action action) {
			print("Build proyecto\n");
		}

		public void activate () {
			this.panel=this.window.get_bottom_panel();
			this.last_filename=null;
			this.t_buffer=new Gtk.TextBuffer(null);
			this.output=new Gtk.TextView.with_buffer(this.t_buffer);
			this.output.set_editable(false);
			this.panel.add_item(this.output,"autovala_output","Autovala",null);
			var manager=this.window.get_ui_manager();
			var entry = Gtk.ActionEntry();
			entry.name="Autovala";
			entry.stock_id="";
			entry.label=_("Autovala");
			entry.accelerator="";
			entry.tooltip="";
			entry.callback=null;

			var entry2 = Gtk.ActionEntry();
			entry2.name="autovala_new";
			entry2.stock_id="";
			entry2.label=_("New project");
			entry2.accelerator="";
			entry2.tooltip="Creates a new Autovala project";
			entry2.callback=this.new_project;

			var entry6 = Gtk.ActionEntry();
			entry6.name="autovala_open";
			entry6.stock_id="";
			entry6.label=_("Open project file");
			entry6.accelerator="";
			entry6.tooltip="Opens the project file for the current source file";
			entry6.callback=this.open_project;

			var entry3 = Gtk.ActionEntry();
			entry3.name="autovala_refresh";
			entry3.stock_id="";
			entry3.label=_("Refresh project file");
			entry3.accelerator="";
			entry3.tooltip="Refreshes the .avprj project file";
			entry3.callback=this.refresh_project;

			var entry4 = Gtk.ActionEntry();
			entry4.name="autovala_cmake";
			entry4.stock_id="";
			entry4.label=_("Run CMake");
			entry4.accelerator="";
			entry4.tooltip="Runs CMake to create the Makefile";
			entry4.callback=this.cmake_project;

			var entry5 = Gtk.ActionEntry();
			entry5.name="autovala_build";
			entry5.stock_id="";
			entry5.label=_("Build project");
			entry5.accelerator="";
			entry5.tooltip="Builds the project running MAKE";
			entry5.callback=this.build_project;

			this.entry_list={};
			this.entry_list+=entry;
			this.entry_list1={};
			this.entry_list1+=entry2;
			this.entry_list2={};
			this.entry_list2+=entry6;
			this.entry_list2+=entry3;
			this.entry_list2+=entry4;
			this.entry_list2+=entry5;
			this._action_group=new Gtk.ActionGroup("AutoVala");
			this._action_group1=new Gtk.ActionGroup("AutoVala1");
			this._action_group2=new Gtk.ActionGroup("AutoVala2");
			this._action_group.add_actions(this.entry_list,this);
			this._action_group1.add_actions(this.entry_list1,this);
			this._action_group2.add_actions(this.entry_list2,this);
			manager.insert_action_group(this._action_group,-1);
			manager.insert_action_group(this._action_group1,-1);
			manager.insert_action_group(this._action_group2,-1);
			this.ui_id=manager.add_ui_from_string("""<ui><menubar name="MenuBar"><menu name="AutovalaMenu" action="Autovala"><placeholder name="AutoValaToolsOps"><menuitem name="New Project" action="autovala_new"/><menuitem name="Open Project" action="autovala_open"/><menuitem name="Refresh Project" action="autovala_refresh"/><menuitem name="CMake Project" action="autovala_cmake"/><menuitem name="Build Project" action="autovala_build"/></placeholder></menu></menubar></ui>""",-1);
			this._action_group.set_sensitive(true);
			this._action_group1.set_sensitive(true);
			this._action_group2.set_sensitive(false);
		}
 
		public void deactivate () {
			var manager=this.window.get_ui_manager();
			manager.remove_ui(this.ui_id);
			manager.remove_action_group(this._action_group2);
			manager.remove_action_group(this._action_group1);
			manager.remove_action_group(this._action_group);
			manager.ensure_update();
		}
		public void update_state () {
			bool enable=false;
			var document=this.window.get_active_document();
			if (document!=null) {
				var openfile=document.get_location();
				if (openfile!=null) {
					var current_filename=openfile.get_path();
					if (current_filename!=this.last_filename) {
						this.last_filename=current_filename;
						var config=new AutoVala.configuration();
						enable=config.read_configuration(current_filename) ? false : true;
						this._action_group2.set_sensitive(enable);
					}
				}
			}
		}
	}
}

[ModuleInit]
public void peas_register_types (TypeModule module) {

	Intl.bindtextdomain(AutoVala_geditConstants.GETTEXT_PACKAGE, Path.build_filename(AutoVala_geditConstants.DATADIR,"locale"));
	var objmodule = module as Peas.ObjectModule;

	// Register my plugin extension
	objmodule.register_extension_type (typeof (Gedit.WindowActivatable), typeof (AutoVala_gedit.window));
}
