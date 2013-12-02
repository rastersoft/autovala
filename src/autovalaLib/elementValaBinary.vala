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

	public enum packageType {NO_CHECK, DO_CHECK, LOCAL}

	private class GenericElement:GLib.Object {
		public string elementName;
		public string? condition;
		public bool invertCondition;
		public bool automatic;
	}

	private class PackageElement:GenericElement {

		public packageType type;

		public PackageElement(string package, packageType type, bool automatic, string? condition, bool inverted) {
			this.elementName=package;
			this.type=type;
			this.automatic=automatic;
			this.condition=condition;
			this.invertCondition=inverted;
		}
	}

	private class SourceElement:GenericElement {

		public SourceElement(string source, bool automatic, string? condition, bool inverted) {
			this.elementName=source;
			this.automatic=automatic;
			this.condition=condition;
			this.invertCondition=inverted;
		}
	}

	private class VapiElement:GenericElement {

		public VapiElement(string vapi, bool automatic, string? condition, bool inverted) {
			this.elementName=vapi;
			this.automatic=automatic;
			this.condition=condition;
			this.invertCondition=inverted;
		}
	}

	private class CompileElement:GenericElement {
		public CompileElement(string options, bool automatic, string? condition, bool inverted) {
			this.elementName=options;
			this.automatic=automatic;
			this.condition=condition;
			this.invertCondition=inverted;
		}
	}

	private class ElementValaBinary : ElementBase {

		private string version;
		private bool versionSet;
		private bool versionAutomatic;

		private Gee.List<PackageElement ?> _packages;
		public Gee.List<PackageElement ?> packages {
			get {return this._packages;}
		}
		private Gee.List<SourceElement ?> _sources;
		public Gee.List<SourceElement ?> sources {
			get {return this._sources;}
		}
		private Gee.List<VapiElement ?> _vapis;
		private Gee.List<CompileElement ?> _compileOptions;

		private Gee.List<string> usingList;
		private Gee.List<string> defines;

		private string? _currentNamespace;
		public string ? currentNamespace {
			get {return this._currentNamespace;}
		}
		private bool namespaceAutomatic;
		private string? destination;

		private static bool addedValaBinaries;

		private GLib.Regex regexVersion;
		private GLib.Regex regexPackages;

		public ElementValaBinary() {
			this.command = "";
			this.version="1.0.0";
			this.versionSet=false;
			this.versionAutomatic=true;
			this._currentNamespace=null;
			this.usingList=null;
			this.defines=null;
			this.namespaceAutomatic=true;
			this.destination=null;
			this._packages=new Gee.ArrayList<PackageElement ?>();
			this._sources=new Gee.ArrayList<SourceElement ?>();
			this._vapis=new Gee.ArrayList<VapiElement ?>();
			this._compileOptions=new Gee.ArrayList<CompileElement ?>();
			ElementValaBinary.addedValaBinaries = false;
			try {
				this.regexVersion = new GLib.Regex("^[ \t]*// *project +version *= *[0-9]+.[0-9]+(.[0-9]+)?;?$");
				this.regexPackages = new GLib.Regex("^([ \t]*// *)?[Uu]sing +");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Can't generate the Regexps"));
			}
		}

		public static bool autoGenerate() {

			bool error=false;
			ElementBase.globalData.generateExtraData();
			if (false==ElementBase.globalData.checkExclude("src")) {
				var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"src"));

				if (filePath.query_exists()) {
					var element = new ElementValaBinary();
					error|=element.autoConfigure("src/"+ElementBase.globalData.projectName);
				}
			}
			foreach(var element in ElementBase.globalData.globalElements) {
				if ((element.eType==ConfigType.VALA_BINARY)||(element.eType==ConfigType.VALA_LIBRARY)) {
					var elementBinary = element as ElementValaBinary;
					elementBinary.checkDependencies();
				}
			}
			return error;
		}

		public override bool autoConfigure(string? path=null) {

			bool error = false;
			if (path != null) {
				this._type = ConfigType.VALA_BINARY;
				error |= this.configureElement(GLib.Path.get_dirname(path),
							GLib.Path.get_dirname(path),GLib.Path.get_basename(path),true,null,false);
				if (error) {
					return true;
				}
			}

			this.usingList = new Gee.ArrayList<string>();
			this.defines = new Gee.ArrayList<string>();
			
			foreach(var element in this._packages) {
				if (element.type!=packageType.LOCAL) {
					continue;
				}
				if (this.usingList.contains(element.elementName)==false) {
					this.usingList.add(element.elementName);
				}
			}

			var files = ElementBase.getFilesFromFolder(this._path,{".vala"},true,true);
			foreach (var element in files) {
				error |= this.addSource(element,true,null,false,-1);
				error |= this.processSource(element);
			}
			ElementBase.globalData.addExclude(this._path);
			return error;
		}

		private bool checkDependencies() {

			// Check which dependencies are resolved by local libraries
			foreach(var element in ElementBase.globalData.localModules.keys) {
				if (this.usingList.contains(element)) {
					this.usingList.remove(element);
				}
			}
			// Check which dependencies are already resolved by manually added packages
			foreach(var element in this._packages) {
				var namespaceP = ElementBase.globalData.vapiList.getNamespaceFromPackage(element.elementName);
				if ((namespaceP!=null)&&(this.usingList.contains(namespaceP))) {
					this.usingList.remove(namespaceP);
				}
			}

			// Finally, add the dependencies not resolved yet
			foreach(var element in ElementBase.globalData.vapiList.getNamespaces()) {
				if (this.usingList.contains(element)) {
					bool isCheckable=false;
					this.usingList.remove(element);
					var filename = ElementBase.globalData.vapiList.getPackageFromNamespace(element, out isCheckable);
					this.addPackage(filename,isCheckable ? packageType.DO_CHECK : packageType.NO_CHECK, true, null, false, -1);
				}
			}
			return false;
		}

		// Read a source file and extract all the data about it, like packages, program version, namespaces...
		private bool processSource(string pathP) {

			string line;
			string? version=null;
			int lineCounter=0;
			string regexString;
			MatchInfo regexMatch;

			string path = GLib.Path.build_filename(ElementBase.globalData.projectFolder,this._path,pathP);
			try {
				var file=File.new_for_path(path);
				var dis = new DataInputStream (file.read ());
				
				while ((line = dis.read_line (null)) != null) {
					if (version!=null) {
						if ((this.versionSet) && (version!=this.version)) {
							ElementBase.globalData.addWarning(_("File %s is overwritting the version number (line %d)").printf(pathP,lineCounter));
						} else {
							this.version=version;
							this.versionSet=true;
						}
						version=null;
					}
					lineCounter++;
					line=line.strip();
					 // add the version (old, deprecated format)
					if (line.has_prefix("const string project_version=\"")) {
						ElementBase.globalData.addWarning(_("The contruction 'const string project_version=...' in file %s is deprecated. Replace it with '// project version=...'").printf(pathP));
						var pos=line.index_of("\"",30);
						if (pos!=-1) {
							this.version=line.substring(30,pos-30);
						}
						continue;
					}
					// add the version
					if (this.regexVersion.match(line,0, out regexMatch)) {
						regexString = regexMatch.fetch(0);
						var pos = regexString.index_of("=");
						var pos2 = regexString.index_of(";");
						if (pos2==-1) {
							pos2 = regexString.length;
						}
						version=regexString.substring(pos+1,pos2-pos-1).strip();
						continue;
					}
					// add the packages used by this source file
					if (this.regexPackages.match(line,0, out regexMatch)) {
						regexString = regexMatch.fetch(0);
						var pos=regexString.index_of(";");
						var pos2=regexString.index_of("g ");
						if (pos==-1) {
							pos=regexString.length; // allow to put //using without a ; at the end, but also accept with it
						}
						var namespaceFound=regexString.substring(pos2+2,pos-pos2-2).strip();
						if (this.usingList.contains(namespaceFound)==false) {
							this.usingList.add(namespaceFound);
						}
						continue;
					}
					/* Check for these words to automatically add the gio package.
					 * Of course, this is NOT an exhaustive list, just the most common, to simplify the use.
					 * In case of needing the Gio package, and not using any of these words in your source, just
					 * add "//using GIO" */
					if ((-1!=line.index_of("FileInfo"))||(-1!=line.index_of("FileType"))||(-1!=line.index_of("FileEnumerator"))||
								(-1!=line.index_of("DataInputStream"))||(-1!=line.index_of("DataOutputStream"))||
								(-1!=line.index_of("FileInputStream"))||(-1!=line.index_of("FileOutputStream"))||
								(-1!=line.index_of("DBus"))||(-1!=line.index_of("Socket"))) {
						if (this.usingList.contains("GIO")==false) {
							this.usingList.add("GIO");
						}
					}
					if (line.has_prefix("namespace ")) {
						var pos=line.index_of("{");
						if (pos==-1) {
							pos=line.length;
						}
						var namespaceFound=line.substring(10,pos-10).strip();
						if ((this.currentNamespace!=null)&&(this.currentNamespace!=namespaceFound)) {
							ElementBase.globalData.addWarning(_("File %s is overwritting the namespace (line %d)").printf(pathP,lineCounter));
							continue;
						}
						this._currentNamespace=namespaceFound;
						continue;
					}
					if ((line.has_prefix("#if ")) || (line.has_prefix("#elif "))) { // Add #defines
						var pos=line.index_of(" ");
						string element=line.substring(pos).strip();
						// remove all logical elements to get a set of DEFINEs
						string[] elements=element.replace("&&"," ").replace("||"," ").replace("=="," ").replace("!="," ").replace("!"," ").replace("("," ").replace(")"," ").split(" ");
						foreach(var l in elements) {
							if ((l!="")&&(l.ascii_casecmp("true")!=0)&&(l.ascii_casecmp("false")!=0)&&(this.defines.contains(l)==false)) {
								var define=new ElementDefine();
								define.addNewDefine(l);
							}
						}
					}
				}
			} catch (Error e) {
				ElementBase.globalData.addError(_("Can't open for read the file %s").printf(pathP));
				return true;
			}
			return false;
		}

		public override void clearAutomatic() {

			if ((this.versionSet)&&(this.versionAutomatic)) {
				this.version="1.0.0";
				this.versionSet=false;
				this.versionAutomatic=true;
			}
			if ((this._currentNamespace!=null)&&(this.namespaceAutomatic)) {
				this._currentNamespace=null;
				this.namespaceAutomatic=true;
			}
			var packagesTmp=new Gee.ArrayList<PackageElement ?>();
			var sourcesTmp=new Gee.ArrayList<SourceElement ?>();
			var vapisTmp=new Gee.ArrayList<VapiElement ?>();
			var compileTmp=new Gee.ArrayList<CompileElement ?>();
			foreach (var e in this._packages) {
				if (e.automatic==false) {
					packagesTmp.add(e);
				}
			}
			foreach (var e in this._sources) {
				if (e.automatic==false) {
					sourcesTmp.add(e);
				}
			}
			foreach (var e in this._vapis) {
				if (e.automatic==false) {
					vapisTmp.add(e);
				}
			}
			foreach (var e in this._compileOptions) {
				if (e.automatic==false) {
					compileTmp.add(e);
				}
			}
			this._packages=packagesTmp;
			this._sources=sourcesTmp;
			this._vapis=vapisTmp;
			this._compileOptions=compileTmp;
		}

		public static int comparePackages (GenericElement? a, GenericElement? b) {
			if ((a.condition==null)&&(b.condition==null)) {
				return Posix.strcmp(a.elementName,b.elementName);
			}
			if (a.condition==null) {
				return -1;
			}
			if (b.condition==null) {
				return 1;
			}
			if (a.condition==b.condition) {
				if (a.invertCondition==b.invertCondition) {
					return Posix.strcmp(a.elementName,b.elementName); // both are equal; sort alphabetically
				} else {
					return a.invertCondition ? 1 : -1; // the one with the condition not inverted goes first
				}
			}
			return (Posix.strcmp(a.condition,b.condition));
		}

		public override void sortElements() {
			this._packages.sort(AutoVala.ElementValaBinary.comparePackages);
			this._sources.sort(AutoVala.ElementValaBinary.comparePackages);
			this._vapis.sort(AutoVala.ElementValaBinary.comparePackages);
			this._compileOptions.sort(AutoVala.ElementValaBinary.comparePackages);
		}

		private void transformToNonAutomatic(bool automatic) {
			if (automatic) {
				return;
			}
			this._automatic=false;
		}

		private bool checkVersion(string version) {
			return Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?$",version);
		}

		private bool setVersion(string version, bool automatic, int lineNumber) {

			if (this.checkVersion(version)) {
				this.version = version;
				this.versionSet = true;
				if (!automatic) {
					this.versionAutomatic=false;
				}
				this.transformToNonAutomatic(automatic);
				return false;
			} else {
				ElementBase.globalData.addError(_("Syntax error in VERSION statement (line %d)").printf(lineNumber));
				return true;
			}
		}

		private bool setNamespace(string namespaceT, bool automatic, int lineNumber) {
			if (this._currentNamespace==null) {
				this._currentNamespace=namespaceT;
				if (!automatic) {
					this.namespaceAutomatic=false;
				}
			} else {
				ElementBase.globalData.addWarning(_("Ignoring duplicated NAMESPACE command (line %d)").printf(lineNumber));
			}
			return false;
		}

		private bool setCompileOptions(string options,  bool automatic, string? condition, bool invertCondition, int lineNumber) {
			// if it is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic option to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var element=new CompileElement(options,automatic,condition,invertCondition);
			this._compileOptions.add(element);

			return false;
		}

		private bool setDestination(string destination, int lineNumber) {
			if (this.destination==null) {
				this.destination=destination;
			} else {
				ElementBase.globalData.addWarning(_("Ignoring duplicated DESTINATION command (line %d)").printf(lineNumber));
			}
			return false;
		}

		private bool addPackage(string package, packageType type, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			// if a package is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic package to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._packages) {
				if (element.elementName==package) {
					return false;
				}
			}

			var element=new PackageElement(package,type,automatic,condition,invertCondition);
			this._packages.add(element);
			return false;
		}

		private bool addSource(string sourceFile, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (condition!=null) {
				automatic=false; // if a source file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._sources) {
				if (element.elementName==sourceFile) {
					return false;
				}
			}
			var element=new SourceElement(sourceFile,automatic,condition, invertCondition);
			this._sources.add(element);
			return false;
		}

		private bool addVapi(string vapiFile, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (condition!=null) {
				automatic=false; // if a VAPI file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic VAPI to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._vapis) {
				if (element.elementName==vapiFile) {
					return false;
				}
			}
			var element=new VapiElement(vapiFile,automatic,condition, invertCondition);
			this._vapis.add(element);
			return false;
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (line.has_prefix("vala_binary: ")) {
				this._type = ConfigType.VALA_BINARY;
				this.command = "vala_binary";
			} else if (line.has_prefix("vala_library: ")) {
				this._type = ConfigType.VALA_LIBRARY;
				this.command = "vala_library";
			} else if (line.has_prefix("version: ")) {
				return this.setVersion(line.substring(9).strip(),automatic,lineNumber);
			} else if (line.has_prefix("namespace: ")) {
				return this.setNamespace(line.substring(11).strip(),automatic,lineNumber);
			} else if (line.has_prefix("compile_options: ")) {
				return this.setCompileOptions(line.substring(17).strip(),automatic, condition, invertCondition, lineNumber);
			} else if (line.has_prefix("vala_destination: ")) {
				return this.setDestination(line.substring(18).strip(),lineNumber);
			} else if (line.has_prefix("vala_package: ")) {
				return this.addPackage(line.substring(14).strip(),packageType.NO_CHECK,automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_check_package: ")) {
				return this.addPackage(line.substring(20).strip(),packageType.DO_CHECK,automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_local_package: ")) {
				return this.addPackage(line.substring(20).strip(),packageType.LOCAL,automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_source: ")) {
				return this.addSource(line.substring(13).strip(),automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_vapi: ")) {
				return this.addVapi(line.substring(11).strip(),automatic,condition,invertCondition,lineNumber);
			} else {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}

			var data=line.substring(2+this.command.length).strip();
			return this.configureElement(GLib.Path.get_dirname(data),GLib.Path.get_dirname(data),GLib.Path.get_basename(data),automatic,condition,invertCondition);
		}

		public override void endedCMakeFile() {
			ElementValaBinary.addedValaBinaries=false;
		}

		public override bool generateCMakeHeader(DataOutputStream dataStream) {

			try {
				if (ElementValaBinary.addedValaBinaries==false) {
					dataStream.put_string("set (DATADIR \"${AUTOVALA_INSTALL_PREFIX}/share\")\n");
					dataStream.put_string("set (PKGDATADIR \"${DATADIR}/"+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (GETTEXT_PACKAGE \""+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (RELEASE_NAME \""+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (CMAKE_C_FLAGS \"\")\n");
					dataStream.put_string("set (PREFIX ${CMAKE_INSTALL_PREFIX})\n");
					dataStream.put_string("set (VERSION \""+this.version+"\")\n");
					dataStream.put_string("set (DOLLAR \"$\")\n\n");
					if (this._path!="") {
						dataStream.put_string("configure_file (${CMAKE_SOURCE_DIR}/"+this._path+"/Config.vala.cmake ${CMAKE_BINARY_DIR}/"+this._path+"/Config.vala)\n");
					} else {
						dataStream.put_string("configure_file (${CMAKE_SOURCE_DIR}/Config.vala.cmake ${CMAKE_BINARY_DIR}/Config.vala)\n");
					}
					dataStream.put_string("add_definitions(-DGETTEXT_PACKAGE=\\\"${GETTEXT_PACKAGE}\\\")\n");
				}
				ElementValaBinary.addedValaBinaries=true;
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the header for binary file %s").printf(this.fullPath));
				return true;
			}
			return false;
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			string girFilename="";
			string libFilename=this.name;
			if (this._currentNamespace!=null) {
				// Build the GIR filename
				girFilename=this._currentNamespace+"-"+this.version.split(".")[0]+".0.gir";
				libFilename=this._currentNamespace;
			}

			string ?destination;
			if (this.destination==null) {
				destination=null;
			} else {
				if (this.destination[0]!='/') {
					destination=this.destination;
				} else {
					destination="${FINAL_AUTOVALA_PATH}%s".printf(this.destination);
				}
			}

			var fname=File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,this._path,"Config.vala.cmake"));
			try {
				if (fname.query_exists()) {
					fname.delete();
				}
				var dis = fname.create(FileCreateFlags.NONE);
				var dataStream2 = new DataOutputStream(dis);
				if ((this._type == ConfigType.VALA_LIBRARY) && (this._currentNamespace!=null)) {
					dataStream2.put_string("namespace "+libFilename+"Constants {\n");
				} else {
					dataStream2.put_string("namespace Constants {\n");
				}
				dataStream2.put_string("\tpublic const string DATADIR = \"@DATADIR@\";\n");
				dataStream2.put_string("\tpublic const string PKGDATADIR = \"@PKGDATADIR@\";\n");
				dataStream2.put_string("\tpublic const string GETTEXT_PACKAGE = \"@GETTEXT_PACKAGE@\";\n");
				dataStream2.put_string("\tpublic const string RELEASE_NAME = \"@RELEASE_NAME@\";\n");
				dataStream2.put_string("\tpublic const string VERSION = \"@VERSION@\";\n");
				dataStream2.put_string("}\n");
				dataStream2.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to create the Config.vala.cmake file"));
				return true;
			}

			try {
				string pcFilename=libFilename+".pc";

				if (this._type == ConfigType.VALA_LIBRARY) {
					fname=File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,this._path,libFilename+".pc"));
					if (fname.query_exists()) {
						fname.delete();
					}
					try {
						var dis = fname.create(FileCreateFlags.NONE);
						var dataStream2 = new DataOutputStream(dis);
						dataStream2.put_string("prefix=@AUTOVALA_INSTALL_PREFIX@\n");
						dataStream2.put_string("real_prefix=@CMAKE_INSTALL_PREFIX@\n");
						dataStream2.put_string("exec_prefix=@DOLLAR@{prefix}\n");
						dataStream2.put_string("libdir=@DOLLAR@{exec_prefix}/lib\n");
						dataStream2.put_string("includedir=@DOLLAR@{exec_prefix}/include\n\n");
						dataStream2.put_string("Name: "+libFilename+"\n");
						dataStream2.put_string("Description: "+libFilename+"\n");
						dataStream2.put_string("Version: "+this.version+"\n");
						dataStream2.put_string("Libs: -L@DOLLAR@{libdir} -l"+libFilename+"\n");
						dataStream2.put_string("Cflags: -I@DOLLAR@{includedir}\n");
						dataStream2.close();
					} catch (Error e) {
						ElementBase.globalData.addError(_("Failed to create the Config.vala.cmake file"));
						return true;
					}
					dataStream.put_string("configure_file (${CMAKE_CURRENT_SOURCE_DIR}/"+pcFilename+" ${CMAKE_CURRENT_BINARY_DIR}/"+pcFilename+")\n");
				}

				dataStream.put_string("set (VERSION \""+this.version+"\")\n");

				dataStream.put_string("add_definitions (${DEPS_CFLAGS})\n");

				bool addedPrefix=false;
				foreach(var module in this._packages) {
					if (module.type==packageType.LOCAL) {
						if (ElementBase.globalData.localModules.has_key(module.elementName)) {
							if (addedPrefix==false) {
								dataStream.put_string("include_directories ( ");
								addedPrefix=true;
							}
							dataStream.put_string("${CMAKE_BINARY_DIR}/"+ElementBase.globalData.localModules.get(module.elementName)+" ");
						} else {
							ElementBase.globalData.addWarning(_("Can't set package %s for binary %s").printf(module.elementName,this.name));
						}
					}
				}
				if (addedPrefix) {
					dataStream.put_string(")\n");
				}

				dataStream.put_string("link_libraries ( ${DEPS_LIBRARIES} ");
				foreach(var module in this._packages) {
					if ((module.type==packageType.LOCAL)&&(ElementBase.globalData.localModules.has_key(module.elementName))) {
						dataStream.put_string("-l"+module.elementName+" ");
					}
				}
				dataStream.put_string(")\n");
				dataStream.put_string("link_directories ( ${DEPS_LIBRARY_DIRS} ");
				foreach(var module in this._packages) {
					if ((module.type==packageType.LOCAL)&&(ElementBase.globalData.localModules.has_key(module.elementName))) {
						dataStream.put_string("${CMAKE_BINARY_DIR}/"+ElementBase.globalData.localModules.get(module.elementName)+" ");
					}
				}
				dataStream.put_string(")\n");
				dataStream.put_string("find_package (Vala REQUIRED)\n");
				dataStream.put_string("include (ValaVersion)\n");
				dataStream.put_string("ensure_vala_version (\"%d.%d\" MINIMUM)\n".printf(ElementBase.globalData.valaVersionMajor,ElementBase.globalData.valaVersionMinor));
				dataStream.put_string("include (ValaPrecompile)\n\n");

				var printConditions=new ConditionalText(dataStream,true);

				bool found_local=false;
				foreach(var module in this._packages) {
					if (module.type==packageType.LOCAL) {
						found_local=true;
						continue;
					}
					printConditions.printCondition(module.condition,module.invertCondition);
					dataStream.put_string("set (VALA_PACKAGES ${VALA_PACKAGES} %s)\n".printf(module.elementName));
				}
				printConditions.printTail();
				dataStream.put_string("\n");

				if ((this._type != ConfigType.VALA_LIBRARY)||(this._currentNamespace!="")) {
					dataStream.put_string("set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)\n");
				}
				foreach(var module in this._sources) {
					printConditions.printCondition(module.condition,module.invertCondition);
					dataStream.put_string("set (APP_SOURCES ${APP_SOURCES} %s)\n".printf(module.elementName));
				}
				printConditions.printTail();
				dataStream.put_string("\n");

				bool has_custom_VAPIs=false;
				if ((this._vapis.size!=0)||(found_local==true)) {
					foreach (var filename in this._vapis) {
						printConditions.printCondition(filename.condition,filename.invertCondition);
						dataStream.put_string("set (CUSTOM_VAPIS_LIST ${CUSTOM_VAPIS_LIST} ${CMAKE_SOURCE_DIR}/%s)\n".printf(Path.build_filename(this._path,filename.elementName)));
						has_custom_VAPIs=true;
					}
					printConditions.printTail();
					foreach(var module in this._packages) {
						if (module.type==packageType.LOCAL) {
							if (ElementBase.globalData.localModules.has_key(module.elementName)) {
								printConditions.printCondition(module.condition,module.invertCondition);
								dataStream.put_string("set (CUSTOM_VAPIS_LIST ${CUSTOM_VAPIS_LIST} ${CMAKE_BINARY_DIR}/%s)\n".printf(Path.build_filename(ElementBase.globalData.localModules.get(module.elementName), module.elementName +".vapi")));
								has_custom_VAPIs=true;
							}
						}
					}
					printConditions.printTail();
					dataStream.put_string("\n");
				}

				// Add all the DEFINEs set both in the code and the configuration file
				bool addDefines=false;
				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType==ConfigType.DEFINE) {
						addDefines=true;
						dataStream.put_string("if (%s)\n".printf(element.path));
						dataStream.put_string("\tset (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D %s)\n".printf(element.path));
						dataStream.put_string("endif ()\n");
					}
				}

				if (this._type == ConfigType.VALA_LIBRARY) {
					addDefines=true;
					// If it is a library, generate the Gobject Introspection file
					var finalOptions="--library="+libFilename;
					if (girFilename!="") {
						finalOptions+=" --gir "+girFilename;
					} else {
						ElementBase.globalData.addWarning(_("No namespace specified in library %s; GIR file will not be generated").printf(this.name));
					}
					dataStream.put_string("set (COMPILE_OPTIONS ${COMPILE_OPTIONS} %s )\n".printf(finalOptions));
				}

				foreach(var element in this._compileOptions) {
					addDefines=true;
					printConditions.printCondition(element.condition,element.invertCondition);
					dataStream.put_string("set (COMPILE_OPTIONS ${COMPILE_OPTIONS} %s )\n".printf(element.elementName));
				}
				printConditions.printTail();

				if (addDefines) {
					dataStream.put_string("\n");
				}

				dataStream.put_string("vala_precompile(VALA_C "+libFilename+"\n");
				dataStream.put_string("\t${APP_SOURCES}\n");
				dataStream.put_string("PACKAGES\n");
				dataStream.put_string("\t${VALA_PACKAGES}\n");
				if (has_custom_VAPIs) {
					dataStream.put_string("CUSTOM_VAPIS\n");
					dataStream.put_string("\t${CUSTOM_VAPIS_LIST}\n");
				}

				if (addDefines) {
					dataStream.put_string("OPTIONS\n");
					dataStream.put_string("\t${COMPILE_OPTIONS}\n");
				}

				if (this._type == ConfigType.VALA_LIBRARY) {
					// Generate both VAPI and headers
					dataStream.put_string("GENERATE_VAPI\n");
					dataStream.put_string("\t"+libFilename+"\n");
					dataStream.put_string("GENERATE_HEADER\n");
					dataStream.put_string("\t"+libFilename+"\n");
				}

				dataStream.put_string(")\n\n");
				if (this._type == ConfigType.VALA_LIBRARY) {
					dataStream.put_string("add_library("+libFilename+" SHARED ${VALA_C})\n\n");

					// Set library version number
					dataStream.put_string("set_target_properties( "+libFilename+" PROPERTIES\n");
					dataStream.put_string("VERSION\n");
					dataStream.put_string("\t"+this.version+"\n");
					dataStream.put_string("SOVERSION\n");
					dataStream.put_string("\t"+this.version.split(".")[0]+" )\n\n");

					// Install library
					dataStream.put_string("install(TARGETS\n");
					dataStream.put_string("\t"+libFilename+"\n");
					dataStream.put_string("LIBRARY DESTINATION\n");
					if (destination==null) {
						dataStream.put_string("\tlib/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(destination));
					}
					dataStream.put_string(")\n");

					// Install headers
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".h\n");
					dataStream.put_string("DESTINATION\n");
					if (destination==null) {
						dataStream.put_string("\tinclude/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(destination));
					}
					dataStream.put_string(")\n");

					// Install VAPI
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".vapi\n");
					dataStream.put_string("DESTINATION\n");
					if (destination==null) {
						dataStream.put_string("\tshare/vala/vapi/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(destination));
					}
					dataStream.put_string(")\n");

					// Install GIR
					if (girFilename!="") {
						dataStream.put_string("install(FILES\n");
						dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+girFilename+"\n");
						dataStream.put_string("DESTINATION\n");
					if (destination==null) {
						dataStream.put_string("\tshare/gir-1.0/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(destination));
					}
						dataStream.put_string(")\n");
					}

					// Install PC
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+pcFilename+"\n");
					dataStream.put_string("DESTINATION\n");
					if (destination==null) {
						dataStream.put_string("\tlib/pkgconfig/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(destination));
					}
					dataStream.put_string(")\n");

				} else {

					// Install executable
					dataStream.put_string("add_executable("+libFilename+" ${VALA_C})\n\n");
					dataStream.put_string("install(TARGETS\n");
					dataStream.put_string("\t"+libFilename+"\n");
					dataStream.put_string("RUNTIME DESTINATION\n");
					if (destination==null) {
						dataStream.put_string("\tbin/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(destination));
					}
					dataStream.put_string(")\n\n");
				}

				dataStream.put_string("if(HAVE_VALADOC)\n");
				dataStream.put_string("\tvaladoc("+libFilename+"\n");
				dataStream.put_string("\t\t${CMAKE_BINARY_DIR}/"+Path.build_filename("valadoc",libFilename)+"\n");
				dataStream.put_string("\t\t${APP_SOURCES}\n");
				dataStream.put_string("\tPACKAGES\n");
				dataStream.put_string("\t\t${VALA_PACKAGES}\n");
				dataStream.put_string("\tCUSTOM_VAPIS\n");
				dataStream.put_string("\t\t${CUSTOM_VAPIS_LIST}\n");
				dataStream.put_string("\t)\n");

				dataStream.put_string("\tinstall(DIRECTORY\n");
				dataStream.put_string("\t\t${CMAKE_BINARY_DIR}/valadoc\n");
				dataStream.put_string("\tDESTINATION\n");
				dataStream.put_string("\t\t"+Path.build_filename("share/doc",ElementBase.globalData.projectName)+"\n");
				dataStream.put_string("\t)\n");
				dataStream.put_string("endif()\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for binary %s").printf(libFilename));
				return true;
			}

			return false;
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				if (this._type == ConfigType.VALA_BINARY) {
					dataStream.put_string("vala_binary: %s\n".printf(Path.build_filename(this._path,this._name)));
				} else {
					dataStream.put_string("vala_library: %s\n".printf(Path.build_filename(this._path,this._name)));
				}
				if (this.versionSet) {
					if (this.versionAutomatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("version: %s\n".printf(this.version));
				}
				if ((this._currentNamespace!=null)&&(this._type==ConfigType.VALA_LIBRARY)) {
					if (this.namespaceAutomatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("namespace: %s\n".printf(this._currentNamespace));
				}
				if (this.destination!=null) {
					dataStream.put_string("vala_destination: %s\n".printf(this.destination));
				}

				foreach(var element in this._compileOptions) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("compile_options: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._packages) {
					if (element.type == packageType.LOCAL) {
						printConditions.printCondition(element.condition,element.invertCondition);
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("vala_local_package: %s\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._vapis) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("vala_vapi: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._packages) {
					if (element.type == packageType.NO_CHECK) {
						printConditions.printCondition(element.condition,element.invertCondition);
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("vala_package: %s\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._packages) {
					if (element.type == packageType.DO_CHECK) {
						printConditions.printCondition(element.condition,element.invertCondition);
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("vala_check_package: %s\n".printf(element.elementName));
					}
				}
				printConditions.printTail();

				foreach(var element in this._sources) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("vala_source: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store ': %s' at config").printf(this.fullPath));
				return true;
			}
			return false;
		}
		public override string[]? getSubFiles() {
			string[] subFileList = {};
			foreach (var element in this._sources) {
				subFileList += element.elementName;
			}
			return subFileList;
		}
	}
}
