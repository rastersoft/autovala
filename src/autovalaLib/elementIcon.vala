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
using Gdk;
using Gee;

namespace AutoVala {

	enum IconTypes {Fixed, Scalable, Thresold}

	private class IconEntry : Object {

		public string path;
		public int size;
		public int minsize;
		public int maxsize;
		public string context;
		public IconTypes type;

		public IconEntry(string path, string context, IconTypes type, int size, int minsize=-1, int maxsize=-1) {
			this.path = path;
			this.context = context;
			this.type = type;
			this.size = size;
			if (type == IconTypes.Scalable) {
				this.minsize = minsize == -1 ? size : minsize;
				this.maxsize = maxsize == -1 ? size : maxsize;
			} else {
				this.minsize = size;
				this.maxsize = size;
			}
		}

		public bool check_size(string context, int size,bool scalable) {
			if (context != this.context) {
				return false;
			}
			if (scalable) {
				if (this.type == IconTypes.Scalable) {
					return true;
				}
			} else {
				if (size == this.size) {
					return true;
				}
			}
			return false;
		}
	}

	private class Theme : Object {

		public string folder_name;
		public string ?name;
		string basePath;
		Gee.List<IconEntry ?> entries;

		public Theme(string basepath, string folder_name) {
			this.entries = new Gee.ArrayList<IconEntry ?>();
			this.basePath = basepath;
			this.folder_name = folder_name;
			this.name = null;
			this.fill_theme();
		}

		private void fill_theme() {

			var indexFile = GLib.Path.build_filename(this.basePath,"index.theme");
			var file = File.new_for_path(indexFile);
			if (!file.query_exists()) {
				return;
			}
			var data = new GLib.KeyFile();
			if (!data.load_from_file(indexFile,KeyFileFlags.NONE)) {
				return;
			}
			if ((!data.has_group("Icon Theme")) || (!data.has_key("Icon Theme","Name")) || (!data.has_key("Icon Theme","Directories"))) {
				return;
			}
			this.name = data.get_string("Icon Theme","Name");
			var dirs = data.get_string("Icon Theme","Directories").split(",");
			foreach(var group in dirs) {
				if ((!data.has_group(group)) || (!data.has_key(group,"Size"))) {
					continue; // just to avoid problems with malformed index.theme files
				}
				string context = "Actions";
				IconTypes type = IconTypes.Thresold;
				int size = data.get_integer(group,"Size");
				int minsize = -1;
				int maxsize = -1;
				if (data.has_key(group,"Context")) {
					context = data.get_string(group,"Context");
				}
				if (data.has_key(group,"Type")) {
					var tmptype = data.get_string(group,"Type");
					switch (tmptype) {
					case "Fixed":
						type = IconTypes.Fixed;
					break;
					case "Scalable":
						type = IconTypes.Scalable;
					break;
					default:
						type = IconTypes.Thresold;
					break;
					}
				}
				if (type == IconTypes.Scalable) {
					if (data.has_key(group,"MinSize")) {
						minsize = data.get_integer(group,"MinSize");
					}
					if (data.has_key(group,"MaxSize")) {
						maxsize = data.get_integer(group,"MaxSize");
					}
				}
				var element = new IconEntry(group,context, type, size, minsize, maxsize);
				this.entries.add(element);
			}
		}

		public IconEntry? check_size(string context, int size,bool scalable) {

			IconEntry? tmpentry = null;
			foreach(var entry in this.entries) {
				if (entry.check_size(context,size,scalable)) {
					if (scalable) {
						if (!entry.path.contains("scalable")) {
							if (tmpentry == null) {
								tmpentry = entry;
							}
							continue;
						}
					}
					return entry;
				}
			}

			if (tmpentry != null) {
				return tmpentry;
			}
			return null;
		}

