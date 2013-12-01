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
//using GIO;

namespace AutoVala {

	class ElementManPage : ElementBase {

		private string? language;
		private int pageSection;

		public ElementManPage() {
			this._type = ConfigType.MANPAGE;
			this.command = "manpage";
		}

		private static bool autoGenerateLocal(string extension) {
			bool error=false;
			var filePath = File.new_for_path(Path.build_filename(ElementBase.globalData.projectFolder,"data/man"));
			if (filePath.query_exists()) {
				string[] extensions = {".1"+extension,".2"+extension,".3"+extension,".4"+extension,".5"+extension,".6"+extension,".7"+extension,".8"+extension,".9"+extension};
				var files = ElementBase.getFilesFromFolder("data/man",extensions,true);
				foreach (var file in files) {
					var element = new ElementManPage();
					error|=element.autoConfigure(file);
				}
			}
			return error;
		}

		public static bool autoGenerate() {

			bool error=false;

			error |= ElementManPage.autoGenerateLocal("");
			error |= ElementManPage.autoGenerateLocal(".md");
			error |= ElementManPage.autoGenerateLocal(".rst");
			error |= ElementManPage.autoGenerateLocal(".htm");
			error |= ElementManPage.autoGenerateLocal(".html");
			error |= ElementManPage.autoGenerateLocal(".tex");
			error |= ElementManPage.autoGenerateLocal(".json");
			error |= ElementManPage.autoGenerateLocal(".rdoc");
			error |= ElementManPage.autoGenerateLocal(".xml");
			error |= ElementManPage.autoGenerateLocal(".txt");

			return error;
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {

			if (false == line.has_prefix("manpage: ")) {
				var badCommand = line.split(": ")[0];
				ElementBase.globalData.addError(_("Invalid command %s after command %s (line %d)").printf(badCommand,this.command, lineNumber));
				return true;
			}
			// The line starts with 'manpage: '
			var data=line.substring(9).strip();
			string filename;

			this.language = null;
			this.pageSection = 1;
			var elements=data.split(" ");
			switch (elements.length) {
			default:
				ElementBase.globalData.addError(_("Manpage command needs one, two or three parameters (line %d)").printf(lineNumber));
				return true;
			case 1: // manpage in default language, section 1
				filename=elements[0];
			break;
			case 2: // manpage in specific language, section 1
				filename=elements[0];
				if (elements[1]!="default") {
					language=elements[1];
				}
			break;
			case 3: // manpage in specific language and custom section
				filename=elements[0];
				if (elements[1]!="default") {
					language=elements[1];
				}
				pageSection=int.parse(elements[2]);
				if ((pageSection<1)||(pageSection>9)) {
					ElementBase.globalData.addError(_("Man page section must be a number between 1 and 9 (line %d)").printf(lineNumber));
					return true;
				}
			break;
			}
			return this.configureElement(filename,null,null,automatic,condition,invertCondition);
		}

		public override bool autoConfigure(string? path=null) {
			
			if (path==null) {
				return false;
			}

			var elements = path.split(Path.DIR_SEPARATOR_S);
			var len = elements.length;

			string pageName = elements[len-1];
			this.language = null;
			if (len>3) {
				this.language = elements[2];
			}

			var fname=pageName.split(".");
			len=fname.length-1;
			string extension;
			this.pageSection=1;
			for(;len>0;len--) {
				extension=fname[len];
				if (extension.length!=1) {
					continue;
				}
				if ((extension[0]<'1')||(extension[0]>'9')) {
					continue;
				}
				this.pageSection=extension[0]-'0';
				break;
			}
			return this.configureElement(pageName,null,null,true,null,false);
		}

		public override bool generateCMake(DataOutputStream dataStream) {

			string finalFile="";
			string? inputFormat=null;
			if (this.name.has_suffix(".md")) {
				finalFile=this.name.substring(0,this.name.length-3);
				inputFormat="markdown_github";
			} else if (this.name.has_suffix(".rst")) {
				finalFile=this.name.substring(0,this.name.length-4);
				inputFormat="rst";
			} else if (this.name.has_suffix(".htm")) {
				finalFile=this.name.substring(0,this.name.length-4);
				inputFormat="html";
			} else if (this.name.has_suffix(".html")) {
				finalFile=this.name.substring(0,this.name.length-5);
				inputFormat="html";
			} else if (this.name.has_suffix(".tex")) {
				finalFile=this.name.substring(0,this.name.length-4);
				inputFormat="latex";
			} else if (this.name.has_suffix(".json")) {
				finalFile=this.name.substring(0,this.name.length-4);
				inputFormat="json";
			} else if (this.name.has_suffix(".rdoc")) {
				finalFile=this.name.substring(0,this.name.length-5);
				inputFormat="textile";
			} else if (this.name.has_suffix(".xml")) {
				finalFile=this.name.substring(0,this.name.length-4);
				inputFormat="docbook";
			} else if (this.name.has_suffix(".txt")) {
				finalFile=this.name.substring(0,this.name.length-4);
				inputFormat="mediawiki";
			} else {
				finalFile=this.name;
			}

			try {
				if (inputFormat==null) {
					dataStream.put_string("configure_file ( ${CMAKE_CURRENT_SOURCE_DIR}/" + this.name + " ${CMAKE_CURRENT_BINARY_DIR}/" + finalFile + " COPYONLY )\n");
				} else {
					dataStream.put_string("execute_process ( COMMAND pandoc ${CMAKE_CURRENT_SOURCE_DIR}/" + this.name + " -o ${CMAKE_CURRENT_BINARY_DIR}/" + finalFile + " -f " + inputFormat + " -t man -s )\n");
				}

				dataStream.put_string("execute_process ( COMMAND gzip -f ${CMAKE_CURRENT_BINARY_DIR}/" + finalFile + " )\n");
				finalFile+=".gz";
				dataStream.put_string("install(FILES ${CMAKE_CURRENT_BINARY_DIR}/" + finalFile + " DESTINATION share/man/");
				if (this.language!=null) {
					dataStream.put_string(this.language+"/");
				}
				dataStream.put_string("man%d/ )\n\n".printf(this.pageSection));
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to install MANpages at %s").printf(this.fullPath));
				return true;
			}

			return false;
		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			try {
				if (this._automatic) {
					dataStream.put_string("*");
				}
				dataStream.put_string("manpage: "+this.fullPath);
				if ((this.language!=null) || (this.pageSection!=1)) {
					if (this.language!=null) {
						dataStream.put_string(" "+this.language);
					} else {
						dataStream.put_string(" default");
					}
				}
				if (this.pageSection!=1) {
					dataStream.put_string(" %d".printf(this.pageSection));
				}
				dataStream.put_string("\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store 'manpage: %s' at config").printf(this.fullPath));
				return true;
			}
			return false;
		}
	}
}
