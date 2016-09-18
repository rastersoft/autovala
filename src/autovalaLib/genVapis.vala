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
using Posix;

namespace AutoVala {

	private class namespacesElement:GLib.Object {

		public string namespaceS;
		public string ? currentFile;
		public string filename;
		public Gee.List<string> filenames;
		public int major;
		public int minor;
		public bool checkable;

		public namespacesElement(string namespaceS) {
			this.namespaceS=namespaceS;
			this.filenames=new Gee.ArrayList<string>();
			this.currentFile=null;
			this.checkable=false;
		}
	}

	private class dependenciesElement:GLib.Object {
		public string[] dependencies;
		public string mainFile;

		public dependenciesElement(string mainFile) {
			this.mainFile = mainFile;
			this.dependencies={};
		}

		public void add_dependency(string dep) {
			this.dependencies+=dep;
		}
	}

	/**
	 * Reads all the VAPI files in the system and generates a list of the namespaces contained in each one.
	 * This allows to know which package add for each USING statement in the source code.
	 */
	private class ReadVapis:GLib.Object {

		private string[] errorList;
		private Gee.Map<string,namespacesElement?> ?namespaces;
		private Gee.Map<string,dependenciesElement?> ?dependencies;
		private ReadPkgConfig pkgConfigs;
		private GLib.Regex regexGirVersion;
		private GLib.Regex regexVersion;
		private GLib.Regex regexNamespace;

		/**
		 * @param major Major number of the version of Vala compiler currently installed
		 * @param minor Minor number of the version of Vala compiler currently installed
		 * @param local If true, want to process local VAPI files, not the system-wide ones
		 */
		public ReadVapis(int major, int minor, bool local=false) {

			this.errorList={};
			try {
				this.regexGirVersion=new GLib.Regex("gir_version( )*=( )*\"[0-9]+(.[0-9]+)?\"");
				this.regexVersion=new GLib.Regex("[0-9]+(.[0-9]+)?");
				this.regexNamespace=new GLib.Regex("^[ \t]*namespace[ ]+[^ \\{]+[ ]*");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Can't generate the regular expressions to read the VAPI files."));
			}

			this.namespaces=new Gee.HashMap<string,namespacesElement?>();
			this.dependencies=new Gee.HashMap<string,dependenciesElement?>();
			this.pkgConfigs=new ReadPkgConfig();

			if(local==false) {
				this.fillNamespaces("/usr/share/vala",true);
				this.fillNamespaces("/usr/share/vala-%d.%d".printf(major,minor),true);
				this.fillNamespaces("/usr/local/share/vala",true);
				this.fillNamespaces("/usr/local/share/vala-%d.%d".printf(major,minor),true);
			}
		}

		public string? get_pc_path(string module) {

			return this.pkgConfigs.find_path(module);
		}

		/**
		 * Returns all the namespaces found in the system
		 * @return a set with all the namespaces found
		 */
		public Gee.Set<string>getNamespaces() {
			return this.namespaces.keys;
		}

		/**
		 * For a given namespace, returns the package that provides it, and also if it is a library with
		 * a pkgconfig file.
		 * @param namespaceP The namespace to find
		 * @param checkable If //true//, the package has a pkgconfig file (like //Gtk//) and can be checked by CMake; if false, it is an //internal// package (like //Posix// or //Gio//)
		 * @return the greatest package version that implements that namespace, or //null// if no package implements it
		 */
		public string ? getPackageFromNamespace(string namespaceP, out bool checkable) {

			if (false == this.namespaces.has_key(namespaceP)) {
				checkable = false;
				return null;
			}
			var element = this.namespaces.get(namespaceP);
			checkable = element.checkable;
			return element.filename;
		}

		/**
		 * For a given package, returns which namespace(s) it contains. It is useful when the user adds
		 * a package manually and Autovala needs to know which namespaces are covered by it
		 * @param package The package to check
		 * @return A list with all the namespaces inside that package
		 */
		public string[] getNamespaceFromPackage(string package) {

			string[] retVal = {};
			foreach (var element in this.namespaces.keys) {
				var ns = this.namespaces.get(element);
				if (ns.filenames.contains(package)) {
					retVal += ns.namespaceS;
				}
			}
			return retVal;
		}

