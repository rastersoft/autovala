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

	private class ElementPo : ElementBase {

		public ElementPo() {
			this._type = ConfigType.PO;
			this.command = "po";
		}

		public static bool autoGenerate() {
			// checks for "po/" folder
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"po"));
			// If the folder exists, create a PO element with it
			if ((filePath.query_exists()) && (false==ElementBase.globalData.checkExclude("po"))) {
				var element = new ElementPo();
				return element.autoConfigure("po");
			}
			return false;
		}

		public override void add_files() {

			string[] extensions = {};
			extensions += "po";
			extensions += "pot";
			this.file_list = ElementBase.getFilesFromFolder(this._path,extensions,false);
			this.file_list+= Path.build_filename(this._path,"POTFILES.in");
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			var potFile=Path.build_filename(ElementBase.globalData.projectFolder,this._path,"POTFILES.in");
			var fname=File.new_for_path(potFile);
			if (fname.query_exists()==true) {
				try {
					fname.delete();
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to delete the old POTFILES.in file at %s").printf(potFile));
					return true;
				}
			}

			// Generate the POTFILES.in file for compatibility with xgettext
			try {
				var dis = fname.create(FileCreateFlags.NONE);
				var dataStream2 = new DataOutputStream(dis);

				foreach(var element in ElementBase.globalData.globalElements) {
					switch (element.eType) {
					case ConfigType.VALA_BINARY:
					case ConfigType.VALA_LIBRARY:
						var element2 = element as ElementValaBinary;
						var subFiles=element2.getSubFiles();
						if (subFiles!=null) {
							foreach(var subFile in subFiles) {
								// Don't add the DBUS interfaces to the list of files to check
								if (subFile.contains("dbus_generated")) {
									continue;
								}
								dataStream2.put_string(Path.build_filename(element2.path,subFile)+"\n");
							}
						}
						subFiles=element2.getCSubFiles();
						if (subFiles!=null) {
							foreach(var subFile in subFiles) {
								dataStream2.put_string(Path.build_filename(element2.path,subFile)+"\n");
							}
						}
					break;
					case ConfigType.GLADE:
						dataStream2.put_string("[type: gettext/glade]"+Path.build_filename(element.fullPath)+"\n");
					break;
					default:
					break;
					}
				}
				dataStream2.close();

				dataStream.put_string("include (Translations)\n");
				dataStream.put_string("add_translations_directory(\""+ElementBase.globalData.projectName+"\")\n");

				// Calculate the number of "../" needed to go from the PO folder to the root of the project
				string[] translatablePaths={};
				var toUpper=this._path.split(Path.DIR_SEPARATOR_S).length;
				var tmp_path="";
				for(var c=0;c<toUpper;c++) {
					tmp_path+="../";
				}

				// Find all the folders with translatable files
				foreach (var element in ElementBase.globalData.globalElements) {
					if ((element.eType==ConfigType.VALA_BINARY) || (element.eType==ConfigType.GLADE)) {
						bool found=false;
						foreach (var p in translatablePaths) {
							if (p==element.path) {
								found=true;
								break;
							}
						}
						if (found==false) {
							translatablePaths+=element.path;
						}
					}
				}

				// Add the files to translate using the VALA CMAKE macros
				if (translatablePaths.length!=0) {
					dataStream.put_string("add_translations_catalog(\""+ElementBase.globalData.projectName+"\" ");
					foreach(var p in translatablePaths) {
						dataStream.put_string(tmp_path+p+" ");
					}
					dataStream.put_string(")\n");
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to create the PO files list"));
				return true;
			}
			
			return false;
		}
	}
}
