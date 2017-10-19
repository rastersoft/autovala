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

	private class ElementVapidir : ElementBase {

		public ElementVapidir() {
			this._type = ConfigType.VAPIDIR;
			this.command = "vapidir";
		}

		public static bool autoGenerate() {

			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"src","vapidir"));

			if (filePath.query_exists()) {
				var element = new ElementVapidir();
				error|=element.autoConfigure("src/vapidir");
			}
			return error;
		}

		public override bool configureElement(string? fullPathP, string? path, string? name, bool automatic, string? condition, bool invertCondition, bool accept_nonexisting_paths = false) {
			var retval = base.configureElement(fullPathP,path,name,automatic,condition,invertCondition, true);
			if (!retval) {
				AutoVala.Globals.vapiList.fillNamespaces(fullPathP);
			}
			return retval;
		}


		public override void add_files() {

			if (this._fullPath[0] == GLib.Path.DIR_SEPARATOR) {
				// don't add VAPI files that aren't inside this project
				return;
			}
			this.file_list = AutoVala.ElementBase.getFilesFromFolder(this._fullPath,{".vapi"},false);
		}

	}
}
