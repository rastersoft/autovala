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

	class ConditionalText: GLib.Object {

		string? currentCondition;
		bool invertedCondition;
		DataOutputStream dataStream;
		bool cmakeFormat;

		public static Globals globalData = null;

		public ConditionalText(DataOutputStream stream,bool cmake) {
			this.dataStream=stream;
			this.cmakeFormat=cmake;
			this.reset();
		}

		public void reset() {
			this.currentCondition=null;
			invertedCondition=false;
		}

		public void printCondition(string? condition, bool inverted) {
			if (condition==this.currentCondition) {
				if ((condition!=null) && (inverted!=this.invertedCondition)) {
					try {
						if (this.cmakeFormat) {
							this.dataStream.put_string("else ()\n\t");
						} else {
							this.dataStream.put_string("else\n");
						}
					} catch (Error e) {
						ElementBase.globalData.addError(_("Failed to store ELSE condition at config"));
					}
					this.invertedCondition=inverted;
				}
			} else {
				this.invertedCondition=false;
				if(this.currentCondition!=null) {
					try {
						if (this.cmakeFormat) {
							this.dataStream.put_string("endif ()\n");
						} else {
							this.dataStream.put_string("end\n");
						}
					} catch (Error e) {
						ElementBase.globalData.addError(_("Failed to store ENDIF condition at config"));
					}
				}
				if(condition!=null) {
					if (inverted==false) {
						try {
							if (this.cmakeFormat) {
								this.dataStream.put_string("if (%s)\n\t".printf(condition));
							} else {
								this.dataStream.put_string("if %s\n".printf(condition));
							}
						} catch (Error e) {
							ElementBase.globalData.addError(_("Failed to store IF at config"));
						}
					} else {
						try {
							if (this.cmakeFormat) {
								this.dataStream.put_string("if (NOT(%s))\n\t".printf(condition));
							} else {
								this.dataStream.put_string("if %s\nelse\n".printf(condition));
							}
						} catch (Error e) {
							ElementBase.globalData.addError(_("Failed to store IF NOT/ELSE at config"));
						}
						this.invertedCondition=true;
					}
				}
				this.currentCondition=condition;
			}
		}

		public void printTail() {
			if (this.currentCondition!=null) {
				try {
					if (this.cmakeFormat) {
						this.dataStream.put_string("endif ()\n\n");
					} else {
						this.dataStream.put_string("end\n");
					}
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to store TAIL at config"));
				}
			}
			this.reset();
		}
	}
}
