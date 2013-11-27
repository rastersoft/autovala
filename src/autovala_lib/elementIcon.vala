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
using Gtk;
//using GIO;

namespace AutoVala {

	class ElementIcon : ElementBase {

		private string iconCathegory;
		private string[] appendText;
		private static bool addedSuffix;

		public ElementIcon() {
			this._type = ConfigType.ICON;
			this.appendText = {};
			this.iconCathegory = "";
			ElementIcon.addedSuffix=false;
			this.command = "icon";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (false == line.has_prefix("icon: ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Error: invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}
			// The line starts with 'icon: '
			var data=line.substring(6).strip();
			var pos=data.index_of(" ");
			if (pos!=-1) { // there is a cathegory for the icon; use it instead the default one
				this.iconCathegory=data.substring(0,pos);
				data=data.substring(pos+1).strip();
			} else {
				if (data.has_suffix("-symbolic.svg")) {
					this.iconCathegory="status";
				} else {
					this.iconCathegory="apps";
				}
			}

			return this.configureElement(data,null,null,automatic,condition,invertCondition);
		}

		public override bool autoConfigure(string path) {

			if (path.has_suffix("-symbolic.svg")) {
				this.iconCathegory="status";
			} else {
				this.iconCathegory="apps";
			}
			return this.configureElement(path,null,null,true,null,false);
		}

		public override bool generateCMake(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}

			var fullPath=Path.build_filename(ElementBase.globalData.projectFolder,this._fullPath);
			int size=0;

			// For each PNG file, find the icon size to which it belongs
			if (this.file.has_suffix(".png")) {
				try {
					var picture=new Gdk.Pixbuf.from_file(fullPath);
					int w=picture.width;
					int h=picture.height;
					int[] sizes = {16, 22, 24, 32, 36, 48, 64, 72, 96, 128, 192, 256};
					size=512;
					foreach (var s in sizes) {
						if ((w<=s) && (h<=s)) {
							size=s;
							break;
						}
					}
				} catch (Error e) {
					ElementBase.globalData.addError(_("Can't get the size for icon %s").printf(fullPath));
					return true;
				}
				try {
					dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION share/icons/hicolor/%d/%s/)\n".printf(this.file,size,this.iconCathegory));
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write the CMakeLists file for icon %s").printf(fullPath));
					return true;
				}
			} else if (this.file.has_suffix(".svg")) {
				try {
					dataStream.put_string("install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/%s DESTINATION share/icons/hicolor/scalable/%s/)\n".printf(this.file,this.iconCathegory));
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write the CMakeLists file for icon %s").printf(fullPath));
					return true;
				}
			} else {
				ElementBase.globalData.addError(_("Unknown icon type %s. Must be .png or .svg (in lowercase)").printf(this.file));
				return true;
			}

			return false;
		}

		public override bool generateCMakePostData(DataOutputStream dataStream, ConfigType type) {

			// only process this file if it is of the desired type
			if (type!=this.eType) {
				return false;
			}

			if (ElementIcon.addedSuffix==false) {
				// Refresh the icon cache (but only if ICON_UPDATE is not OFF; that means we are building a package)
				try {
					ElementIcon.addedSuffix=true;
					dataStream.put_string("IF( NOT (${ICON_UPDATE} STREQUAL \"OFF\" ))\n");
					dataStream.put_string("\tinstall (CODE \"execute_process ( COMMAND /usr/bin/gtk-update-icon-cache-3.0 -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor )\" )\n");
					dataStream.put_string("ENDIF()\n");
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to write the PostData for icons at %s").printf(fullPath));
					return true;
				}
			}
			return false;
		}

		public override void endedCMakeFile() {
			ElementIcon.addedSuffix=false;
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			try {
				if (this.automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("icon: %s %s\n".printf(this.iconCathegory,this.fullPath));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'icon: %s' at config").printf(this.fullPath));
				return true;
			}
			return false;
		}
	}
}
