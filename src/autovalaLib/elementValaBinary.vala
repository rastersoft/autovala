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

	public enum packageType {NO_CHECK, DO_CHECK, C_DO_CHECK, LOCAL}

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

	private class LibraryElement:GenericElement {
		public LibraryElement(string libraries, bool automatic, string? condition, bool inverted) {
			this.elementName=libraries;
			this.automatic=automatic;
			this.condition=condition;
			this.invertCondition=inverted;
		}
	}

	private class DBusElement:GenericElement {

		public string obj;
		public bool systemBus;
		public bool GDBus;

		public DBusElement(string destination, string obj, bool systemBus, bool GDBus, bool automatic) {
			this.elementName=destination;
			this.obj=obj;
			this.systemBus=systemBus;
			this.automatic=automatic;
			this.condition=null;
			this.invertCondition=false;
			this.GDBus=GDBus;
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
		private Gee.List<SourceElement ?> _cSources;
		public Gee.List<SourceElement ?> cSources {
			get {return this._cSources;}
		}
		private Gee.List<SourceElement ?> _unitests;
		public Gee.List<SourceElement ?> unitests {
			get {return this._unitests;}
		}
		private Gee.List<VapiElement ?> _vapis;
		private Gee.List<CompileElement ?> _compileOptions;
		private Gee.List<CompileElement ?> _compileCOptions;

		private Gee.List<DBusElement ?> _dbusElements;

		private Gee.List<string> usingList;
		private Gee.List<string> defines;
		private Gee.List<string> namespaces;

		private Gee.List<LibraryElement ?> _link_libraries;
		public Gee.List<LibraryElement ?> link_libraries {
			get {return this._link_libraries;}
		}

		private string? _currentNamespace;
		public string ? currentNamespace {
			get {return this._currentNamespace;}
		}
		private bool namespaceAutomatic;
		private string? destination;

		private static bool addedValaBinaries;
		private static bool addedLibraryWarning;

		private GLib.Regex regexVersion;
		private GLib.Regex regexPackages;
		private GLib.Regex regexClasses;

		public string get_vala_opts() {

			string opts = "";
			foreach(var element in this._compileOptions) {
				if (opts != "") {
					opts += " ";
				}
				opts+=element.elementName;
			}
			return opts;
		}

		public string get_c_opts() {

			string opts = "";
			foreach(var element in this._compileCOptions) {
				if (opts != "") {
					opts += " ";
				}
				opts+=element.elementName;
			}
			return opts;
		}

		public string get_libraries() {

			string libs = "";
			foreach(var element in this._link_libraries) {
				if (element.automatic==true) {
					continue; // don't put the automatically added ones
				}
				if (libs != "") {
					libs += " ";
				}
				libs+=element.elementName;
			}
			return libs;
		}

		public void set_name(string new_name) {
			if ((this._name != new_name) && (this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}
			this._name = new_name;
		}

		public void set_type(bool set_as_library) {
			if (set_as_library) {
				if ((this._type == ConfigType.VALA_BINARY) && (this._automatic==true)) {
					this.transformToNonAutomatic(false);
				}
				this._type = ConfigType.VALA_LIBRARY;
			} else {
				if ((this._type == ConfigType.VALA_LIBRARY) && (this._automatic==true)) {
					this.transformToNonAutomatic(false);
				}
				this._type = ConfigType.VALA_BINARY;
			}
		}

		public void set_path(string new_path) {
			if (((this._path != new_path) || (this._fullPath != new_path)) && (this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			this._path = new_path;
			this._fullPath = new_path;
		}

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
			this.namespaces=null;
			this._packages=new Gee.ArrayList<PackageElement ?>();
			this._sources=new Gee.ArrayList<SourceElement ?>();
			this._cSources=new Gee.ArrayList<SourceElement ?>();
			this._unitests=new Gee.ArrayList<SourceElement ?>();
			this._vapis=new Gee.ArrayList<VapiElement ?>();
			this._compileOptions=new Gee.ArrayList<CompileElement ?>();
			this._compileCOptions=new Gee.ArrayList<CompileElement ?>();
			this._dbusElements=new Gee.ArrayList<DBusElement ?>();
			this._link_libraries=new Gee.ArrayList<LibraryElement ?>();
			ElementValaBinary.addedValaBinaries = false;
			ElementValaBinary.addedLibraryWarning = false;
			try {
				this.regexVersion = new GLib.Regex("^[ \t]*// *project +version *= *[0-9]+.[0-9]+(.[0-9]+)?;?$");
				this.regexPackages = new GLib.Regex("^([ \t]*// *)?[Uu]sing +[^;]+;?");
				this.regexClasses = new GLib.Regex("^[ \t]*(public )?(private )?[ \t]*class[ ]+");
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Can't generate the Regexps"));
			}
		}

		private void add_library(string library) {

			foreach (var element in this._link_libraries) {
				var libs = element.elementName.split(" ");
				foreach (var lib in libs) {
					if (lib == "") {
						continue;
					}
					if (lib == library) {
						return; // that library already exists
					}
				}
			}
			this.setCLibrary(library, true, null, false, 0);
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
					elementBinary.checkVAPIs();
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
			this.namespaces = new Gee.ArrayList<string>();

			this.usingList.add("GLib"); // GLib is always needed

			foreach(var element in this._packages) {
				if (element.type!=packageType.LOCAL) {
					continue;
				}
				if (this.usingList.contains(element.elementName)==false) {
					this.usingList.add(element.elementName);
				}
			}

			// Don't add automatically the files inside dbus_generated, because they are
			// automatically (re)generated
			var dbusFolder=Path.build_filename(this._fullPath,"dbus_generated");
			ElementBase.globalData.addExclude(dbusFolder);

			// Check if there are unitary tests
			var unitestsFolder=Path.build_filename(this._path,"unitests");
			var files = ElementBase.getFilesFromFolder(unitestsFolder,{".vala"},true,true,"unitests");
			foreach (var element in files) {
				error |= this.addUnitest(element,true,null,false,-1);
			}
			unitestsFolder=Path.build_filename(this._fullPath,"unitests");
			ElementBase.globalData.addExclude(unitestsFolder);

			files = ElementBase.getFilesFromFolder(this._path,{".vala"},true,true);
			foreach (var element in files) {
				error |= this.addSource(element,true,null,false,-1);
				error |= this.processSource(element);
			}

			files = ElementBase.getFilesFromFolder(this._path,{".c"},true,true);
			foreach (var element in files) {
				error |= this.addCSource(element,true,null,false,-1);
			}

			ElementBase.globalData.addExclude(this._path);
			return error;
		}

		private void remove_self_package() {

			var tmpPackages = new Gee.ArrayList<PackageElement ?>();
			foreach(var element in this._packages) {
				if (element.elementName != this._currentNamespace) {
					tmpPackages.add(element);
				}
			}
			this._packages = tmpPackages;
		}

		public override void add_files() {

			this.file_list = {};

			this.file_list = ElementBase.getFilesFromFolder(this._path,{".vala",".c",".pc","deps",".cmake"},true);
			var files = ElementBase.getFilesFromFolder(GLib.Path.build_filename(this._path,"vapis"),{".vapi"},true);
			foreach (var element in files) {
				this.file_list += element;
			}
			files = ElementBase.getFilesFromFolder(GLib.Path.build_filename(this._path,"dbus_generated"),{".vala"},true);
			foreach (var element in files) {
				this.file_list+= element;
			}
		}

		private bool checkVAPIs() {

			var vapisPath=GLib.Path.build_filename(this._path,"vapis");
			if(ElementBase.globalData.checkExclude(vapisPath)) {
				return false;
			}

			var fullPath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,vapisPath));
			if (fullPath.query_exists()==false) {
				return false; // there's no VAPIS folder
			}
			var files = ElementBase.getFilesFromFolder(vapisPath,{".vapi"},true,true);
			bool error=false;
			foreach (var element in files) {
				error |= this.addVapi(GLib.Path.build_filename("vapis",element),true,null,false,-1);
			}
			ElementBase.globalData.addExclude(vapisPath);
			return error;
		}

		private bool checkDependencies() {

			// Check which dependencies are resolved by local libraries
			foreach(var element in ElementBase.globalData.localModules.keys) {
				if (this.usingList.contains(element)) {
					this.usingList.remove(element);
				}
			}

			// Check which dependencies are resolved by local VAPIs
			var spaceVapis = new ReadVapis(0,0,true);
			// Fill the namespaces defined in the VAPIs for this binary
			foreach(var element in this._vapis) {
				var fullPath = Path.build_filename(ElementBase.globalData.projectFolder,this._path,element.elementName);
				spaceVapis.checkVapiFile(fullPath,fullPath);
			}
			foreach(var element in spaceVapis.getNamespaces()) {
				if (this.usingList.contains(element)) {
					this.usingList.remove(element);
				}
			}

			// Check which dependencies are already resolved by manually added packages
			foreach(var element in this._packages) {
				var namespaces = Globals.vapiList.getNamespaceFromPackage(element.elementName);
				foreach (var namespaceP in namespaces) {
					if ((namespaceP!=null)&&(this.usingList.contains(namespaceP))) {
						this.usingList.remove(namespaceP);
					}
				}
			}

			// Finally, add the dependencies not resolved yet
			foreach(var element in Globals.vapiList.getNamespaces()) {
				if (this.usingList.contains(element)) {
					bool isCheckable=false;
					this.usingList.remove(element);
					var filename = Globals.vapiList.getPackageFromNamespace(element, out isCheckable);
					this.addPackage(filename,isCheckable ? packageType.DO_CHECK : packageType.NO_CHECK, true, null, false, -1);
					var dependencies = Globals.vapiList.getDependenciesFromPackage(filename);
					if (dependencies!=null) {
						foreach (var dep in dependencies) {
							this.addPackage(dep,packageType.DO_CHECK, true, null, false, -1);
						}
					}
				}
			}

			// If there are dependencies not resolved, show a warning message for each one
			foreach(var element in this.usingList) {
				if (this.namespaces.index_of(element) != -1) {
					continue;
				}
				ElementBase.globalData.addWarning(_("Can't resolve Using %s").printf(element));
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
				bool added_math = false;

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
					// add the packages used by this source file ("using" statement)
					if (this.regexPackages.match(line,0, out regexMatch)) {
						regexString = regexMatch.fetch(0);
						var pos=regexString.index_of(";");
						var pos2=regexString.index_of("g ");
						if (pos==-1) {
							pos=regexString.length; // allow to put //using without a ; at the end, but also accept with it
						}
						var namespaceFound=regexString.substring(pos2+2,pos-pos2-2).strip();
						if ((namespaceFound == "Math") || (namespaceFound == "GLib.Math")) {
							if (added_math == false) {
								added_math = true;
								this.add_library("m");
							}
							continue;
						}
						if (this.usingList.contains(namespaceFound)==false) {
							this.usingList.add(namespaceFound);
						}
						continue;
					}
					// Check if this source file uses classes, to add the gobject package
					if (this.regexClasses.match(line,0, out regexMatch)) {
						if (this.usingList.contains("GObject")==false) {
							this.usingList.add("GObject");
						}
					}
					/* Check for these words to automatically add the gio package.
					 * Of course, this is NOT an exhaustive list, just the most common, to simplify the use.
					 * In case of needing the Gio package, and not using any of these words in your source, just
					 * add "//using GIO" */
					if ((-1!=line.index_of("FileInfo"))||(-1!=line.index_of("FileType"))||
								(-1!=line.index_of("FileEnumerator"))||(-1!=line.index_of("GLib.File"))||
								(-1!=line.index_of("DataInputStream"))||(-1!=line.index_of("DataOutputStream"))||
								(-1!=line.index_of("FileInputStream"))||(-1!=line.index_of("FileOutputStream"))||
								(-1!=line.index_of("DBus"))||(-1!=line.index_of("Socket"))||
								(-1!=line.index_of("stdout."))||(-1!=line.index_of("stdin."))
								) {
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

						var topNamespaceFound = namespaceFound.split(".")[0];
						if ((this.currentNamespace!=null)&&(this.currentNamespace!=topNamespaceFound)) {
							ElementBase.globalData.addWarning(_("File %s is overwritting the namespace (line %d)").printf(pathP,lineCounter));
							continue;
						}
						this._currentNamespace=topNamespaceFound;
						if (this.namespaces.index_of(namespaceFound) == -1) {
							this.namespaces.add(namespaceFound);
						}
						continue;
					}
					if ((line.has_prefix("#if ")) || (line.has_prefix("#elif "))) { // Add #defines
						var pos=line.index_of(" ");
						string element=line.substring(pos).strip();
						// remove all logical elements to get a set of DEFINEs
						string[] elements=element.replace("&&"," ").replace("||"," ").replace("=="," ").replace("!="," ").replace("!"," ").replace("("," ").replace(")"," ").split(" ");
						foreach(var l in elements) {
							if ((l!="") && (l.ascii_casecmp("true")!=0) && (l.ascii_casecmp("false")!=0) && (this.defines.contains(l)==false) && (l.ascii_casecmp("UNITEST")!=0)) {
								var define=new ElementDefine();
								define.addNewDefine(l);
							}
						}
					}
				}
			} catch (GLib.Error e) {
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
			var unitestsTmp=new Gee.ArrayList<SourceElement ?>();
			var cSourcesTmp=new Gee.ArrayList<SourceElement ?>();
			var vapisTmp=new Gee.ArrayList<VapiElement ?>();
			var compileTmp=new Gee.ArrayList<CompileElement ?>();
			var dbusTmp=new Gee.ArrayList<DBusElement ?>();
			var librariesTmp=new Gee.ArrayList<LibraryElement ?>();

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
			foreach (var e in this._unitests) {
				if (e.automatic==false) {
					unitestsTmp.add(e);
				}
			}
			foreach (var e in this._cSources) {
				if (e.automatic==false) {
					cSourcesTmp.add(e);
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
			foreach (var e in this._dbusElements) {
				if (e.automatic==false) {
					dbusTmp.add(e);
				}
			}
			foreach (var e in this._link_libraries) {
				if (e.automatic==false) {
					librariesTmp.add(e);
				}
			}
			this._packages=packagesTmp;
			this._sources=sourcesTmp;
			this._unitests=unitestsTmp;
			this._cSources=cSourcesTmp;
			this._vapis=vapisTmp;
			this._compileOptions=compileTmp;
			this._dbusElements=dbusTmp;
			this._link_libraries=librariesTmp;
		}

		public static int comparePackages (GenericElement? a, GenericElement? b) {
			if (a.automatic!=b.automatic) {
				return (a.automatic ? 1 : -1); // put the manual ones first
			}
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
			this._cSources.sort(AutoVala.ElementValaBinary.comparePackages);
			this._unitests.sort(AutoVala.ElementValaBinary.comparePackages);
			this._vapis.sort(AutoVala.ElementValaBinary.comparePackages);
			this._compileOptions.sort(AutoVala.ElementValaBinary.comparePackages);
			this._dbusElements.sort(AutoVala.ElementValaBinary.comparePackages);
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

		public bool setCLibrary(string libraries,  bool automatic, string? condition, bool invertCondition, int lineNumber, bool erase_all=false) {

			if (erase_all) {
				// remove the manually added libraries
				var librariesTmp=new Gee.ArrayList<LibraryElement ?>();
				foreach (var e in this._link_libraries) {
					if (e.automatic==true) {
						librariesTmp.add(e);
					}
				}
				this._link_libraries = librariesTmp;
			}

			if (libraries == "") {
				return false;
			}

			// if it is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic library to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var element=new LibraryElement(libraries,automatic,condition,invertCondition);
			this._link_libraries.add(element);

			return false;
		}

		public bool setCompileOptions(string options,  bool automatic, string? condition, bool invertCondition, int lineNumber, bool erase_all=false) {

			if (erase_all) {
				this._compileOptions = new Gee.ArrayList<CompileElement ?>();
			}

			if (options == "") {
				return false;
			}

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

		public bool setCompileCOptions(string options,  bool automatic, string? condition, bool invertCondition, int lineNumber, bool erase_all=false) {

			if (erase_all) {
				this._compileOptions = new Gee.ArrayList<CompileElement ?>();
			}

			if (options == "") {
				return false;
			}

			// if it is conditional, it MUST be manual, because conditions are not added automatically
			if (condition!=null) {
				automatic=false;
			}

			// adding a non-automatic option to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var element=new CompileElement(options,automatic,condition,invertCondition);
			this._compileCOptions.add(element);

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
				if ((element.elementName==package) && ((automatic==true) || (element.type==type))) {
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

		private bool addUnitest(string unitestFile, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (condition!=null) {
				automatic=false; // if a source file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._unitests) {
				if (element.elementName==unitestFile) {
					return false;
				}
			}
			var element=new SourceElement(unitestFile,automatic,condition, invertCondition);
			this._unitests.add(element);
			return false;
		}

		private bool addCSource(string sourceFile, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (condition!=null) {
				automatic=false; // if a source file is conditional, it MUST be manual, because conditions are not added automatically
			}

			// adding a non-automatic source to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			foreach(var element in this._cSources) {
				if (element.elementName==sourceFile) {
					return false;
				}
			}
			var element=new SourceElement(sourceFile,automatic,condition, invertCondition);
			this._cSources.add(element);
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

		private bool addDBus(string DBusLine, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (condition!=null) {
				ElementBase.globalData.addError(_("DBus definitions can't be conditional (line %d)").printf(lineNumber));
				return true;
			}

			// adding a non-automatic DBUS definition to an automatic binary transforms this binary to non-automatic
			if ((automatic==false)&&(this._automatic==true)) {
				this.transformToNonAutomatic(false);
			}

			var datas=DBusLine.split(" ");
			string[] datas2={};
			foreach(var element in datas) {
				if (element!="") {
					datas2+=element;
				}
			}
			if ((datas2.length!=3) && (datas2.length!=4)) {
				ElementBase.globalData.addError(_("DBus definition must have three or four parameters (line %d)").printf(lineNumber));
				return true;
			}

			bool systemBus=false;
			if (datas2[2]=="system") {
				systemBus=true;
			} else if (datas2[2]=="session") {
				systemBus=false;
			} else {
				ElementBase.globalData.addError(_("DBus bus must be either 'system' or 'session' (line %d)").printf(lineNumber));
				return true;
			}

			bool GDBus=true;
			if (datas2.length==4) {
				if (datas2[3]=="gdbus") {
					GDBus=true;
				} else if (datas2[3]=="dbus-glib") {
					GDBus=false;
				} else {
					ElementBase.globalData.addError(_("DBus library must be either 'gdbus' or 'dbus-glib' (line %d)").printf(lineNumber));
					return true;
				}
			}

			foreach(var element in this._dbusElements) {
				if ((element.elementName==datas2[0])&&(element.obj==datas2[1])&&(element.systemBus==systemBus)) {
					return false;
				}
			}

			var element=new DBusElement(datas2[0],datas2[1],systemBus,GDBus,automatic);
			this._dbusElements.add(element);
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
			} else if (line.has_prefix("compile_c_options: ")) {
				return this.setCompileCOptions(line.substring(19).strip(),automatic, condition, invertCondition, lineNumber);
			} else if (line.has_prefix("vala_destination: ")) {
				return this.setDestination(line.substring(18).strip(),lineNumber);
			} else if (line.has_prefix("vala_package: ")) {
				return this.addPackage(line.substring(14).strip(),packageType.NO_CHECK,automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_check_package: ")) {
				return this.addPackage(line.substring(20).strip(),packageType.DO_CHECK,automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_local_package: ")) {
				return this.addPackage(line.substring(20).strip(),packageType.LOCAL,automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("c_check_package: ")) {
				return this.addPackage(line.substring(17).strip(),packageType.C_DO_CHECK,automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_source: ")) {
				return this.addSource(line.substring(13).strip(),automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("c_source: ")) {
				return this.addCSource(line.substring(10).strip(),automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("unitest: ")) {
				return this.addUnitest(line.substring(9).strip(),automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("vala_vapi: ")) {
				return this.addVapi(line.substring(11).strip(),automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("dbus_interface: ")) {
				return this.addDBus(line.substring(16).strip(),automatic,condition,invertCondition,lineNumber);
			} else if (line.has_prefix("c_library: ")) {
				return this.setCLibrary(line.substring(11).strip(),automatic,condition,invertCondition,lineNumber);
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

			int retval;

			// Delete the dbus_generated folder and recreate all the dbus interfaces
			var pathDbus=GLib.Path.build_filename(ElementBase.globalData.projectFolder,this._fullPath,"dbus_generated");
			var path = File.new_for_path(pathDbus);
			if(path.query_exists()) {
				try {
					Process.spawn_command_line_sync("rm -rf "+pathDbus);
				} catch (GLib.SpawnError e) {
					ElementBase.globalData.addWarning(_("Failed to delete the path %s").printf(pathDbus));
				}
			}
			if (this._dbusElements.size!=0) {
				foreach (var element in this._dbusElements) {
					var elementPathS=GLib.Path.build_filename(pathDbus,element.elementName,element.obj);
					var elementPath=File.new_for_path(elementPathS);
					try{
						elementPath.make_directory_with_parents();
					} catch (GLib.Error e) {
						ElementBase.globalData.addWarning(_("Failed to create the path %s").printf(elementPathS));
						continue;
					}
					string command="";
					string output="";
					string errorMsg="";
					int exitStatus;

					try {
						command = "dbus-send --%s --type=method_call --print-reply=literal --dest=%s %s org.freedesktop.DBus.Introspectable.Introspect".printf(element.systemBus ? "system" : "session",element.elementName,element.obj);
						if (!GLib.Process.spawn_command_line_sync(command,out output,out errorMsg,out exitStatus)) {
							ElementBase.globalData.addError(_("Can't find dbus-send command"));
							return true;
						}
						if (exitStatus!=0) {
							ElementBase.globalData.addWarning(_("Failed to execute '%s' with error message '%s'").printf(command,errorMsg.strip()));
							continue;
						}
					} catch (GLib.SpawnError e) {
						ElementBase.globalData.addError(_("Can't find dbus-send command"));
						return true;
					}

					FileOutputStream outputStream;
					try {
						GLib.File dbusFile=GLib.File.new_for_path("/tmp/dbus_data.xml");
						if (dbusFile.query_exists()) {
							dbusFile.delete();
						}
						outputStream = dbusFile.create(GLib.FileCreateFlags.NONE);
					} catch (GLib.Error e) {
						ElementBase.globalData.addWarning(_("Failed to check temporary file /tmp/dbus_data.xml"));
						continue;
					}

   					try {
						outputStream.write(output.data);
					} catch (GLib.IOError e) {
						ElementBase.globalData.addWarning(_("IOError: %s\n").printf(e.message));
						   return false;
					}


					if (element.GDBus) {
						command = "vala-dbus-binding-tool --gdbus --api-path=/tmp/dbus_data.xml --directory=%s".printf(elementPathS);
					} else {
						command = "vala-dbus-binding-tool --api-path=/tmp/dbus_data.xml --directory=%s".printf(elementPathS);
					}

					try {
						if (!Process.spawn_command_line_sync(command, null, null, out retval)) {
							ElementBase.globalData.addError(_("Can't find vala-dbus-binding-tool command"));
							return true;
						}
						if (retval!=0) {
							ElementBase.globalData.addWarning(_("Failed to generate the DBus interface for the object %s (%s) at the bus '%s'\n").printf(element.obj,element.elementName,element.systemBus ? "system" : "session"));
							continue;
						}
					} catch (GLib.SpawnError e) {
						ElementBase.globalData.addError(_("Can't find vala-dbus-binding-tool command"));
						return true;
					}

					var files = ElementBase.getFilesFromFolder(GLib.Path.build_filename(this._path,"dbus_generated"),{".vala"},true,true);
					foreach (var iface in files) {
					   this.addSource(GLib.Path.build_filename("dbus_generated",iface),true,null,false,-1);
					}
				}
			}


			try {
				if (ElementValaBinary.addedValaBinaries==false) {
					dataStream.put_string("set (DATADIR \"${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}\")\n");
					dataStream.put_string("set (PKGDATADIR \"${DATADIR}/"+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (GETTEXT_PACKAGE \""+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (RELEASE_NAME \""+ElementBase.globalData.projectName+"\")\n");
					dataStream.put_string("set (CMAKE_C_FLAGS \"\")\n");
					dataStream.put_string("set (PREFIX ${CMAKE_INSTALL_PREFIX})\n");
					dataStream.put_string("set (VERSION \""+this.version+"\")\n");
					dataStream.put_string("set (TESTSRCDIR \"${CMAKE_SOURCE_DIR}\")\n");
					dataStream.put_string("set (DOLLAR \"$\")\n\n");
					if (this._path!="") {
						dataStream.put_string("configure_file (${CMAKE_SOURCE_DIR}/"+this._path+"/Config.vala.cmake ${CMAKE_BINARY_DIR}/"+this._path+"/Config.vala)\n");
					} else {
						dataStream.put_string("configure_file (${CMAKE_SOURCE_DIR}/Config.vala.cmake ${CMAKE_BINARY_DIR}/Config.vala)\n");
					}
					dataStream.put_string("add_definitions(-DGETTEXT_PACKAGE=\\\"${GETTEXT_PACKAGE}\\\")\n");
				}
				ElementValaBinary.addedValaBinaries=true;
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write the header for binary file %s").printf(this.fullPath));
				return true;
			}
			return false;
		}

		public override bool generateCMakePostData(DataOutputStream dataStream) {

			if (ElementValaBinary.addedLibraryWarning == false) {
				ElementValaBinary.addedLibraryWarning = true;
				foreach(var element in ElementBase.globalData.globalElements) {
					if (element.eType==ConfigType.VALA_LIBRARY) {
						try {
							dataStream.put_string("\ninstall(CODE \"MESSAGE (\\\"\n************************************************\n* Run 'sudo ldconfig' to complete installation *\n************************************************\n\n\\\") \" )");
						} catch(GLib.Error e) {
							ElementBase.globalData.addError(_("Failed to append the 'run sudo ldconfig' message"));
							return true;
						}
						break;
					}
				}
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

			if (this._type == ConfigType.VALA_LIBRARY) {
				this.remove_self_package();
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
				dataStream2.put_string("#if UNITEST\n\tpublic const string TESTSRCDIR = \"@TESTSRCDIR@\";\n#endif\n");
				dataStream2.put_string("}\n");
				dataStream2.close();
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to create the Config.vala.cmake file"));
				return true;
			}

			try {
				string pcFilename=libFilename+".pc";
				string depsFilename=libFilename+".deps";

				if (this._type == ConfigType.VALA_LIBRARY) {
					fname=File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,this._path,pcFilename));
					if (fname.query_exists()) {
						fname.delete();
					}
					try {
						var dis = fname.create(FileCreateFlags.NONE);
						var dataStream2 = new DataOutputStream(dis);
						dataStream2.put_string("prefix=@CMAKE_INSTALL_PREFIX@\n");
						dataStream2.put_string("real_prefix=@CMAKE_INSTALL_PREFIX@\n");
						dataStream2.put_string("exec_prefix=@DOLLAR@{prefix}\n");
						dataStream2.put_string("libdir=@DOLLAR@{exec_prefix}/${CMAKE_INSTALL_LIBDIR}\n");
						dataStream2.put_string("includedir=@DOLLAR@{exec_prefix}/${CMAKE_INSTALL_INCLUDEDIR}\n\n");
						dataStream2.put_string("Name: "+libFilename+"\n");
						dataStream2.put_string("Description: "+libFilename+"\n");
						dataStream2.put_string("Version: "+this.version+"\n");
						dataStream2.put_string("Libs: -L@DOLLAR@{libdir} -l"+libFilename+"\n");
						dataStream2.put_string("Cflags: -I@DOLLAR@{includedir}\n");

						bool first = true;
						foreach(var module in this._packages) {
							if ((module.type != packageType.DO_CHECK) && (module.type != packageType.LOCAL)){
								continue;
							}
							if (first) {
								dataStream2.put_string("Requires:");
								first = false;
							}
							dataStream2.put_string(" %s".printf(module.elementName));
						}
						if (!first) {
							dataStream2.put_string("\n");
						}
						dataStream2.close();
					} catch (GLib.Error e) {
						ElementBase.globalData.addError(_("Failed to create the .PC file"));
						return true;
					}
					dataStream.put_string("configure_file (${CMAKE_CURRENT_SOURCE_DIR}/"+pcFilename+" ${CMAKE_CURRENT_BINARY_DIR}/"+pcFilename+")\n");

					fname=File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,this._path,depsFilename));
					if (fname.query_exists()) {
						fname.delete();
					}
					try {
						var dis = fname.create(FileCreateFlags.NONE);
						var dataStream2 = new DataOutputStream(dis);
						foreach(var module in this._packages) {
							if ((module.type == packageType.C_DO_CHECK)) {
								continue;
							}
							dataStream2.put_string("%s\n".printf(module.elementName));
						}
						dataStream2.close();
					} catch (GLib.Error e) {
						ElementBase.globalData.addError(_("Failed to create the .DEPS file"));
						return true;
					}
					dataStream.put_string("configure_file (${CMAKE_CURRENT_SOURCE_DIR}/"+depsFilename+" ${CMAKE_CURRENT_BINARY_DIR}/"+depsFilename+")\n");
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
					if (module.type==packageType.C_DO_CHECK) {
						continue;
					}
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
						dataStream.put_string("if (%s)\n".printf(element.name));
						dataStream.put_string("\tset (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D %s)\n".printf(element.name));
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

				bool addedCFlags=false;
				foreach(var element in this._compileCOptions) {
					addedCFlags=true;
					printConditions.printCondition(element.condition,element.invertCondition);
					dataStream.put_string("set (CMAKE_C_FLAGS ${CMAKE_C_FLAGS} \" %s \" )\n".printf(element.elementName));
				}
				printConditions.printTail();
				if (addedCFlags) {
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

				bool hasCFiles=false;
				foreach(var module in this._cSources) {
					hasCFiles=true;
					printConditions.printCondition(module.condition,module.invertCondition);
					dataStream.put_string("set (VALA_C ${VALA_C} %s)\n".printf(module.elementName));
				}
				printConditions.printTail();
				if (hasCFiles) {
					dataStream.put_string("\n");
				}

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
					if (this.destination==null) {
						dataStream.put_string("\t${CMAKE_INSTALL_LIBDIR}/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(this.destination));
					}
					dataStream.put_string(")\n");

					// Install headers
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".h\n");
					dataStream.put_string("DESTINATION\n");
					if (this.destination==null) {
						dataStream.put_string("\t${CMAKE_INSTALL_INCLUDEDIR}/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(this.destination));
					}
					dataStream.put_string(")\n");

					// Install VAPI
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".vapi\n");
					dataStream.put_string("DESTINATION\n");
					if (this.destination==null) {
						dataStream.put_string("\t${CMAKE_INSTALL_DATAROOTDIR}/vala/vapi/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(this.destination));
					}
					dataStream.put_string(")\n");

					// Install DEPS
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+libFilename+".deps\n");
					dataStream.put_string("DESTINATION\n");
					if (this.destination==null) {
						dataStream.put_string("\t${CMAKE_INSTALL_DATAROOTDIR}/vala/vapi/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(this.destination));
					}
					dataStream.put_string(")\n");

					// Install GIR
					if (girFilename!="") {
						dataStream.put_string("install(FILES\n");
						dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+girFilename+"\n");
						dataStream.put_string("DESTINATION\n");
					if (this.destination==null) {
						dataStream.put_string("\t${CMAKE_INSTALL_DATAROOTDIR}/gir-1.0/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(this.destination));
					}
						dataStream.put_string(")\n");
					}

					// Install PC
					dataStream.put_string("install(FILES\n");
					dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/"+pcFilename+"\n");
					dataStream.put_string("DESTINATION\n");
					if (this.destination==null) {
						dataStream.put_string("\t${CMAKE_INSTALL_LIBDIR}/pkgconfig/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(this.destination));
					}
					dataStream.put_string(")\n");

				} else {
					// Install executable
					dataStream.put_string("add_executable("+libFilename+" ${VALA_C})\n");
					foreach (var element in this._link_libraries) {
						printConditions.printCondition(element.condition,element.invertCondition);
						dataStream.put_string("target_link_libraries( "+libFilename+" "+element.elementName+" )\n");
					}
					printConditions.printTail();
					dataStream.put_string("\n");
					dataStream.put_string("install(TARGETS\n");
					dataStream.put_string("\t"+libFilename+"\n");
					dataStream.put_string("RUNTIME DESTINATION\n");
					if (this.destination==null) {
						dataStream.put_string("\t${CMAKE_INSTALL_BINDIR}/\n");
					} else {
						dataStream.put_string("\t%s\n".printf(this.destination));
					}
					dataStream.put_string(")\n\n");
				}

				// unitary tests
				if (this._unitests.size != 0) {
					dataStream.put_string("set (COMPILE_OPTIONS_UTEST ${COMPILE_OPTIONS} -D UNITEST)\n\n");
					int counter = 1;
					foreach (var unitest in this._unitests) {
						dataStream.put_string("set (APP_SOURCES_%d ${APP_SOURCES} %s)\n".printf(counter,unitest.elementName));
						dataStream.put_string("vala_precompile(VALA_C_%d %s\n".printf(counter,libFilename));
						dataStream.put_string("\t${APP_SOURCES_%d}\n".printf(counter));
						dataStream.put_string("PACKAGES\n");
						dataStream.put_string("\t${VALA_PACKAGES}\n");
						if (has_custom_VAPIs) {
							dataStream.put_string("CUSTOM_VAPIS\n");
							dataStream.put_string("\t${CUSTOM_VAPIS_LIST}\n");
						}

						dataStream.put_string("OPTIONS\n");
						dataStream.put_string("\t${COMPILE_OPTIONS_UTEST}\n");

						dataStream.put_string("DIRECTORY\n");
						dataStream.put_string("\t${CMAKE_CURRENT_BINARY_DIR}/unitests/test%d\n".printf(counter));

						dataStream.put_string(")\n\n");
						dataStream.put_string("add_executable( test%d ${VALA_C_%d})\n".printf(counter,counter));
						foreach (var element in this._link_libraries) {
							printConditions.printCondition(element.condition,element.invertCondition);
							dataStream.put_string("target_link_libraries( test%d %s)\n".printf(counter,element.elementName));
						}
						printConditions.printTail();
						dataStream.put_string("add_test(NAME test%d COMMAND test%d)\n".printf(counter,counter));
						dataStream.put_string("\n");
						counter++;
					}
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
				dataStream.put_string("\t\t"+Path.build_filename("${CMAKE_INSTALL_DATAROOTDIR}/doc",ElementBase.globalData.projectName)+"\n");
				dataStream.put_string("\t)\n");
				dataStream.put_string("endif()\n");
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for binary %s").printf(libFilename));
				return true;
			}
			return false;
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			if (this._type == ConfigType.VALA_LIBRARY) {
				this.remove_self_package();
			}

			try {
				dataStream.put_string("\n");
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

				foreach(var element in this._compileCOptions) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("compile_c_options: %s\n".printf(element.elementName));
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
					if (element.type == packageType.C_DO_CHECK) {
						printConditions.printCondition(element.condition,element.invertCondition);
						if (element.automatic) {
							dataStream.put_string("*");
						}
						dataStream.put_string("c_check_package: %s\n".printf(element.elementName));
					}
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

				foreach(var element in this._link_libraries) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("c_library: %s\n".printf(element.elementName));
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

				foreach(var element in this._unitests) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("unitest: %s\n".printf(element.elementName));
				}
				printConditions.printTail();

				foreach(var element in this._dbusElements) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("dbus_interface: %s %s %s %s\n".printf(element.elementName,element.obj,element.systemBus ? "system" : "session", element.GDBus ? "gdbus" : "dbus-glib"));
				}
				printConditions.printTail();

				foreach(var element in this._cSources) {
					printConditions.printCondition(element.condition,element.invertCondition);
					if (element.automatic) {
						dataStream.put_string("*");
					}
					dataStream.put_string("c_source: %s\n".printf(element.elementName));
				}
				printConditions.printTail();
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to store ': %s' at config").printf(this.fullPath));
				return true;
			}
			return false;
		}

		public string[]? getSubFiles() {
			string[] subFileList = {};
			foreach (var element in this._sources) {
				subFileList += element.elementName;
			}
			return subFileList;
		}

		public string[]? getCSubFiles() {
			string[] subFileList = {};
			foreach (var element in this._cSources) {
				subFileList += element.elementName;
			}
			return subFileList;
		}
	}
}
