{CompositeDisposable,File,Directory} = require 'atom'
{TreeView} = require './treeview'

fs = require 'fs'
path = require 'path'

module.exports = AutovalaAtom =
	myView: null
	changingPane: null
	projectFileCheck: null
	currentProjectFile: null
	lastPaths: null
	path: null

	projectFileChanged: ->
		if @currentProjectFile is null
			@myView.hide()
			return
		@myView.show()
		f = new File(@currentProjectFile)
		basePath = @path.dirname(@currentProjectFile)
		# this is mandatory to be able to access the object from inside the dataRead promise
		tmpthis = this
		dataRead = f.read(true)
		.then (content) ->
			lines = content.split("\n")
			data = []
			data.push({label: f.getBaseName(), icon: "autovala_project", customData: tmpthis.currentProjectFile})
			while lines.length != 0
				line = lines[0].trim()
				lines.shift()
				if line == ""
					continue
				if line[0] == '*'
					line = line.substring(1)
				if (line.startsWith("vala_binary:")) or (line.startsWith("vala_library:"))
					if (line.startsWith("vala_binary:"))
						valaName = tmpthis.path.basename(line.substring(12))
						valaIcon = "autovala_application"
						binaryPath = tmpthis.path.dirname(line.substring(12).trim())
					else
						valaName = tmpthis.path.basename(line.substring(13))
						valaIcon = "autovala_library"
						binaryPath = tmpthis.path.dirname(line.substring(13).trim())
					child = []
					while lines.length != 0
						line = lines[0].trim()
						lines.shift()
						if line == ""
							continue
						if line[0] == '*'
							line = line.substring(1)
						if line.startsWith("vala_source:")
							sourceFile = line.substring(12).trim()
							child.push({label: sourceFile, icon: "autovala_vala", children: null, customData: tmpthis.path.join(basePath,binaryPath,sourceFile)})
							continue
						if line.startsWith("c_source:")
							sourceFile = line.substring(9).trim()
							child.push({label: sourceFile, icon: "autovala_c", children: null, customData: tmpthis.path.join(basePath,binaryPath,sourceFile)})
							continue
						if line.startsWith("h_source:")
							sourceFile = line.substring(9).trim()
							child.push({label: sourceFile, icon: "autovala_h", children: null, customData: tmpthis.path.join(basePath,binaryPath,sourceFile)})
							continue
						if line.startsWith("vala_vapi:")
							sourceFile = line.substring(10).trim()
							child.push({label: sourceFile, icon: "autovala_vapi", children: null, customData: tmpthis.path.join(basePath,binaryPath,sourceFile)})
							continue
						if (line.startsWith("vala_binary:")) or (line.startsWith("vala_library:"))
							lines.unshift(line)
							break
						
					data.push({label: valaName, icon: valaIcon, children: child})
			tmpthis.myView.setRoot({label: "root", icon: null, children: data})


	changedActivePane: (element)->

		try
			currentFile = element.getPath()
		catch error
			@currentProjectFile = null
			@projectFileChanged()
			return

		if (typeof currentFile is 'undefined') or (currentFile is null)
			@currentProjectFile = null
			@projectFileChanged()
			return

		f = new File(currentFile)
		@currentProjectFile = null
		if currentFile.endsWith(".avprj")
			@currentProjectFile = currentFile
		else
			while (@currentProjectFile == null)
				f = f.getParent()
				if (f.getPath() == f.getParent().getPath())
					break
				for element in f.getEntriesSync()
					if (element.isFile()) and (element.getPath().endsWith(".avprj"))
						@currentProjectFile = element.getPath()
						break

		if @projectFileCheck isnt null
			@projectFileCheck.dispose()
			@projectFileCheck = null

		if (@currentProjectFile is null)
			if (@lastPaths isnt null) and (@lastPaths isnt undefined)
				atom.project.setPaths(@lastPaths)
			@lastPaths = null
		else
			tmp1 = atom.project.getPaths()
			if (@lastPaths is null)
				@lastPaths = tmp1
			projectPath = @path.dirname(@currentProjectFile)
			if (tmp1.length != 1) or (tmp1[0] != projectPath)
				atom.project.setPaths([projectPath])
			tmp = new File(@currentProjectFile)
			@projectFileCheck = tmp.onDidChange(@projectFileChanged.bind(@))
		@projectFileChanged()


	fileSelected: (element) ->
		if element.item.customData isnt undefined
			atom.workspace.open(element.item.customData)


	activate: (state) ->
		# This is needed to be able to access the PATH api from the callbacks
		@path = path
		if (@myView is null)
			@myView = new TreeView(@state)
			atom.workspace.addLeftPanel(item: @myView)
			lista = []
			@myView.setRoot({label: "root", icon: null, children: lista})
			@myView.onSelect(@fileSelected.bind(@))
		else
			@myView.show()
		try
		  @lastPaths = state.lastPaths
		catch error
			@lastPaths = null
			
		@projectFileCheck = null
		@currentProjectFile = null
		@changingPane = atom.workspace.onDidStopChangingActivePaneItem(@changedActivePane.bind(@))


	deactivate: ->
		@myView.hide()
		@changingPane.dispose()
		if @projectFileCheck isnt null
			@projectFileCheck.dispose()
			@projectFileCheck = null
			
	serialize: ->
		if @lastPaths is null
			lastPaths: null
		else
			lastPaths: @lastPaths