		public IconEntry? find_nearest(string context, int size, bool scalable) {

			// for non-scalable, return the smallest one where this size fits
			if (!scalable) {
				int tmpsize = -1;
				IconEntry? tmpentry = null;
				foreach(var entry in this.entries) {
					if ((entry.context != context) || (entry.type == IconTypes.Scalable)) {
						continue;
					}
					if ((entry.size >= size) && ((tmpsize == -1) || (entry.size < tmpsize))) {
						tmpentry = entry;
						tmpsize = entry.size;
					}
				}
				return tmpentry;
			}

			// for scalable, return the biggest one in the specified context
			int tmpsize = -1;
			IconEntry? tmpentry = null;
			foreach(var entry in this.entries) {
				if ((entry.context != context) || (entry.type == IconTypes.Scalable)) {
					continue;
				}
				if ((tmpsize == -1) || (entry.size > tmpsize)) {
					tmpentry = entry;
					tmpsize = entry.size;
				}
			}
			return tmpentry;
		}

	}

	private class ThemeList : Object {

		private Gee.List<Theme ?> themes;

		public ThemeList() {

			this.themes = new Gee.ArrayList<Theme ?>();
			var pathvar = GLib.Environment.get_variable("XDG_DATA_DIRS");
			if (pathvar != null) {
				var paths = pathvar.split(":");

				foreach (var path in paths) {
					var fullpath = GLib.Path.build_filename(path,"icons");
					var directory = File.new_for_path(fullpath);
					if ((!directory.query_exists()) || (directory.query_file_type(GLib.FileQueryInfoFlags.NONE) != GLib.FileType.DIRECTORY)) {
						continue;
					}
					try {
						var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);

						FileInfo file_info;
						while ((file_info = enumerator.next_file ()) != null) {
							if (file_info.get_file_type() != GLib.FileType.DIRECTORY) {
								continue;
							}
							var theme = new Theme(GLib.Path.build_filename(fullpath,file_info.get_name()),file_info.get_name());
							if (theme.name != null) {
								this.themes.add(theme);
							}
						}
					} catch (Error e) {
					}
				}
			}
		}

