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

	public enum ConfigType {VALA_BINARY, VALA_LIBRARY, BINARY, ICON, PIXMAP, PO, GLADE, DBUS_SERVICE, DESKTOP, AUTOSTART,
							 EOS_PLUG, SCHEME, DATA, DOC, INCLUDE, IGNORE, CUSTOM, DEFINE, MANPAGE}

	/**
	 * Represents a generic file of the project, with its path, filename, compilation condition...
	 * This class must be inherited by several subclasses, one for each kind of file allowed in AutoVala
	 */

	abstract class ElementBase : GLib.Object {

		public static Globals globalData = null;

		protected string _fullPath; // Full file path, relative to the project's root
		protected string _path; // File path relative to the project's root
		protected string _file; // File name
		protected ConfigType _type; // File type
		protected string command; // command in the config file

		public string fullPath {
			get {return this._fullPath;}
		}
		public string path {
			get {return this._path;}
		}
		public string file {
			get {return this._file;}
		}
		public ConfigType eType {
			get {return this._type;}
		}

		protected string? condition; // Condition (#if/#else/#end) for this file (null if there is no condition)
		protected bool invertCondition; // When true, invert the condition (this is, the file is after the #else, not before)
		protected bool automatic; // This file class has been filled automatically by AutoVala

		public ElementBase() {
		}

		/**
		 * Configures the common file parameters
		 * @param path The file path, relative to the project's root
		 * @param automatic //true// if this file has been processed automatically; //false// if the user modified something manually in the configuration file
		 * @param condition The condition (#if / #else / #endif) for this file (or null if there is no compilation condition)
		 * @param invertCondition When true, invert the condition (this is, the file is after the #else statement)
		 * @return //true// if the file has been already processed
		 */
		public virtual bool configureElement(string fullPath, string? path, string? file, bool automatic, string? condition, bool invertCondition) {

			if (ElementBase.globalData.checkFile(fullPath)) {
				ElementBase.globalData.addError(_("Warning: trying to add again the path %s").printf(path));
				return true;
			}
			this._fullPath = fullPath;
			if (path==null) {
				this._path = GLib.Path.get_dirname(fullPath);
			} else {
				this._path=path;
			}
			if (file==null) {
				this._file = GLib.Path.get_basename(fullPath);
			}

			ElementBase.globalData.addFile(fullPath);
			this.automatic = automatic;
			this.condition = condition;
			this.invertCondition = invertCondition;
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
		public virtual bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			// The line starts with 'binary: '
			var data=line.substring(2+this.command.length).strip();

			return this.configureElement(data,null,null,automatic,condition,invertCondition);
		}

		/**
		 * Reads the file specified and adds automatically all its parameters
		 * @param path The file path (relative to the project root)
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool autoConfigure(string path) {

			return this.configureElement(path,null,null,true,null,false);
		}

		/**
		 * Inserts the CMake commands needed for this file in the data stream specified
		 * @param dataStream The data stream for the CMakeList.txt file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public abstract bool generateCMake(DataOutputStream dataStream, ConfigType type);

		/**
		 * Inserts the CMake commands needed for this file AT ITS END in the data stream specified. This allows to add extra commands at the end of a file
		 * @param dataStream The data stream for the CMakeList.txt file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool generateCMakePostData(DataOutputStream dataStream, ConfigType type) {
			return false;
		}

		/**
		 * If the element contains subelements, like a binary or library (which contains several source files), their paths and filenames can be retrieved with this method
		 * @return a list with all the paths and filenames, relative to the element path (so it is mandatory to add the project's root path and the element path to get the full path), or null if there are no need for paths or filenames in this element class
		 */
		public virtual string[]? getSubFiles() {
			return null;
		}

		/**
		 * Stores in the specified stream the configuration lines needed for this file
		 * @param dataStream The data stream for the CMakeList.txt file being processed
		 * @return //true// if there was an error; //false// if not. The error texts can be obtained by calling to returnErrors()
		 */
		public virtual bool storeConfig(DataOutputStream dataStream) {

			try {
				if (this.automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("%s: %s\n".printf(this.command,this.fullPath));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store '%s: %s' at config").printf(this.command,this.fullPath));
				return true;
			}
			return false;
		}

	}

/*		public string compile_options;
		public string icon_path;
		public string version;
		public string? destination;
		public string define;
		public string? language;
		public int section;
		public bool version_set;
		public bool version_manually_set;

		public Gee.List<package_element ?> packages;
		public Gee.List<source_element ?> sources;
		public Gee.List<vapi_element ?> vapis;
		public string current_namespace;
		public bool namespace_manually_set;


	}*/
}