		/**
		 * For a given package, returns the list of checkable dependencies
		 * @param package The package to find
		 * @return A list with all the dependencies, or NULL if there are no checkable dependencies
		 */

		public string[] ? getDependenciesFromPackage(string package) {

			if (this.dependencies.has_key(package)==false) {
				return null;
			}

			string [] retVal = {};
			foreach (var element in this.dependencies[package].dependencies) {
				if (pkgConfigs.contains(element)) {
					retVal += element;
				}
			}
			return retVal;
		}

		/**
		 * Each time a VAPI file is found, it is called this function to add it to the namespacesElement with
		 * one of its namespaces (several VAPI files can offer the same namespace, like gtk-2.0 and gtk-3.0)
		 * @param element The namespacesElement to wich append this VAPI file
		 * @param filename The VAPI filename
		 * @param girMajor The major version of this VAPI GIR
		 * @param girMinor The minor version of this VAPI GIR
		 */
		private void addFile(namespacesElement element, string filename, int girMajor, int girMinor) {

			int cMajor;
			int cMinor;
			string file;
			string newfile;

			cMajor=girMajor;
			cMinor=girMinor;

			if (filename.has_suffix(".vapi")) {
				file=filename.substring(0,filename.length-5); // remove the .vapi extension
			} else {
				file=filename;
			}

			element.filenames.add(file);
			newfile=file;
			// if the filename has a version number, remove it
			if (Regex.match_simple("-[0-9]+(.[0-9]+)?$",file)) {
				var pos=file.last_index_of("-");
				newfile=file.substring(0,pos);
				// if there is no version number inside, use the one in the filename
				if ((cMajor==0)&&(cMinor==0)) {
					var version=file.substring(pos+1);
					pos=version.index_of(".");
					if (pos==-1) { // only one number
						cMajor=int.parse(version);
						cMinor=0;
					} else {
						cMajor=int.parse(version.substring(0,pos));
						cMinor=int.parse(version.substring(pos+1));
					}
				}
			}
			if (file==("gee-1.0")) {
				cMajor = 0;
				cMinor = 6;
			}


			// always take the shortest filename
			if ((element.currentFile==null)||(newfile.length<element.currentFile.length)) {
				element.currentFile=newfile;
				element.filename=file;
				element.major=cMajor;
				element.minor=cMinor;
				element.checkable=pkgConfigs.contains(file);
				return;
			}
			if (element.currentFile==newfile) {
				// for the same filename, take always the greatest version
				if((cMajor>element.major)||((cMajor==element.major)&&(cMinor>element.minor))) {
					element.major=cMajor;
					element.minor=cMinor;
					element.filename=file;
					element.checkable=pkgConfigs.contains(file);
					return;
				}
			}
		}

