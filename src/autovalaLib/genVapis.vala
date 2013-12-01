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

	private class ReadVapis:GLib.Object {

		private string[] errorList;
		private Gee.Map<string,namespacesElement?> ?namespaces;
		private ReadPkgConfig pkgConfigs;

		public ReadVapis(int major, int minor) {

			this.errorList={};
			this.namespaces=new Gee.HashMap<string,namespacesElement?>();
			this.pkgConfigs=new ReadPkgConfig();

			this.fillNamespaces("/usr/share/vala");
			this.fillNamespaces("/usr/share/vala-%d.%d".printf(major,minor));
			this.fillNamespaces("/usr/local/share/vala");
			this.fillNamespaces("/usr/local/share/vala-%d.%d".printf(major,minor));
		}

		public Gee.Set<string>getNamespaces() {
			return this.namespaces.keys;
		}

		public string ? getPackageFromNamespace(string namespaceP, out bool checkable) {
			
			if (false == this.namespaces.has_key(namespaceP)) {
				checkable = false;
				return null;
			}
			var element = this.namespaces.get(namespaceP);
			checkable = element.checkable;
			return element.filename;
		}
		
		public string ? getNamespaceFromPackage(string package) {
			foreach (var element in this.namespaces.keys) {
				var ns = this.namespaces.get(element);
				if (ns.filenames.contains(package)) {
					return ns.namespaceS;
				}
			}
			return null;
		}

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

			if ((element.currentFile==null)||(newfile.length<element.currentFile.length)) { // always take the shortest filename
				element.currentFile=newfile;
				element.filename=file;
				element.major=cMajor;
				element.minor=cMinor;
				element.checkable=pkgConfigs.contains(file);
				return;
			}
			if (element.currentFile==newfile) { // for the same filename, take always the greatest version
				if((cMajor>element.major)||((cMajor==element.major)&&(cMinor>element.minor))) {
					element.major=cMajor;
					element.minor=cMinor;
					element.filename=file;
					element.checkable=pkgConfigs.contains(file);
					return;
				}
			}
		}

		private void checkVapiFile(string basepath, string fileP) {

			/*
			 * This method checks the namespaces provided by a .vapi file
			 */

			string file=fileP;
			if (file.has_suffix(".vapi")==false) {
				return;
			}
			file=file.substring(0,fileP.length-5); // remove the .vapi extension

			var file_f = File.new_for_path(basepath);
			int girMajor=0;
			int girMinor=0;
			MatchInfo foundString;
			MatchInfo foundVersion;
			try {
				var reg_expression=new GLib.Regex("gir_version( )*=( )*\"[0-9]+(.[0-9]+)?\"");
				var reg_expression2=new GLib.Regex("[0-9]+(.[0-9]+)?");
				var dis = new DataInputStream (file_f.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					if (reg_expression.match(line,0,out foundString)) {
						var girVersionString = foundString.fetch(0);
						if (reg_expression2.match(girVersionString,0, out foundVersion)) {
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
					if (line.has_prefix("namespace ")) {
						var namespaceS=line.split(" ")[1];
						if (namespaceS=="GLib") { // GLib needs several tricks
							if (fileP.has_prefix("glib-")) {
							} else if (fileP.has_prefix("gio-unix-")) {
								namespaceS="GIO-unix";
							} else if (fileP.has_prefix("gio")) {
								namespaceS="GIO";
							} else if (fileP.has_prefix("gmodule-")) {
								namespaceS="GModule";
							} else if (fileP.has_prefix("gobject-")) {
								namespaceS="GObject";
							} else {
								ElementBase.globalData.addWarning(_("Unknown file %s uses namespace GLib. Contact the author.").printf(fileP));
								namespaceS="";
							}
						}

						if (namespaceS!="") {
							namespacesElement element;
							if (this.namespaces.has_key(namespaceS)) {
								element=this.namespaces.get(namespaceS);
							} else {
								element=new namespacesElement(namespaceS);
								this.namespaces.set(namespaceS,element);
							}
							this.addFile(element,fileP,girMajor,girMinor);
						}
					}
				}
			} catch (Error e) {
				return;
			}
		}

		private void fillNamespaces(string basepath) {

			/*
			 * Fills the NAMESPACES hashmap with a list of each namespace and the files that provides it, and also the "best" one
			 * (bigger version)
			 */
			var newpath=File.new_for_path(Path.build_filename(basepath,"vapi"));
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
					this.checkVapiFile(Path.build_filename(basepath,"vapi",fname),fname);
				}
			} catch (Error e) {
				return;
			}
		}
	}
}
