# AUTOVALA PLUGINS FOR TEXT EDITORS

Autovala includes several GTK widgets that simplifies creating plugins for text editors, like GEdit or Scratch Text Editor. These widgets are *ProjectView*, *ActionButtons*, *FileView*, *OutputView* and *SearchView*. The mandatory widget is *ProjectView*, which is also the central widget. All the other ones are optional.

## Using the plugins

All the plugins share the same style, since both uses the same widgets provided by Autovala.

There are two vertical panels, one with all the project targets and its source files, and another with all the files in the project. Doing double-click in a file will open it in the editor. Also, with right-click a context menu with more options will be shown. It allows to open the selected source file, to create a new executable/library target, or, if right-clicking on a target, open the properties dialog, which allows to change the target type (executable or library), change the base folder of the target, or set the compiler and linker option for that target. A target can also be deleted.

In the file view, a right click allows to create a new file or folder, rename or delete it, or choose to show or hide the hiden files.

Finally, there is a button and a popup menu that allows, the former, to start a new Autovala project, and the later to update the project (by running *autovala refresh* or *autovala update*), or the translation files (by running *autovala po*).

There are also two horizontal panels. The first one shows the output of running the autovala commans, after updating the project or the translation files. The second one allows to search strings in all the project's source files, specifying the file and the line for each occurrence. By double-clicking on each message, the file will be shown, and the cursor moved to the specific line.