		/*
		 * This method checks the namespaces provided by a VAPI file and adds it to the corresponding elements
		 * in this.namespaces
		 * @param basepath The full path and filename to check
		 * @param fileP The filename alone
		 */
		public void checkVapiFile(string basepath, string fileP) {

			var file_f = File.new_for_path(basepath);
			int girMajor=0;
			int girMinor=0;
			MatchInfo foundString;
			MatchInfo foundVersion;
			try {
				var dis = new DataInputStream (file_f.read ());
				string line;
				string[] namespaceQueue = {};
				string lastNamespace="";
				while ((line = dis.read_line (null)) != null) {
					// Search for "gir_version" string
					if (regexGirVersion.match(line,0,out foundString)) {
						var girVersionString = foundString.fetch(0);
						if (regexVersion.match(girVersionString,0, out foundVersion)) {
							var version=foundVersion.fetch(0);
							var pos=version.index_of(".");
							if (pos==-1) { // single number
								girMajor=int.parse(version);
								girMinor=0;
							} else {
								var elements=version.split(".");
								girMajor=int.parse(elements[0]);
								girMinor=int.parse(elements[1]);
							}
						}
					}
					/* Search for namespaces. We have to do this complex thing to allow to find
					 * nested, multilevel namespaces inside a VAPI file
					 *
					 * If this line contains a namespace, read and store it in lastNamespace
					 * It will be added to the list when we find the '{' character that belongs to it
					 */

					if (regexNamespace.match(line,0,out foundString)) {
						// Take the regular expression found
						// Remove all prefix spaces and tabs
						// Take everything after "namespace" statement
						// remove all prefix spaces
						// split the string in statements (there can be an space and a '{' after the namespace)
						// the first one is the namespace
						lastNamespace = foundString.fetch(0).strip().substring(9).strip().split(" ")[0];
						if (lastNamespace=="GLib") { // GLib needs several tricks
							if (fileP.has_prefix("glib-")) {
							} else if (fileP.has_prefix("gio-unix-")) {
								lastNamespace="GIO-unix";
							} else if (fileP.has_prefix("gio")) {
								lastNamespace="GIO";
							} else if (fileP.has_prefix("gmodule-")) {
								lastNamespace="GModule";
							} else if (fileP.has_prefix("gobject-")) {
								lastNamespace="GObject";
							} else {
								ElementBase.globalData.addWarning(_("Unknown file %s uses namespace GLib. Contact the author.").printf(fileP));
								lastNamespace="";
							}
						}
					}

					var len = line.length;
					for (int l=0;l<len;l++) {
						/* each time we find a '{' character, we add another level;
						 * If we found previously a namespace then this '{' belongs to it,
						 * so add that namespace to the current level
						 */
						if (line[l] == '{') {
							namespaceQueue += lastNamespace;
							if (lastNamespace!="") {
								lastNamespace="";
								bool noFirst=false;
								string finalNamespace="";
								// Compose a namespace with all the namespaces up to the current level
								foreach(var element in namespaceQueue) {
									if (element!="") {
										if (noFirst) {
											finalNamespace+="."+element;
										} else {
											finalNamespace+=element;
											noFirst=true;
										}
									}
								}
								namespacesElement element;
								if (this.namespaces.has_key(finalNamespace)) {
									element=this.namespaces.get(finalNamespace);
								} else {
									element=new namespacesElement(finalNamespace);
									this.namespaces.set(finalNamespace,element);
								}
								this.addFile(element,fileP,girMajor,girMinor);
							}
						// When we find a '}' character, we remove the last level
						} else if (line[l]=='}') {
							var len2=namespaceQueue.length;
							if (len2>1) {
								len2--;
								string[] tmpQueue = {};
								for(int p=0;p<len2;p++) {
									tmpQueue+=namespaceQueue[p];
								}
								namespaceQueue=tmpQueue;
							} else {
								namespaceQueue = {};
							}
						}
					}
				}
			} catch (Error e) {
				//print("Error: %s\n".printf(e.message));
				return;
			}
		}

		private void checkDepsFile(string basepath,string library) {

			var file_f = File.new_for_path(basepath);
			if (file_f.query_exists()==false) {
				return;
			}

			var deps = new dependenciesElement(library);
			try {
				var dis = new DataInputStream (file_f.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					deps.add_dependency(line);
				}
			} catch (Error e) {
				return;
			}
			this.dependencies.set(library,deps);
		}

		/*
		 * Fills the NAMESPACES hashmap with a list of each namespace and the files that provides it, and also
		 * the "best" one (bigger version)
		 * @param basepath The path where to find VAPI files
		 */
		public void fillNamespaces(string basepath,bool inside_vapi = false) {

			string full_basepath;
			if (inside_vapi) {
				full_basepath = Path.build_filename(basepath,"vapi");
			} else {
				full_basepath = basepath;
			}
			var newpath=File.new_for_path(full_basepath);
			if (newpath.query_exists()==false) {
				return;
			}
			FileInfo fileInfo;
			FileEnumerator enumerator;
			try {
				enumerator = newpath.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
				while ((fileInfo = enumerator.next_file ()) != null) {
					var fname=fileInfo.get_name();
					var ftype=fileInfo.get_file_type();
					if (ftype==FileType.DIRECTORY) {
						continue;
					}
					if (fname.has_suffix(".vapi")==false) {
						continue;
					}
					this.checkVapiFile(Path.build_filename(full_basepath,fname),fname);
					var deps_name = fname.substring(0,fname.length-5); // remove the .vapi extension
					this.checkDepsFile(Path.build_filename(full_basepath,deps_name+".deps"),deps_name);
				}
			} catch (Error e) {
				return;
			}
		}
	}
}
