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
using Gee;


namespace autovala {

	enum Config_Type {VALA_BINARY, BINARY, ICON, PIXMAP, PO, DBUS_SERVICE, DESKTOP, AUTOSTART, EOS_PLUG, SCHEME}
	
	struct config_element {
		Config_Type type;
		string path;
		string file;
	}

	class autovala:GLib.Object {

		private Gee.List<config_element ?> configuration;
		private string config_path;
		
		public autovala() {
			this.config_path="";
			this.configuration=null;
		}

		string find_configuration(string basepath) {
		
			FileEnumerator enumerator;
			FileInfo info_file;
			string full_path="";
			string[] filename;
			string extension;
			FileType typeinfo;

			var directory = File.new_for_path(basepath);
			try {
				enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE,FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
			} catch (Error e) {
				return "";
			}
			while ((info_file = enumerator.next_file(null)) != null) {
				full_path="";
				typeinfo=info_file.get_file_type();
				if (typeinfo!=FileType.REGULAR) {
					continue;
				}
				filename=info_file.get_name().split(".");
				extension=filename[filename.length-1];
				if (extension.casefold()!="avprj".casefold()) {
					continue;
				}
				full_path=Path.build_filename(basepath,info_file.get_name());
				
				// check it's a AutoVala Project file
				var file=File.new_for_path(full_path);
				try {
					var dis = new DataInputStream (file.read ());
					string line;
					line = dis.read_line(null);
					if (line!="### AutoVala Project file ###") {
						continue;
					}
				} catch (Error e) {
					continue;
				}
				break;
			}
			return (full_path);
		}

		public bool read_configuration() {
		
			this.configuration=new Gee.ArrayList<config_element ?>();
		
			var basepath=GLib.Environment.get_current_dir().split(Path.DIR_SEPARATOR_S);
			int len=basepath.length;
			this.config_path="";
			while(len>=0) {
				var path=Path.DIR_SEPARATOR_S;
				for(var i=0;i<len;i++) {
					path=Path.build_filename(path,basepath[i]);
				}
				this.config_path=this.find_configuration(path);
				if (this.config_path!="") {
					break;
				}
				len--;
			}
			if (this.config_path=="") {
				return false; // no configuration file found
			}
			
			var file=File.new_for_path(this.config_path);
			try {
				var dis = new DataInputStream(file.read());
				string line;
				while((line = dis.read_line(null))!=null) {
					if (line[0]=='#') {
						continue;
					}
					var finalline=line.strip();
					if (finalline=="") {
						continue;
					}
					if (line.has_prefix("vala_binary: ")) {
						this.find_entry(line.substring(13).strip(),Config_Type.VALA_BINARY);
						continue;
					}
					if (line.has_prefix("binary: ")) {
						this.find_entry(line.substring(8).strip(),Config_Type.BINARY);
						continue;
					}
					if (line.has_prefix("icon: ")) {
						this.find_entry(line.substring(6).strip(),Config_Type.ICON);
						continue;
					}
					if (line.has_prefix("pixmap: ")) {
						this.find_entry(line.substring(8).strip(),Config_Type.PIXMAP);
						continue;
					}
					if (line.has_prefix("po: ")) {
						this.find_entry(line.substring(4).strip(),Config_Type.PO);
						continue;
					}
					if (line.has_prefix("dbus_service: ")) {
						this.find_entry(line.substring(14).strip(),Config_Type.DBUS_SERVICE);
						continue;
					}
					if (line.has_prefix("desktop: ")) {
						this.find_entry(line.substring(9).strip(),Config_Type.DESKTOP);
						continue;
					}
					if (line.has_prefix("autostart: ")) {
						this.find_entry(line.substring(11).strip(),Config_Type.AUTOSTART);
						continue;
					}
					if (line.has_prefix("eos_plug: ")) {
						this.find_entry(line.substring(10).strip(),Config_Type.EOS_PLUG);
						continue;
					}
					if (line.has_prefix("scheme: ")) {
						this.find_entry(line.substring(8).strip(),Config_Type.SCHEME);
						continue;
					}
				}
			} catch (Error e) {
				return false;
			}
			return true;
		}
		
		private void find_entry(string filename, Config_Type type) {
		
			var file=Path.get_basename(filename);
			var path=Path.get_dirname(filename);
		
			foreach(var e in this.configuration) {
				if ((e.type==type)&&(e.file==file)&&(e.path==path)) {
					return;
				}
			}
			var element=config_element();
			element.type=type;
			element.file=file;
			element.path=path;
			this.configuration.add(element);
		}
		
		public void list_all() {
			foreach(var e in this.configuration) {
				GLib.stdout.printf("Path: %s, file: %s\n",e.path,e.file);
			}
		}
	}
}

int main(string argv[]) {

	var tmp=new autovala.autovala();

	if(tmp.read_configuration()) {
		GLib.stdout.printf("Correcto\n");
		tmp.list_all();
	} else {
		GLib.stdout.printf("Incorrecto\n");
	}

	return 0;
}
