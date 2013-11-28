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

	class ElementGlobal : ElementBase {

		public ElementGlobal() {
			this._type = ConfigType.GLOBAL;
			this.command = "";
		}

		public override bool configureLine(string line, bool automatic, string? condition, bool invertCondition, int lineNumber) {
			return false;
		}

		public override bool generateCMakeHeader(DataOutputStream dataStream) {

			try {
				dataStream.put_string("### CMakeLists automatically created with AutoVala\n### Do not edit\n\n");
				dataStream.put_string("if(${CMAKE_INSTALL_PREFIX} MATCHES usr/local/? )\n");
				dataStream.put_string("\tset( AUTOVALA_INSTALL_PREFIX \"/usr/local\")\n");
				dataStream.put_string("else()\n");
				dataStream.put_string("\tset( AUTOVALA_INSTALL_PREFIX \"/usr\")\n");
				dataStream.put_string("endif()\n\n");
				dataStream.put_string("STRING (REPLACE \"/\" \";\" AUTOVALA_PATH_LIST ${CMAKE_INSTALL_PREFIX})\n");
				dataStream.put_string("SET (FINAL_AUTOVALA_PATH \"\")\n\n");
				dataStream.put_string("FOREACH(element ${AUTOVALA_PATH_LIST})\n");
				dataStream.put_string("\tIF (${FOUND_USR})\n");
				dataStream.put_string("\t\tSET(FINAL_AUTOVALA_PATH ${FINAL_AUTOVALA_PATH}/.. )\n");
				dataStream.put_string("\tELSE()\n");
				dataStream.put_string("\t\tIF(${element} STREQUAL \"usr\")\n");
				dataStream.put_string("\t\t\tSET(FOUND_USR 1)\n");
				dataStream.put_string("\t\t\tSET(FINAL_AUTOVALA_PATH ${FINAL_AUTOVALA_PATH}.. )\n");
				dataStream.put_string("\t\tENDIF()\n");
				dataStream.put_string("\tENDIF()\n");
				dataStream.put_string("ENDFOREACH()\n\n");
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to store a header"));
				return true;
			}
			return false;
		}
	}
}
