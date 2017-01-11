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

namespace AutoVala {

	private class ElementDesktop : ElementBase {

		public ElementDesktop() {
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data"));

			if (filePath.query_exists()) {
				var files = ElementBase.getFilesFromFolder("data",{".desktop"},false);
				foreach (var file in files) {
					var element = new ElementDesktop();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber, string[]? comments) {

			// The line starts with 'binary: '
			if (line.has_prefix("desktop: ")) {
				this._type = ConfigType.DESKTOP;
				this.command = "desktop";
			} else if (line.has_prefix("autostart: ")) {
				this._type = ConfigType.AUTOSTART;
				this.command = "autostart";
			} else {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}
			var data=line.substring(2+this.command.length).strip();
			this.comments = comments;
			return this.configureElement(data,null,null,automatic,condition,invertCondition);
		}

		public override bool autoConfigure(string? pathP=null) {

			string path;
			if (pathP == null) {
				path = this.fullPath;
			} else {
				path = pathP;
			}
			this._type = ConfigType.DESKTOP;
			this.command = "desktop";

			try {
				var dis = new DataInputStream (File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,path)).read());
				string line;
				while ((line = dis.read_line (null)) != null) {
					if (line.has_prefix("X-GNOME-Autostart-enabled=")) {
						this._type = ConfigType.AUTOSTART;
						this.command = "autostart";
						break;
					}
				}
			} catch(Error e) {
				ElementBase.globalData.addError(_("Failed to check if file %s is a GNome autostart file").printf(path));
				return true;
			}

			if (pathP!=null) {
				return this.configureElement(path,null,null,true,null,false);
			} else {
				return false;
			}
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			try {
				if (this._type == ConfigType.DESKTOP) {
					dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/"+this.name+" DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications/ )\n");
				} else {
					dataStream.put_string("if( NOT ( ${CMAKE_INSTALL_PREFIX} MATCHES \"^/home/\" ) )\n");
					dataStream.put_string("\tinstall(FILES ${CMAKE_CURRENT_SOURCE_DIR}/"+this.name+" DESTINATION /etc/xdg/autostart/ )\n");
					dataStream.put_string("else()\n");
					dataStream.put_string("\tMESSAGE(STATUS \"\033[33mAutostart file %s will not be installed. You must create your own .desktop file and put it at ~/.config/autostart\033[39m\")\n".printf(Path.build_filename(this._path,this._name)));
					dataStream.put_string("endif()\n");
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to add file %s").printf(this.name));
				return true;
			}
			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {

			try {
				var filename = Path.build_filename(this._path,this._name);
				if (this._type == ConfigType.DESKTOP) {
					dataStream.put_string("install_data('%s',install_dir:join_paths(get_option('prefix'),get_option('datadir'),'applications'))\n".printf(filename));
				} else {
					dataStream.put_string("if (get_option('prefix').startswith('/home/'))\n");
					dataStream.put_string("\tmessage('\033[33mAutostart file %s will not be installed. You must create your own .desktop file and put it at ~/.config/autostart\033[39m')\n".printf(Path.build_filename(this._path,this._name)));
					dataStream.put_string("else\n");
					dataStream.put_string("\tinstall_data('%s',install_dir: '/etc/xdg/autostart')\n".printf(filename));
					dataStream.put_string("endif\n");
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
			}
			return false;
		}
	}
}
