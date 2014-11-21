/*
 Copyright 2013/2014 (C) Raster Software Vigo (Sergio Costas)

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

	private class packages : Object {

		public string? author_package;
		public string? email_package;
		public string? web;
		public string? description;
		public string[] dependencies;
		public string[] source_dependencies;
		public string[] extra_dependencies;
		public string[] extra_source_dependencies;
		public Configuration config;

		public packages(string? basePath) {
			this.author_package = null;
			this.email_package = null;
			this.web = null;
			this.description = null;
			this.dependencies = {};
			this.source_dependencies = {};
			this.extra_dependencies = {};
			this.extra_source_dependencies = {};

			this.config = new AutoVala.Configuration(basePath);
			// Try to read the description from the README or README.md file
			if (!this.read_description(Path.build_filename(this.config.globalData.projectFolder,"README"))) {
				if (!this.read_description(Path.build_filename(this.config.globalData.projectFolder,"README.md"))) {
					this.description = "Not available";
				}
			}
			this.description = this.cut_lines(this.description,70);
		}

		private string cut_lines(string text, int columns) {

			var lines = text.split("\n");
			string final_text = "";

			foreach (var line in lines) {
				final_text += this.cut_line(line,columns)+"\n";
			}
			return final_text;
		}

		private string cut_line(string text, int columns) {

			string final_text = "";
			string tmp2 = "";

			int pos1;
			int pos2;
			int size = 0;
			int size2;
			int current_offset = 0;

			while(true) {
				pos1 = text.index_of_char(' ',current_offset);
				if (pos1 == -1) {
					if (size != 0) {
						final_text += tmp2+" ";
					}
					final_text += text.substring(current_offset);
					break;
				}
				size2 = pos1-current_offset;
				if (size != 0) {
					if (size+size2+1 < columns) {
						tmp2 += " "+text.substring(current_offset,size2);
						size += size2+1;
					} else {
						final_text += tmp2+"\n";
						tmp2 = "";
						size = 0;
					}
				}
				if (size == 0) {
					tmp2 = text.substring(current_offset,size2);
					size = size2;
				}
				current_offset += size2+1;
			}
			return final_text;
		}

		private bool read_description(string path) {

			string[] content = {};

			var file = File.new_for_path(path);
			if (!file.query_exists()) {
				return false;
			}
			try {
				var dis = new DataInputStream (file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					content+=line;
				}
			} catch (Error e) {
				return false;
			}

			string? last_line = null;
			string[] newcontent = {};
			// Replace double-line markdown elements with single-line ones
			foreach(var line in content) {
				if (this.check_line_has_single_char(line)) {
					if (last_line != null) {
						newcontent += "# "+last_line;
						last_line = null;
					}
				} else {
					if (last_line != null) {
						newcontent += last_line;
					}
					last_line = line;
				}
			}
			if (last_line != null) {
				newcontent += last_line;
			}

			// Now take only the first part in the markdown text

			bool started = false;
			string[] descr = {};
			foreach(var line in newcontent) {
				if (line.length == 0) {
					if (started) {
						descr+="";
					}
					continue;
				}
				if (line[0] == '#') {
					if (started) {
						break;
					} else {
						started = true;
					}
				} else {
					started = true;
					descr+=line;
				}
			}

			if (descr.length != 0) {
				string text = "";
				bool with_spaces = false;
				bool after_cr = true;
				foreach(var line in descr) {
					if (line != "") {
						if ((line[0] == ' ') || (line[0] == '\t')) {
							var tmpline = line.strip();
							if (tmpline == "") {
								text += "\n";
								after_cr = true;
								continue;
							}
							if (tmpline[0] == '*') {
								if (!after_cr) {
									text += "\n";
									after_cr = true;
								}
							} else {
								text += " "+tmpline;
								after_cr = false;
								continue;
							}
						}
						if (!after_cr) {
							text += " ";
						}
						text += line;
						after_cr = false;
					} else {
						if (!after_cr) {
							text += "\n\n";
						}
						after_cr = true;
					}
				}
				this.description = text;
			}
			return true;
		}

		private bool check_line_has_single_char(string line) {
			if (line.length == 0) {
				return false;
			}
			var character = line[0];
			if ((character != '=') && (character != '-')) {
				return false;
			}
			int c;
			for(c=0; c < line.length; c++) {
				if (line[c]!=character) {
					return false;
				}
			}
			return true;
		}
	}
}
