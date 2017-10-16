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

	private class ElementInclude : ElementBase {

		private string? post_condition;
		private bool post_invertCondition;

		public ElementInclude() {
			this._type = ConfigType.INCLUDE;
			this.command = "include";
		}

		public override bool configureElement(string? fullPathP, string? path, string? name, bool automatic, string? condition, bool invertCondition, bool accept_nonexisting_paths = false) {

			this.post_condition = condition;
			this.post_invertCondition = invertCondition;

			return base.configureElement(fullPathP, path, name, automatic, null, false, accept_nonexisting_paths);

		}

		public override bool generateCMakePostData(DataOutputStream dataStream,DataOutputStream dataStreamGlobal) {

			try {
				var condition = new ConditionalText(dataStream,ConditionalType.CMAKE);
				condition.printCondition(this.post_condition,this.post_invertCondition);
				dataStream.put_string("\ninclude(${CMAKE_CURRENT_SOURCE_DIR}/"+this.name+")\n");
				condition.printTail();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write the CMakeLists file for %s").printf(this.name));
				return true;
			}
			return false;
		}

		public override bool generateMeson(ConditionalText dataStream, MesonCommon mesonCommon) {

			ElementBase.globalData.addWarning(_("This project has an INCLUDE statement, which is valid only for CMAKE. Maybe it will fail to build."));
			return false;

		}

		public override bool storeConfig(DataOutputStream dataStream,ConditionalText printConditions) {

			try {
				printConditions.printCondition(this.post_condition,this.post_invertCondition);
				return base.storeConfig(dataStream,printConditions);
			} catch (GLib.Error e) {
				ElementBase.globalData.addError(_("Failed to write at '%s' element, at '%s' path: %s").printf(this.command,this._path,e.message));
				return true;
			}
		}
	}
}
