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

namespace AutoVala {

	public enum ConfigType {GLOBAL, VALA_BINARY, VALA_LIBRARY, BINARY, ICON, PIXMAP, PO, GLADE, DBUS_SERVICE, DESKTOP, AUTOSTART,
							 EOS_PLUG, SCHEME, DATA, DOC, INCLUDE, IGNORE, CUSTOM, DEFINE, MANPAGE, BASH_COMPLETION, SOURCE_DEPENDENCY,
							 BINARY_DEPENDENCY, APPDATA, GRESOURCE, TRANSLATION, VAPIDIR, EXTERNAL }

	/**
	 * Represents a generic file of the project, with its path, filename, compilation condition...
	 * This class must be inherited by several subclasses, one for each kind of file allowed in AutoVala
	 * Also, each subclass must implement an static method to automagically find its files in a project, and this
	 * method must be added in the autovalaLib.vala file to be called each time the user asks for a refresh or update
	 */

	abstract class ElementBase : GLib.Object {

		public string[]? file_list = null;

		public static Globals globalData = null;
		public bool processed=false;

		protected string? _fullPath; // Full file path, relative to the project's root
		protected string _path; // File path relative to the project's root
		protected string _name; // File name
		protected ConfigType _type; // File type
		protected string command; // command in the config file

		public string[]? comments = null;

		public string? fullPath {
			get {return this._fullPath;}
		}
		public string path {
			get {return this._path;}
		}
		public string name {
			get {return this._name;}
		}
		public ConfigType eType {
			get {return this._type;}
		}

		protected string? _condition; // Condition (#if/#else/#end) for this file (null if there is no condition)
		protected bool _invertCondition; // When true, invert the condition (this is, the file is after the #else, not before)
		protected bool _automatic; // This file class has been filled automatically by AutoVala

		public bool automatic {
			get {return this._automatic;}
			set {this._automatic = value;}
		}

		public string? condition {
			get {return this._condition;}
		}

		public bool invertCondition {
			get {return this._invertCondition;}
		}

		public ElementBase() {
		}

		/**
		 * fills the list of files for this element
		 */
		public virtual void add_files() {

			this.file_list = {};
			var full_path = GLib.Path.build_filename(this._path, this._name);
			this.file_list += full_path;
		}

		/**
		 * Generates a list of files with the specified extensions, avoiding the files and folders listed at EXCLUDE list.
		 * @param folder The folder where to search for files
		 * @param extensions A list with all the file extensions to search (starting with a dot), or null to add all files
		 * @param recursive If true, will add the files from the specified folder and its subfolders
		 * @param removeFolder If true, will not prefix the paths and filenames with FOLDER
		 * @param masterFolder The current folder relative to the starting point (FOLDER)
		 *
		 * @returns A list with all the files with its relative path to the specified starting path
		 */

		public static string[] getFilesFromFolder(string folder, string[]? extensions, bool recursive, bool removeFolder=false, string ? masterFolder=null) {

			string[] files = {};

			var dirPath=File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,folder));
			if (dirPath.query_exists()==false) {
				ElementBase.globalData.addWarning(_("Directory %s doesn't exist").printf(folder));
				return files;
			}

			try {
				var enumerator = dirPath.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
				FileInfo file_info;
				while ((file_info = enumerator.next_file ()) != null) {
					var filename_get = file_info.get_name();
					// don't read hiden or backup files
					if (filename_get[0]=='.') {
						continue;
					}
					if (filename_get.has_suffix("~")) {
						continue;
					}

					var fname=Path.build_filename(folder,filename_get);
					string fname2;
					if (removeFolder) {
						if (masterFolder==null) {
							fname2=file_info.get_name();
						} else {
							fname2=Path.build_filename(masterFolder,file_info.get_name());
						}
					} else {
						fname2=fname;
					}
					if (ElementBase.globalData.checkExclude(fname)) {
						continue;
					}
					var ftype=file_info.get_file_type();
					if (ftype==GLib.FileType.DIRECTORY) {
						if (recursive) {
							var subDirs = ElementBase.getFilesFromFolder(fname,extensions,recursive, removeFolder, fname2);
							foreach (var element in subDirs) {
								files+=element;
							}
						}
						continue;
					}
					if ((ftype==GLib.FileType.REGULAR)||(ftype==GLib.FileType.SYMBOLIC_LINK)) {
						if (fname2.has_suffix("CMakeLists.txt")) {
							continue;
						}
						if (extensions==null) {
							files+=fname2;
						} else {
							foreach(var extension in extensions) {
								if (fname.has_suffix(extension)) {
									files+=fname2;
									break;
								}
							}
						}
					}
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Can't access folder %s").printf(folder));
				return files;
			}
			return files;
		}

