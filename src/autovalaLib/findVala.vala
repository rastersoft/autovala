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
	 * Searchs for all versions of Vala
	 */

	private class FindVala : GLib.Object {

		private Gee.List<ValaVersion> _versions;
		private ValaVersion? _defaultVersion;
		private weak ValaVersion? _maxVersion;

		public Gee.List<ValaVersion> versions {
			get { return this._versions; }
		}
		public ValaVersion? defaultVersion {
			get { return this._defaultVersion; }
		}
		public ValaVersion? maxVersion {
			get { return this._maxVersion; }
		}

		public FindVala() throws GLib.Error {

			this._versions = new Gee.ArrayList<ValaVersion>();
			this._defaultVersion = null;
			this._maxVersion = null;

			var lPaths = Environment.get_variable("PATH");
			var paths = lPaths.split(":");
			foreach(string path in paths) {
				this.checkPath(path);
			}
		}

		private void checkPath(string path) throws GLib.Error {

			var dirPath=File.new_for_path(path);
			if (dirPath.query_exists()==false) {
				return;
			}

			var enumerator = dirPath.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) {
				var ftype=file_info.get_file_type();
				if (ftype==GLib.FileType.DIRECTORY) {
					continue;
				}
				var fname=file_info.get_name();
				if ((this._defaultVersion == null) && (fname == "valac")) {
					var compiler = new ValaVersion();
					if (false == compiler.setValaVersion(Path.build_filename(path,"valac"))) {
						this._defaultVersion = compiler;
					}
					continue;
				}
				if (fname.has_prefix("valac-")) {
					var compiler = new ValaVersion();
					if (false == compiler.setValaVersion(Path.build_filename(path,fname))) {
						bool not_found = true;
						foreach (ValaVersion element in this._versions) {
							if ((element.major == compiler.major) && (element.minor == compiler.minor)) {
								not_found = false;
							}
						}
						if (not_found) {
							this._versions.add (compiler);
						}
						if (this._maxVersion != null) {
							if (this._maxVersion.major < compiler.major) {
								this._maxVersion = compiler;
							} else if ((this._maxVersion.major == compiler.major) && (this._maxVersion.minor < compiler.minor)) {
								this._maxVersion = compiler;
							}
						} else {
							this._maxVersion = compiler;
						}
					}
				}
			}
		}
	}

	private class ValaVersion : GLib.Object {

		public int major;
		public int minor;
		public string path;

		public ValaVersion() {
			this.major=0;
			this.minor=16;
		}

		/**
		 * Sets the version of Vala compiler passed in lPath.
		 * @param lPath The complete path to the vala compiler
		 * @return //false// if there was no error, //true// if the version can't be determined
		 */
		public bool setValaVersion (string lPath) {

			this.path = lPath;

			/*
			 * Maybe a not very elegant way of doing it. I accept patches
			 */

			string[] spawn_args = {lPath, "--version"};
			string ls_stdout;
			int ls_status;

			try {
				if (!Process.spawn_sync (null,spawn_args,Environ.get(),0,null,out ls_stdout,null,out ls_status)) {
					return true;
				}
				if (ls_status != 0) {
					return true;
				}
			} catch (SpawnError e) {
				return true;
			}

			var lines = ls_stdout.split("\n");
			foreach(var line in lines) {
				var version=line.split(" ");
				foreach(var element in version) {
					if (Regex.match_simple("^[0-9]+.[0-9]+(.[0-9]+)?",element)) {
						var numbers=element.split(".");
						this.major=int.parse(numbers[0]);
						this.minor=int.parse(numbers[1]);
						return false;
					}
				}
			}
			return true;
		}
	}
}