		public Theme? find_theme(string name) {
			foreach(var theme in this.themes) {
				if ((theme.name == name) || (theme.folder_name == name)) {
					return theme;
				}
			}
			return null;
		}
	}

	private class ElementIcon : ElementBase {

		private string iconCathegory;
		private string[] appendText;
		private string iconTheme;
		private bool fixed_size;
		private static weak DataOutputStream lastCMakeFile = null;
		private static string[] updateThemes = {};
		private static ThemeList themes = new ThemeList();

		public ElementIcon() {
			this._type = ConfigType.ICON;
			this.appendText = {};
			this.iconCathegory = "";
			this.iconTheme = "Hicolor"; // default value
			this.command = "full_icon";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data","icons"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data/icons",{".png",".svg"},true);
				foreach (var file in files) {
					var element = new ElementIcon();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		private void add_theme(string theme) {

			foreach(var t in ElementIcon.updateThemes) {
				if (theme == t) {
					return;
				}
			}
			ElementIcon.updateThemes += theme;
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			var command = line.split(": ")[0];
			if ((command != "icon") && (command != "full_icon") && (command != "fixed_size_icon")) {
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(command,this.command, lineNumber));
				return true;
			}
			string data;
			this.fixed_size = false;
			if (command == "icon") {
				// The line starts with 'icon: '
				data=line.substring(6).strip();
				var pos=data.index_of(" ");
				if (pos!=-1) { // there is a cathegory for the icon; use it instead the default one
					this.iconCathegory=data.substring(0,pos);
					data=data.substring(pos+1).strip();
				} else {
					if (data.has_suffix("-symbolic.svg")) {
						this.iconCathegory="Status";
					} else {
						this.iconCathegory="Applications";
					}
				}
			} else {
				if (command == "full_icon") {
					// The line starts with 'full_icon: '
					data=line.substring(11).strip();
				} else {
					// The line starts with 'fixed_size_icon: '
					data=line.substring(17).strip();
					this.fixed_size = true;
				}
				var pos=data.index_of(" ");
				if (pos==-1) { // there is no theme for the icon; it is an error
					ElementBase.globalData.addError(_("%s must have a cathegory and a theme (line %d)").printf(command,lineNumber));
					return true;
				}

				var pos2=data.index_of(" ",pos+1);
				if (pos2==-1) { // there is no cathegory for the icon; it is an error
					ElementBase.globalData.addError(_("%s must have a cathegory and a theme (line %d)").printf(command,lineNumber));
					return true;
				}
				this.iconTheme = data.substring(0,pos).strip();
				this.iconCathegory = data.substring(pos+1,pos2-pos-1).strip();
				data=data.substring(pos2+1).strip();
			}

			this.add_theme(this.iconTheme);

			// fixed_size_icon must be always manually added
			return this.configureElement(data,null,null,this.fixed_size ? false : automatic,condition,invertCondition);
		}

		public override bool autoConfigure(string? path=null) {

			if (path == null) {
				return false;
			}

			if (path.has_suffix("-symbolic.svg")) {
				this.iconCathegory="Status";
			} else {
				this.iconCathegory="Applications";
			}
			this.add_theme(this.iconTheme);
			return this.configureElement(path,null,null,true,null,false);
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			// Count how many CMake files for icons we are building,
			// to ensure that we put the regeneration code in the last one

			var fullPath=Path.build_filename(ElementBase.globalData.projectFolder,this._fullPath);
			int size=0;

			var theme = ElementIcon.themes.find_theme(this.iconTheme);
			if (theme == null) {
				ElementBase.globalData.addWarning(_("The icon theme %s isn't installed in the system; can't get its data").printf(this.iconTheme));
				return true;
			}

			// For each PNG file, find the icon size to which it belongs
			if (this.name.has_suffix(".png")) {
				try {
					var picture=new Gdk.Pixbuf.from_file(fullPath);
					size = this.get_nearest_size(picture.width,picture.height);
				} catch (Error e) {
					ElementBase.globalData.addError(_("Can't get the size for icon %s").printf(fullPath));
					return true;
				}
				var entry = theme.check_size(this.iconCathegory,size,false);
				if (entry == null) {
					ElementBase.globalData.addWarning(_("Can't find a suitable entry size in theme %s for the icon %s with size %d in context %s").printf(this.iconTheme,this.name,size,this.iconCathegory));
					return false;
				}
				try {
					dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/%s/)\n".printf(this.name,GLib.Path.build_filename(theme.folder_name,entry.path)));
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write the CMakeLists file for icon %s").printf(fullPath));
					return true;
				}
			} else if (this.name.has_suffix(".svg")) {
				IconEntry? entry = null;
				if (!this.fixed_size) {
					entry = theme.check_size(this.iconCathegory,0,true);
				}
				if (entry == null) {
					// there are no SCALABLE entries, so let's try with the canvas size
					int w;
					int h;
					string local_path = GLib.Path.build_filename(ElementBase.globalData.projectFolder,this.fullPath);
					if (this.get_svg_size(local_path,out w, out h)) {
						size = this.get_nearest_size(w,h);
						entry = theme.find_nearest(this.iconCathegory,size,false);
					}
				}
				if (entry == null) {
					// If the icon doesn't have width or height info, or there is no valid entry for that size, put it in the biggest one
					ElementBase.globalData.addWarning(_("Can't get the canvas size for the icon %s; putting it in the biggest entry in context %s, theme %s").printf(this.name, this.iconCathegory,this.iconTheme));
					entry = theme.find_nearest(this.iconCathegory,0,true);
				}
				if (entry == null) {
					ElementBase.globalData.addWarning(_("Can't find a valid entry in context %s to install the icon %s in theme %s").printf(this.iconCathegory, this.name,this.iconTheme));
					return false;
				}
				try {
					dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/%s/)\n".printf(this.name,GLib.Path.build_filename(theme.folder_name,entry.path)));
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write the CMakeLists file for icon %s").printf(fullPath));
					return true;
				}
			} else {
				ElementBase.globalData.addError(_("Unknown icon type %s. Must be .png or .svg (in lowercase)").printf(this.name));
				return true;
			}

			return false;
		}

		private bool get_svg_size(string filename, out int w, out int h) {

			w = 0;
			h = 0;
			var file=File.new_for_path(filename);
			if (!file.query_exists()) {
				return false;
			}
			try {
				var dis = new DataInputStream(file.read());
				string line;
				string data = "";
				while((line = dis.read_line(null))!=null) {
					data+=line+" ";
				}
				var pos1 = data.index_of("<svg");
				if (pos1 == -1) {
					return false; // it is not an SVG file
				}
				var pos2 = data.index_of_char('>',pos1);
				if (pos2 == -1) {
					return false; // it is not a valid SVG file
				}
				data = data.substring(pos1,pos2-pos1);
				var pos3 = data.index_of("width");
				var pos4 = data.index_of("height");
				if ((pos3==-1)||(pos4==-1)) {
					return false; // no width or height values
				}
				var pos5 = data.index_of("\"",pos3);
				if (pos5 == -1) {
					return false; // malformed SVG file
				}
				var pos6 = data.index_of("\"",pos5+1);
				if (pos6 == -1) {
					return false; // malformed SVG file
				}
				var pos7 = data.index_of("\"",pos4);
				if (pos7 == -1) {
					return false; // malformed SVG file
				}
				var pos8 = data.index_of("\"",pos7+1);
				if (pos8 == -1) {
					return false; // malformed SVG file
				}

				// The width is between pos5 and pos6, and the height between pos7 and pos8
				w = (int)(double.parse(data.substring(pos5+1,pos6-pos5-1))+0.5);
				h = (int)(double.parse(data.substring(pos7+1,pos8-pos7-1))+0.5);
				return true;

			} catch (Error e) {
				return false;
			}
		}

		private int get_nearest_size(int w, int h) {

			int[] sizes = {16, 22, 24, 32, 36, 48, 64, 72, 96, 128, 192, 256};
			int size=512;
			foreach (var s in sizes) {
				if ((w<=s) && (h<=s)) {
					size=s;
					break;
				}
			}
			return (size);
		}

		public override bool generateCMakePostData(DataOutputStream dataStreamGlobal,DataOutputStream dataStream) {

			if (ElementIcon.lastCMakeFile != dataStreamGlobal) {
				if (ElementIcon.updateThemes.length != 0) {
					// Refresh the icon cache (but only if ICON_UPDATE is not OFF; that means we are building a package)
					try {
						dataStreamGlobal.put_string("if( NOT (${ICON_UPDATE} STREQUAL \"OFF\" ))\n");
						dataStreamGlobal.put_string("\tfind_program ( GTK_UPDATE_ICON_CACHE NAMES gtk-update-icon-cache.3.0 gtk-update-icon-cache )\n");
						foreach(var theme in ElementIcon.updateThemes) {
							var th = ElementIcon.themes.find_theme(theme);
							if (th!=null) {
								dataStreamGlobal.put_string("\tinstall (CODE \"execute_process ( COMMAND ${GTK_UPDATE_ICON_CACHE} -t ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}/icons/%s )\" )\n".printf(th.folder_name));
							}
						}
						dataStreamGlobal.put_string("ENDIF()\n");
					} catch (Error e) {
						ElementBase.globalData.addError(_("Failed to write the PostData for icons at %s").printf(fullPath));
						return true;
					}
				}
			}
			ElementIcon.lastCMakeFile = dataStreamGlobal;
			return false;
		}

		public override void endedCMakeFile() {
			ElementIcon.lastCMakeFile = null;
			ElementIcon.updateThemes={};
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				if (this.fixed_size) {
					dataStream.put_string("fixed_size_icon: %s %s %s\n".printf(this.iconTheme,this.iconCathegory,this.fullPath));
				} else {
					dataStream.put_string("full_icon: %s %s %s\n".printf(this.iconTheme,this.iconCathegory,this.fullPath));
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'icon: %s' at config").printf(this.fullPath));
				return true;
			}
			return false;
		}
	}
}
