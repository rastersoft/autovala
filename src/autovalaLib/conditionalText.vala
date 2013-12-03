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

	/**
	 * This class manages the conditional texts in the configuration and CMakeLists.txt files
	 * It decides when to write an 'if', an 'else' and an 'end'
	 */
	private class ConditionalText: GLib.Object {

		string? currentCondition;
		bool invertedCondition;
		DataOutputStream dataStream;
		bool cmakeFormat;

		public static Globals globalData = null;

		/**
		 * @param stream The file stream to which write the statements
		 * @param cmake //true// if we are writting to a CMakeLists.txt file; //false// if it is a .avprj file
		 */
		public ConditionalText(DataOutputStream stream,bool cmake) {
			this.dataStream=stream;
			this.cmakeFormat=cmake;
			this.reset();
		}

		/**
		 * Erases all the conditions and starts from scratch
		 */
		public void reset() {
			this.currentCondition=null;
			invertedCondition=false;
		}

		/**
		 * Prints, if needed, the current condition.
		 * @param condition The condition for the next statement to add to the file
		 * @param inverted Wether the condition is inverted (this is, the statement is after an 'else')
		 */
		public void printCondition(string? condition, bool inverted) {
			if (condition==this.currentCondition) {
				try {
					if (condition!=null) {
						/* if the condition for the next statement is the same than the condition of the
						 * previous statement, but the 'inverted' flag is different, we have to put an else
						 * to reverse the condition
						 */
						if (inverted!=this.invertedCondition) {
							if (this.cmakeFormat) {
								this.dataStream.put_string("else ()\n");
							} else {
								this.dataStream.put_string("else\n");
							}
							this.invertedCondition=inverted;
						}
						if (this.cmakeFormat) {
							this.dataStream.put_string("\t");
						}
					}
				} catch (Error e) {
					ElementBase.globalData.addError(_("Failed to store ELSE condition at config"));
				}
			} else {
				this.invertedCondition=false;
				/* If the condition for the next statement is different than the condition of the previous
				 * statement, and the previous statement was conditional, we have to close the previous if
				 */
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
				/* Now, if the next statement is conditional, we must start a new condition
				 */
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

		/* After printing all statements, we must close any possible condition previously opened */
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