		/**
		 * Configures the common file parameters
		 * @param fullPath The file path and file name, relative to the project's root
		 * @param path Only the file path, or null if it must be derived from fullPath
		 * @param name Only the file name, or null if it must be derived from fullPath
		 * @param automatic //true// if this file has been processed automatically; //false// if the user modified something manually in the configuration file
		 * @param condition The condition (#if / #else / #endif) for this file (or null if there is no compilation condition)
		 * @param invertCondition When true, invert the condition (this is, the file is after the #else statement)
		 * @return //true// if the file has been already processed
		 */
		public virtual bool configureElement(string? fullPathP, string? path, string? name, bool automatic, string? condition, bool invertCondition, bool accept_nonexisting_paths = false) {

			if (fullPathP == "") {
				ElementBase.globalData.addError(_("Trying to add an empty path: %s").printf(fullPath));
				return true;
			}

			string? fullPath = fullPathP;
			if (fullPath != null) {

				if (fullPath.has_suffix(Path.DIR_SEPARATOR_S)) {
					fullPath=fullPathP.substring(0,fullPathP.length-1);
				}

				if (ElementBase.globalData.checkExclude(fullPath)) {
					ElementBase.globalData.addWarning(_("Trying to add twice the path %s").printf(fullPath));
					return false;
				}
			}

			this._fullPath = fullPath;
			if ((path == null) || (name == null)) {
				GLib.File file;
				if ((fullPath != null) && (fullPath[0] == GLib.Path.DIR_SEPARATOR)) {
					file = File.new_for_path(fullPath);
				} else {
					file = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,fullPath));
				}
				if ((accept_nonexisting_paths == false) && (file.query_exists()==false)) {
					ElementBase.globalData.addWarning(_("File %s doesn't exist").printf(fullPath));
					return false;
				}
				if (file.query_file_type(FileQueryInfoFlags.NONE)!=FileType.DIRECTORY) {
					this._path = GLib.Path.get_dirname(fullPath);
					this._name = GLib.Path.get_basename(fullPath);
				} else {
					this._path = fullPath;
					this._name = "";
				}
			} else {
				this._path = path;
				this._name = name;
			}

			if ((this._path == ".") || (this._path == "./")) {
				ElementBase.globalData.addError(_("File %s is located at the project's root. Autovala doesn't allow that. You should move it into a folder.").printf(fullPath));
				return true;
			}

			ElementBase.globalData.addElement(this);
			if (fullPath != null) {
				ElementBase.globalData.addExclude(fullPath);
			}
			this._automatic = automatic;
			this._condition = condition;
			this._invertCondition = invertCondition;
			return false;
		}

		/**
		 * The Configuration class will call this method for each line in the configuration file that belong to it
		 * @param line The complete, unprocessed line from the configuration file, except for the (optional) asterisk as the first character
		 * @param automatic //true// if this file has been processed automatically; //false// if the user modified something manually in the configuration file
		 * @param condition The condition (#if / #else / #endif) for this file (or null if there is no compilation condition)
		 * @param invertCondition When true, invert the condition (this is, the file is after the #else statement)
		 * return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber,string[]? comments) {

			if (false == line.has_prefix(this.command+": ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}

			var data=line.substring(1+this.command.length).strip();
			this.comments = comments;

			return this.configureElement(data,null,null,automatic,condition,invertCondition);
		}

		/**
		 * Reads the file specified and adds automatically all its parameters
		 * @param path The file path (relative to the project root). If null, the object must reconfigure itself, taking into account the current values
		 * (this is needed when refreshing a file with manually-added elements)
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool autoConfigure(string? path=null) {

			if (path==null) {
				return false;
			}

			return this.configureElement(path,null,null,true,null,false);
		}

		/**
		 * Inserts the CMake commands needed for this file in the data stream specified
		 * @param dataStream The data stream for the CMakeList.txt file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool generateCMake(DataOutputStream dataStream) {
			return false;
		}

		/**
		 * Inserts the CMake commands needed for this file AT THE HEADER in the data stream specified. This allows to add definitions and other preparatory commands at the head of a file
		 * @param dataStream The data stream for the CMakeList.txt file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool generateCMakeHeader(DataOutputStream dataStream) {
			return false;
		}

		/**
		 * Inserts the CMake commands needed for this file AT ITS END in the data stream specified. This allows to add extra commands at the end of a file
		 * @param dataStream The data stream for the CMakeList.txt file being processed
		 * @param dataStreamGlobal The data stream for the main CMakeList.txt file being processed, to allow to add extra commands at its end
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool generateCMakePostData(DataOutputStream dataStream,DataOutputStream dataStreamGlobal) {
			return false;
		}

		/**
		 * Informs to the element that the current CMakeList.txt file has been completed
		 */
		public virtual void endedCMakeFile() {
		}

		/**
		 * Adds the specific data for this element to a Meson build file that must be added before anything
		 * @param dataStream The data stream for the meson.build file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool generateMesonHeader(ConditionalText dataStream, MesonCommon mesonCommon) {
			return false;
		}

		/**
		 * Adds the specific data for this element to a Meson build file
		 * @param dataStream The data stream for the meson.build file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {
			return false;
		}

		/**
		 * Notifies to all the objects that Autovala ended generating the meson script
		 */
		public virtual void endedMeson(MesonCommon mesonCommon) {
		}

		/**
		 * Removes all the automatic data in the element
		 */
		public virtual void clearAutomatic() {
		}

		/**
		 * Stores in the specified stream the configuration lines needed for this file
		 * @param dataStream The data stream for the CMakeList.txt file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool storeConfig(DataOutputStream dataStream, ConditionalText printConditions) {

			string data;
			if (this.fullPath == null) {
				data = this.name;
			} else {
				data = this.fullPath;
			}

			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("%s: %s\n".printf(this.command,data));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store '%s: %s' at config").printf(this.command,data));
				return true;
			}
			return false;
		}

		/**
		 * Sorts the subelements to allow a better creation of the configuration file
		 */
		public virtual void sortElements() {
			return;
		}

		/**
		 * Returns the sorting element, to allow to sort by any internal field
		 */
		public virtual string? getSortId() {
			return this.fullPath;
		}

		protected string? getRelativePath(string origin, string destination) {

			if (origin == destination) {
				return null;
			}

			string output = "";
			foreach(var element in origin.split("/")) {
				if (element != "") {
					output += "../";
				}
			}
			output += destination;
			return output;
		}
	}
}
