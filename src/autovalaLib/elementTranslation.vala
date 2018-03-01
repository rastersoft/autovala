/*
 * Copyright 2013-2016 (C) Raster Software Vigo (Sergio Costas)
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
	public enum TranslationType { C, VALA, GLADE, GENIE }

	private class ElementTranslation : ElementBase {
		protected TranslationType _translate_type;
		public TranslationType ? translate_type {
			get { return this._translate_type; }
			set { this._translate_type = value; }
		}

		// Full file path, relative to the project's root
		protected string ? _fullPath2;

		public string ? fullPath2 {
			get { return this._fullPath2; }
		}

		public ElementTranslation() {
			this._type     = ConfigType.TRANSLATION;
			this.command   = "translate";
			this._fullPath = null;
		}

		public static bool autoGenerate() {
			// nothing to do here
			return false;
		}

		public override void add_files() {
			// this doesn't return files
			this.file_list = {};
		}

		public override bool configureElement(string ? fullPathP, string ? path, string ? name, bool automatic, string ? condition, bool invertCondition, bool accept_nonexisting_paths = false) {
			if (fullPathP == "") {
				ElementBase.globalData.addError(_("Trying to add an empty path: %s").printf(fullPath));
				return true;
			}

			string ? fullPath_t = fullPathP;
			if (fullPath_t != null) {
				if (fullPath_t.has_suffix(Path.DIR_SEPARATOR_S)) {
					fullPath_t = fullPathP.substring(0, fullPathP.length - 1);
				}
				foreach (var element in ElementBase.globalData.globalElements) {
					if (element.eType == ConfigType.TRANSLATION) {
						var element2 = element as ElementTranslation;
						if (fullPath_t == element2.fullPath2) {
							if ((automatic == false) && (element.automatic == false)) {
								ElementBase.globalData.addWarning(_("Trying to add twice the file %s for translation").printf(fullPath_t));
							}
							if (element.automatic == true) {
								element.automatic = automatic;
							}
							return false;
						}
					}
				}
			}

			this._fullPath2 = fullPath_t;
			if ((path == null) || (name == null)) {
				var file = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder, fullPath_t));
				if (file.query_exists() == false) {
					ElementBase.globalData.addWarning(_("File %s doesn't exist").printf(fullPath_t));
					return false;
				}
				if (file.query_file_type(FileQueryInfoFlags.NONE) != GLib.FileType.DIRECTORY) {
					this._path = GLib.Path.get_dirname(fullPath_t);
					this._name = GLib.Path.get_basename(fullPath_t);
				} else {
					this._path = fullPath_t;
					this._name = "";
				}
			} else {
				this._path = path;
				this._name = name;
			}

			if ((this._path == ".") || (this._path == "./")) {
				ElementBase.globalData.addError(_("File %s is located at the project's root. Autovala doesn't allow that. You should move it into a folder.").printf(fullPath_t));
				return true;
			}

			ElementBase.globalData.addElement(this);
			this._automatic       = automatic;
			this._condition       = condition;
			this._invertCondition = invertCondition;
			return false;
		}

		public override bool configureLine(string line, bool automatic, string ? condition, bool invertCondition, int lineNumber, string[] ? comments) {
			if (false == line.has_prefix(this.command + ": ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand, this.command, lineNumber));
				return true;
			}
			var data = line.substring(2 + this.command.length).strip();
			var pos  = data.index_of_char(' ');
			if (pos == -1) {
				ElementBase.globalData.addError(_("Translate command without type at line %d").printf(lineNumber));
				return true;
			}
			var type_v = data.substring(0, pos);
			switch (type_v) {
			case "c":
				this._translate_type = TranslationType.C;
				break;

			case "vala":
				this._translate_type = TranslationType.VALA;
				break;

			case "glade":
				this._translate_type = TranslationType.GLADE;
				break;

			case "genie":
				this._translate_type = TranslationType.GENIE;
				break;
			}
			this.comments = comments;
			return this.configureElement(data.substring(pos + 1).strip(), null, null, automatic, condition, invertCondition);
		}

		public override bool storeConfig(DataOutputStream dataStream, ConditionalText printConditions) {
			string data;
			if (this.fullPath2 == null) {
				data = this.name;
			} else {
				data = this.fullPath2;
			}

			string type_v = "vala";

			switch (this._translate_type) {
			case TranslationType.C:
				type_v = "c";
				break;

			case TranslationType.GLADE:
				type_v = "glade";
				break;

			case TranslationType.VALA:
				type_v = "vala";
				break;

			case TranslationType.GENIE:
				type_v = "genie";
				break;
			}

			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("%s: %s %s\n".printf(this.command, type_v, data));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store '%s: %s %s' at config").printf(this.command, type_v, data));
				return true;
			}
			return false;
		}

		public override string ? getSortId() {
			if (this.fullPath2 == null) {
				return this.name;
			} else {
				return this.fullPath2;
			}
		}
	}
}
