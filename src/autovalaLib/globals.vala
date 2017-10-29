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

	/**
	 * Contains all the global parameters, like the project name, project folder, the current configuration file, and so on
	 */

	private class Globals : GLib.Object {

		public string projectName; // The project's name
		public string? projectFolder; // The absolute path to the project's root folder
		public string? configFile; // The absolute path to the project definition file

		public string? global_version; // The global version number

		public int valaMajor; // vala version currently installed in the system (major number)
		public int valaMinor; // vala version currently installed in the system (minor number)
		public int valaVersionMajor; // minimun vala version needed to compile the project (major number)
		public int valaVersionMinor; // minimun vala version needed to compile the project (minor number)
		public bool versionAutomatic; // if true, the compiler version in the file has been automatically detected (it has an asterisk in the file)

		public string[] excludeFiles; // A list with all the files and paths that must be avoided when doing automatic detection
		public Gee.List<ElementBase> globalElements; // The list of all elements

		public bool error; // There is at least one error message in the the error list
		public bool warning; // There is at least one warning message in the the error list
		private string[] errorList; // Contains all the messages to show to the user: normal messages, warnings and errors

		public Gee.Map<string,string> localModules;
		public Gee.Set<string> pathList;

		public static ReadVapis? vapiList = null;

		private static int _counter = 0;

		/**
		 * This counter is used for cases where different filenames are needed
		 */
		public static int counter {
				get {
					Globals._counter++;
					return _counter;
				}
		}

		public static void resetCounter() {
			Globals._counter = 0;
		}

		public Globals(string projectName, string ?searchPath = null) throws GLib.Error {

			ElementBase.globalData = this;
			ConditionalText.globalData = this;
			this.global_version = null;
			this.localModules = null;
			this.pathList = null;
			this.error = false;
			this.warning = false;
			this.projectName = projectName;
			this.projectFolder = null;
			this.globalElements = new Gee.ArrayList<ElementBase>();
			this.excludeFiles = {};
			this.getValaVersion();
			this.clearErrors();

			if (Globals.vapiList == null) {
				Globals.vapiList = new ReadVapis(this.valaMajor,this.valaMinor);
			}

			this.configFile = this.findConfiguration(searchPath);
			if (this.configFile != null) {
				this.projectFolder = GLib.Path.get_basename(this.configFile);
			} else {
				string[]? basePath;
				if (searchPath == null) {
					basePath=GLib.Environment.get_current_dir().split(Path.DIR_SEPARATOR_S);
				} else {
					basePath=searchPath.split(Path.DIR_SEPARATOR_S);
				}
				var len=basePath.length;
				while(len>=0) {
					var path=Path.DIR_SEPARATOR_S;
					for(var i=0;i<len;i++) {
						path=Path.build_filename(path,basePath[i]);
					}
					this.configFile=this.findConfiguration(path);
					if (this.configFile!=null) {
						this.projectFolder=path;
						break;
					}
					len--;
				}
			}
		}


		/**
		 * Generates several lists with extra data needed for several parts, like a list with all local modules, etc.
		 */
		public void generateExtraData() {

			this.localModules=new Gee.HashMap<string,string>();
			this.pathList=new Gee.HashSet<string>();
			foreach(var element in this.globalElements) {
				if ((element.eType!=ConfigType.IGNORE) && (element.eType!=ConfigType.DEFINE) && (element.eType!=ConfigType.SOURCE_DEPENDENCY)
						&& (element.eType!=ConfigType.BINARY_DEPENDENCY) && (element.eType!=ConfigType.INCLUDE) && (!this.pathList.contains(element.path))) {
					this.pathList.add(element.path);
				}
				if (element.eType==ConfigType.VALA_LIBRARY) {
					var elementLibrary = element as ElementValaBinary;
					if ((elementLibrary.currentNamespace!=null)&&(!this.localModules.has_key(elementLibrary.currentNamespace))) {
						this.localModules.set(elementLibrary.currentNamespace,elementLibrary.path);
					}
				}
				if (element.eType == ConfigType.VAPIDIR) {
					var fullpath = Path.build_filename(ElementBase.globalData.projectFolder,element.fullPath);
					AutoVala.Globals.vapiList.fillNamespaces(fullpath);
				}
			}
		}

		/**
		 * Removes the non-automatic elements
		 */

		public void clearAutomatic() {
			var newElements = new Gee.ArrayList<ElementBase>();
			this.excludeFiles={};
			foreach (var element in this.globalElements) {
				element.clearAutomatic();
				if (element.automatic==false) {
					newElements.add(element);
					if (element.fullPath != null) {
						this.addExclude(element.fullPath);
					}
				}
			}
			this.globalElements=newElements;
		}

		/**
		 * Inserts a new file structure in the global list
		 * @param element The file structure to add
		 */
		public void addElement(ElementBase element) {
			this.globalElements.add(element);
		}

/* Not needed
		public ElementBase[] findElements(AutoVala.ConfigType eType) {

			AutoVala.ElementBase[] elements = {};
			foreach(var element in this.globalElements) {
				if (element.eType == eType) {
					elements += element;
				}
			}
			return elements;
		}
*/

		/**
		 * Inserts a new file/path in the list of exclude files/paths
		 * @param file/path to add (with path relative to the project's root)
		 */
		public void addExclude(string filenameP) {
			var filename=filenameP;
			// add without the last '/'
			if(filename.has_suffix(Path.DIR_SEPARATOR_S)) {
				filename=filename.substring(0,filename.length-1);
			}
			if (false==this.checkExclude(filename)) {
				this.excludeFiles += filename;
			}
		}

		/**
		 * Checks whether a file/path is in the exclude list
		 * @param filename The file/path to check (with path relative to the project's root)
		 * @return //true// if the file is in the list; //false// if not
		 */
		public bool checkExclude(string filenameP) {
			string filename=filenameP;
			if(filename.has_suffix(Path.DIR_SEPARATOR_S)) {
				filename=filename.substring(0,filename.length-1);
			}
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
		private string? findConfiguration(string? basePath) {

			FileEnumerator enumerator;
			FileInfo info_file;
			string? full_path=null;
			string[] filename;
			string extension;
			FileType typeinfo;

			if (basePath == null) {
				return null;
			}
			var directory = File.new_for_path(basePath);
			try {
				enumerator = directory.enumerate_children(GLib.FileAttribute.STANDARD_NAME+","+GLib.FileAttribute.STANDARD_TYPE,GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null);
				while ((info_file = enumerator.next_file(null)) != null) {
					full_path=null;
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
				return null;
			}
			return (full_path);
		}

		/**
		 * Returns the version of Vala compiler installed in the system (the default one)
		 *
		 * @return //false// if there was no error, //true// if the version can't be determined
		 */

		public bool getValaVersion() {


			this.valaMajor=0;
			this.valaMinor=16;

			this.versionAutomatic = true;

			FindVala compilers;
			try {
				compilers = new FindVala();
				if (compilers == null) {
					return true;
				}
			} catch (GLib.Error e) {
				return true;
			}

			if (compilers.defaultVersion != null) {
				this.valaMajor = compilers.defaultVersion.major;
				this.valaMinor = compilers.defaultVersion.minor;
				return false;
			}

			if (compilers.maxVersion != null) {
				this.valaMajor = compilers.maxVersion.major;
				this.valaMinor = compilers.maxVersion.minor;
				return false;
			}
			return true;
		}

		/**
		 * Inserts an error in the error list
		 * @param error to add
		 */
		public void addError(string errorMsg) {
			this.error = true;
			// Shows an Error message
			this.errorList += "\033[1;31m%s\033[0m %s".printf(_("Error:"),errorMsg);
		}

		/**
		 * Inserts a warning in the error list
		 * @param warning to add
		 */
		public void addWarning(string warningMsg) {
			this.warning = true;
			// Shows a Warning message
			this.errorList += "\033[1;33m%s\033[0m %s".printf(_("Warning:"),warningMsg);
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

			var a_data = a.getSortId();
			var b_data = b.getSortId();

			if ((a.condition==null) && (b.condition==null)) {
				if ((a_data == null) && (b_data == null)) {
					return 0;
				}
				if (a_data == null) {
					return -1;
				}
				if (b_data == null) {
					return 1;
				}
				return Posix.strcmp(a_data,b_data);
			}
			if (a.condition==null) {
				return -1;
			}
			if (b.condition==null) {
				return 1;
			}
			if (a.condition==b.condition) {
				if (a.invertCondition == b.invertCondition) {
					if ((a_data == null) && (b_data == null)) {
						return 0;
					}
					if (a_data == null) {
						return -1;
					}
					if (b_data == null) {
						return 1;
					}
					return Posix.strcmp(a_data,b_data); // both are equal; sort alphabetically
				} else {
					return a.invertCondition ? 1 : -1; // the one with the condition not inverted goes first
				}
			}
			return (Posix.strcmp(a.condition,b.condition));
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
