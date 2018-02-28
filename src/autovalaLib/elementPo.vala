/*
 * Copyright 2013 (C) Raster Software Vigo (Sergio Costas)
 *
 * This file is part of AutoVala
 *
 * AutoVala is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * AutoVala is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>. */

using GLib;

namespace AutoVala {
	private class ElementPo : ElementBase {
		public ElementPo() {
			this._type   = ConfigType.PO;
			this.command = "po";
		}

		public static bool autoGenerate() {
			// checks for "po/" folder
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, "po"));
			// If the folder exists, create a PO element with it
			if ((filePath.query_exists()) && (false == ElementBase.globalData.checkExclude("po"))) {
				var element = new ElementPo();
				return element.autoConfigure("po");
			}
			return false;
		}

		public override void add_files() {
			string[] extensions = {};
			extensions     += "po";
			extensions     += "pot";
			this.file_list  = ElementBase.getFilesFromFolder(this._path, extensions, false);
			this.file_list += Path.build_filename(this._path, "POTFILES.in");
			this.file_list += Path.build_filename(this._path, "meson.build");
			this.file_list += Path.build_filename(this._path, "LINGUAS");
		}

		private void generatePotfiles() throws Error {
			var potFile = Path.build_filename(ElementBase.globalData.projectFolder, this._path, "POTFILES.in");
			var fname   = File.new_for_path(potFile);
			if (fname.query_exists() == true) {
				try {
					fname.delete();
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to delete the old POTFILES.in file at %s").printf(potFile));
					throw e;
				}
			}

			// Generate the POTFILES.in file for compatibility with xgettext
			var dis         = fname.create(FileCreateFlags.NONE);
			var dataStream2 = new DataOutputStream(dis);

			foreach (var element in ElementBase.globalData.globalElements) {
				if (element.eType != ConfigType.TRANSLATION) {
					continue;
				}
				var element2 = element as ElementTranslation;
				dataStream2.put_string(element2.fullPath2 + "\n");
			}
			dataStream2.close();
		}

		public override bool generateCMake(DataOutputStream dataStream) {
			// Generate the POTFILES.in file for compatibility with xgettext
			try {
				this.generatePotfiles();

				dataStream.put_string("include (Translations)\n");
				dataStream.put_string("add_translations_directory(\"" + ElementBase.globalData.projectName + "\")\n");

				// Calculate the number of "../" needed to go from the PO folder to the root of the project
				string[] translatablePaths = {};
				var      toUpper           = this._path.split(Path.DIR_SEPARATOR_S).length;
				var      tmp_path          = "";
				for (var c = 0; c < toUpper; c++) {
					tmp_path += "../";
				}

				// Find all the folders with translatable files
				foreach (var element in ElementBase.globalData.globalElements) {
					if (element.eType == ConfigType.TRANSLATION) {
						bool found = false;
						foreach (var p in translatablePaths) {
							if (p == element.path) {
								found = true;
								break;
							}
						}
						if (found == false) {
							translatablePaths += element.path;
						}
					}
				}

				// Add the files to translate using the VALA CMAKE macros
				if (translatablePaths.length != 0) {
					dataStream.put_string("add_translations_catalog(\"" + ElementBase.globalData.projectName + "\" ");
					foreach (var p in translatablePaths) {
						dataStream.put_string(tmp_path + p + " ");
					}
					dataStream.put_string(")\n");
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to create the PO files list"));
				return true;
			}
			return false;
		}

		public override bool generateMesonHeader(ConditionalText dataStream, MesonCommon mesonCommon) {
			try {
				this.generatePotfiles();

				string[] extensions = {};
				extensions += "po";
				var po_files = ElementBase.getFilesFromFolder(this._path, extensions, false, true);
				if (po_files.length <= 0) {
					return false;
				}

				dataStream.put_string("subdir('%s')\n".printf(this._path));

				var mesonFile = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, this._path, "meson.build"));
				if (mesonFile.query_exists()) {
					try {
						mesonFile.delete();
					} catch (Error e) {
						ElementBase.globalData.addError(_("Failed to delete the old meson.build file at %s").printf(this._path));
						return true;
					}
				}

				var dataStream2 = new DataOutputStream(mesonFile.create(FileCreateFlags.NONE));
				dataStream2.put_string("i18n = import('i18n')\ni18n.gettext('%s', languages: [".printf(ElementBase.globalData.projectName));
				bool first = true;
				foreach (var poname in po_files) {
					if (!first) {
						dataStream2.put_string(", ");
					}
					first = false;
					dataStream2.put_string("'%s'".printf(poname.substring(0, poname.length - 3)));
				}
				dataStream2.put_string("])\n");
				dataStream2.close();

				var linguasFile = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, this._path, "LINGUAS"));
				if (linguasFile.query_exists()) {
					try {
						linguasFile.delete();
					} catch (Error e) {
						ElementBase.globalData.addError(_("Failed to delete the old meson.build file at %s").printf(this._path));
						return true;
					}
				}

				var dataStream3 = new DataOutputStream(linguasFile.create(FileCreateFlags.NONE));
				first = true;
				foreach (var poname in po_files) {
					if (!first) {
						dataStream3.put_string(" ");
					}
					first = false;
					dataStream3.put_string("%s".printf(poname.substring(0, poname.length - 3)));
				}
				dataStream3.put_string("\n");
				dataStream3.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write to meson.build at '%s' element, at '%s' path: %s").printf(this.command, this._path, e.message));
				return true;
			}
			return false;
		}
	}
}
