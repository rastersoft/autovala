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

	class Globals : GLib.Object {

		public string projectName; // The project's name
		public string? projectFolder; // The absolute path to the project's root folder
		public string? configFile; // The absolute path to the project definition file

		public int valaMajor;
		public int valaMinor;

		private string[] files; // A list with all the files already processed, to allow to new objects to know if a file has already been processed (that's why it's a class property instead of an object one)
		public string[] excludeFiles; // A list with all the files and paths that must be avoided when doing automatic detection
		public Gee.List<ElementBase> globalElements; // The list of all elements

		public bool error;
		public bool warning;
		private string[] errorList;

		public Globals(string projectName) {

			ElementBase.globalData = this;
			ConditionalText.globalData = this;
			this.error = false;
			this.warning = false;
			this.projectName = projectName;
			this.projectFolder = null;
			this.globalElements = new Gee.ArrayList<ElementBase>();
			this.files = {};
			this.excludeFiles = {};
			this.getValaVersion();

			var basePath=GLib.Environment.get_current_dir().split(Path.DIR_SEPARATOR_S);
			var len=basePath.length;
			while(len>=0) {
				var path=Path.DIR_SEPARATOR_S;
				for(var i=0;i<len;i++) {
					path=Path.build_filename(path,basePath[i]);
				}
				this.configFile=this.findConfiguration(path);
				if (this.configFile!="") {
					this.projectFolder=path;
					break;
				}
				len--;
			}
		}

		/**
		 * Inserts a new file structure in the global list
		 * @param element The file structure to add
		 */
		public void addElement(ElementBase element) {
			this.globalElements.add(element);
		}

		/**
		 * Inserts a new file in the list
		 * @param filename to add (with path relative to the project's root)
		 */
		public void addFile(string filename) {
			if (false==this.checkFile(filename)) {
				this.files += filename;
			}
		}

		/**
		 * Inserts a new file/path in the list of exclude files/paths
		 * @param file/path to add (with path relative to the project's root)
		 */
		public void addExclude(string filename) {
			if (false==this.checkExclude(filename)) {
				this.excludeFiles += filename;
			}
		}

		/**
		 * Checks whether a file has been already processed
		 * @param filename The filename to check (with path relative to the project's root
		 * @return //true// if the file has been processed in another object; //false// if not
		 */
		public bool checkFile(string? filename) {
			foreach (var element in this.files) {
				if (element == filename) {
					return true;
				}
			}
			return false;
		}

		/**
		 * Checks whether a file/path is in the exclude list
		 * @param filename The file/path to check (with path relative to the project's root
		 * @return //true// if the file is in the list; //false// if not
		 */
		public bool checkExclude(string filename) {
			foreach (var element in this.excludeFiles) {
				if (element == filename) {
					return true;
				}
			}
			return false;
		}

		/**
		 * Checks if the specified path contains a valid configuration file, returning the full path
		 * @param basePath The path where to seek for a configuration file
		 * @return the full path of the configuration file
		 */
		private string findConfiguration(string basePath) {

			FileEnumerator enumerator;
			FileInfo info_file;
			string full_path="";
			string[] filename;
			string extension;
			FileType typeinfo;

			var directory = File.new_for_path(basePath);
			try {
				enumerator = directory.enumerate_children(GLib.FileAttribute.STANDARD_NAME+","+GLib.FileAttribute.STANDARD_TYPE,GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
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
					full_path=Path.build_filename(basePath,info_file.get_name());

					// check it's a AutoVala Project file
					var file=File.new_for_path(full_path);
					try {
						var dis = new DataInputStream (file.read ());
						string line;
						line = dis.read_line(null);
						if (!line.has_prefix("### AutoVala Project ###")) {
							continue;
						}
					} catch (Error e) {
						continue;
					}
					break;
				}
			} catch (Error e) {
				return "";
			}
			return (full_path);
		}

/**
		 * Returns the version of Vala compiler installed in the system (the default one)
		 *
		 * @return //false// if there was no error, //true// if the version can't be determined
		 */

		public bool getValaVersion() {

			/*
			 * Maybe a not very elegant way of doing it. I accept patches
			 */
			this.valaMajor=16;
			this.valaMinor=0;

			if (0!=Posix.system("valac --version > /var/tmp/current_vala_version")) {
				return true;
			}
			var file=File.new_for_path("/var/tmp/current_vala_version");
			try {
				var dis = new DataInputStream(file.read());
				string ?line;
				while((line=dis.read_line(null))!=null) {
					var version=line.split(" ");
					foreach(var element in version) {
						if (Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?$",element)) {
							var numbers=element.split(".");
							this.valaMajor=int.parse(numbers[0]);
							this.valaMinor=int.parse(numbers[1]);
							return false;
						}
					}
				}
			} catch (Error e) {
				return true;
			}
			return true;
		}

		/**
		 * Inserts an error in the error list
		 * @param error to add
		 */
		public void addError(string errorMsg) {
			this.error = true;
			this.errorList += errorMsg;
		}

		/**
		 * Inserts a warning in the error list
		 * @param warning to add
		 */
		public void addWarning(string warningMsg) {
			this.warning = true;
			this.errorList += warningMsg;
		}

		/**
		 * Inserts a message in the error list
		 * @param message to add
		 */
		public void addMessage(string msg) {
			this.errorList += msg;
		}

		/**
		 * Clears the error list
		 */

		public void clearErrors() {
			this.error = false;
			this.warning = false;
			this.errorList={};
		}

		/**
		 * Return the list of errors and warnings, to allow to show it from another program
		 *
		 * @return An array with one error or warning in each string
		 */

		public string[] getErrorList() {
			return this.errorList;
		}

		/**
		 * Sets the configuration file
		 *
		 * This method is useful when creating a new project; after creating a new configuration object (specifying the project name), use
		 * this method to set the path and filename where to store it, before calling //save_configuration()//.
		 *
		 * @param path The path for the configuration file. If given as a relative path, it will be internally expanded to the full path
		 */

		public void setConfigFilename(string path) {

			if (GLib.Path.is_absolute(path)) {
				this.configFile=path;
			} else {
				this.configFile=GLib.Path.build_filename(GLib.Environment.get_current_dir(),path);
			}
			this.projectFolder=GLib.Path.get_dirname(this.configFile);
		}

		/**
		 * Comparation function to sort the elements
		 */
		public static int compareElements (ElementBase? a, ElementBase? b) {
			if ((a.conditionE=="")&&(b.conditionE=="")) {
				return a.fullPath.collate(b.fullPath);
			}
			if (a.conditionE=="") {
				return -1;
			}
			if (b.conditionE=="") {
				return 1;
			}
			if (a.conditionE==b.conditionE) {
				if (a.invertConditionE==b.invertConditionE) {
					return a.fullPath.collate(b.fullPath); // both are equal; sort alphabetically
				} else {
					return a.invertConditionE ? 1 : -1; // the one with the condition not inverted goes first
				}
			}
			return (a.conditionE>b.conditionE ? 1 : -1);
		}

		/**
		 * Sorts all the elements to allow a better creation of the configuration file
		 */
		public void sortElements() {
			this.globalElements.sort(AutoVala.Globals.compareElements);
			foreach (var element in this.globalElements) {
				element.sortElements();
			}
		}
	}
}
