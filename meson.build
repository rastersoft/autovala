project('autovala',['c','vala'])

add_global_arguments('-DGETTEXT_PACKAGE="autovala"',language: 'c')

atk_dep = dependency('atk')
gio_2_0_dep = dependency('gio-2.0')
cairo_dep = dependency('cairo')
gdk_3_0_dep = dependency('gdk-3.0')
gdk_pixbuf_2_0_dep = dependency('gdk-pixbuf-2.0')
gee_0_8_dep = dependency('gee-0.8')
glib_2_0_dep = dependency('glib-2.0')
gobject_2_0_dep = dependency('gobject-2.0')
gtk_3_0_dep = dependency('gtk+-3.0')
libxml_2_0_dep = dependency('libxml-2.0')
pango_dep = dependency('pango')
pangocairo_dep = dependency('pangocairo')
vte_2_91_dep = dependency('vte-2.91')
x11_dep = dependency('x11')

install_subdir(join_paths(meson.current_source_dir(),'data/debian'), install_dir: join_paths(get_option('prefix'),'share/autovala/debian'))
install_subdir(join_paths(meson.current_source_dir(),'data/cmake'), install_dir: join_paths(get_option('prefix'),'share/autovala/cmake'))
extras_gresource_xml_generator = generator(find_program('glib-compile-resources'), arguments: [ '--sourcedir=@SOURCE_DIR@/data' , '--generate-source', '--target=@BUILD_DIR@/extras.gresource.xml.c', '@INPUT@'], output: '@PLAINNAME@.c')

extras_gresource_xml_file_c = extras_gresource_xml_generator.process(['data/extras.gresource.xml'])

installfile_3 = files('data/local/CMakeLists.txt')
install_data(installfile_3, install_dir: join_paths(get_option('prefix'),'share/autovala'))
installfile_4 = files('data/com.rastersoft.autovala.metainfo.xml')
install_data(installfile_4, install_dir: join_paths(get_option('prefix'),'appdata'))
runoutput_5 = run_command('pkg-config',['--variable=completionsdir','bash-completion'])
if (runoutput_5.stdout().strip() != '')
	installfile_5 = files('data/bash_completion/autovala')
	install_data(installfile_5, install_dir: runoutput_5.stdout().strip())
else
	message('Bash completion isn\'t installed. Definitions will not be built.')
endif
files(['/usr/include/readline/readline.h'])
cfg_autovalaLib = configuration_data()
cfg_autovalaLib.set('DATADIR', join_paths(get_option('prefix'),get_option('datadir')))
cfg_autovalaLib.set('PKGDATADIR', join_paths(get_option('prefix'),get_option('datadir'),'autovala'))
cfg_autovalaLib.set('GETTEXT_PACKAGE', 'autovala')
cfg_autovalaLib.set('RELEASE_NAME', 'autovala')
cfg_autovalaLib.set('PREFIX', get_option('prefix'))
cfg_autovalaLib.set('VERSION', '1.0')
cfg_autovalaLib.set('TESTSRCDIR', meson.current_source_dir())

cfgfile_6 = configure_file(input: 'src/autovalaLib/Config.vala.base',output: 'Config_6.vala',configuration: cfg_autovalaLib)

autovalaLib_deps = [cairo_dep]
autovalaLib_deps += [gdk_3_0_dep]
autovalaLib_deps += [gdk_pixbuf_2_0_dep]
autovalaLib_deps += [gee_0_8_dep]
autovalaLib_deps += [gio_2_0_dep]
autovalaLib_deps += [glib_2_0_dep]
autovalaLib_deps += [gobject_2_0_dep]
autovalaLib_deps += [libxml_2_0_dep]
autovalaLib_deps += [pango_dep]
autovalaLib_deps += [pangocairo_dep]
autovalaLib_sources = [cfgfile_6]
autovalaLib_sources += ['src/autovalaLib/autovalaLib.vala']
autovalaLib_sources += ['src/autovalaLib/conditionalText.vala']
autovalaLib_sources += ['src/autovalaLib/configuration.vala']
autovalaLib_sources += ['src/autovalaLib/elementAppData.vala']
autovalaLib_sources += ['src/autovalaLib/elementBDepend.vala']
autovalaLib_sources += ['src/autovalaLib/elementBase.vala']
autovalaLib_sources += ['src/autovalaLib/elementBashCompletion.vala']
autovalaLib_sources += ['src/autovalaLib/elementBinary.vala']
autovalaLib_sources += ['src/autovalaLib/elementCustom.vala']
autovalaLib_sources += ['src/autovalaLib/elementDBus.vala']
autovalaLib_sources += ['src/autovalaLib/elementData.vala']
autovalaLib_sources += ['src/autovalaLib/elementDefine.vala']
autovalaLib_sources += ['src/autovalaLib/elementDesktop.vala']
autovalaLib_sources += ['src/autovalaLib/elementDoc.vala']
autovalaLib_sources += ['src/autovalaLib/elementEosPlug.vala']
autovalaLib_sources += ['src/autovalaLib/elementExternal.vala']
autovalaLib_sources += ['src/autovalaLib/elementGResource.vala']
autovalaLib_sources += ['src/autovalaLib/elementGlade.vala']
autovalaLib_sources += ['src/autovalaLib/elementGlobal.vala']
autovalaLib_sources += ['src/autovalaLib/elementIcon.vala']
autovalaLib_sources += ['src/autovalaLib/elementIgnore.vala']
autovalaLib_sources += ['src/autovalaLib/elementInclude.vala']
autovalaLib_sources += ['src/autovalaLib/elementManpage.vala']
autovalaLib_sources += ['src/autovalaLib/elementPixmap.vala']
autovalaLib_sources += ['src/autovalaLib/elementPo.vala']
autovalaLib_sources += ['src/autovalaLib/elementSDepend.vala']
autovalaLib_sources += ['src/autovalaLib/elementScheme.vala']
autovalaLib_sources += ['src/autovalaLib/elementTranslation.vala']
autovalaLib_sources += ['src/autovalaLib/elementValaBinary.vala']
autovalaLib_sources += ['src/autovalaLib/elementVapidir.vala']
autovalaLib_sources += ['src/autovalaLib/findVala.vala']
autovalaLib_sources += ['src/autovalaLib/genVapis.vala']
autovalaLib_sources += ['src/autovalaLib/globals.vala']
autovalaLib_sources += ['src/autovalaLib/gresource_xml.vala']
autovalaLib_sources += ['src/autovalaLib/packages.vala']
autovalaLib_sources += ['src/autovalaLib/packages_deb.vala']
autovalaLib_sources += ['src/autovalaLib/packages_pacman.vala']
autovalaLib_sources += ['src/autovalaLib/packages_rpm.vala']
autovalaLib_sources += ['src/autovalaLib/readPkgconfig.vala']
autovalaLib_sources += [extras_gresource_xml_file_c]
autovalaLib_vala_args = ['--pkg','posix']
autovalaLib_vala_args += ['--pkg','readline']
autovalaLib_link_args = ['-lreadline']
autovalaLib_vala_args += ['--gir=AutoVala-1.0.gir']


AutoVala_library = shared_library('AutoVala',autovalaLib_sources,dependencies: autovalaLib_deps,vala_args: autovalaLib_vala_args,link_args: autovalaLib_link_args,version: '1.0',soversion: '1',install: true)

autovalaLib_requires = []
autovalaLib_requires += ['cairo']
autovalaLib_requires += ['gdk-3.0']
autovalaLib_requires += ['gdk-pixbuf-2.0']
autovalaLib_requires += ['gee-0.8']
autovalaLib_requires += ['gio-2.0']
autovalaLib_requires += ['glib-2.0']
autovalaLib_requires += ['gobject-2.0']
autovalaLib_requires += ['libxml-2.0']
autovalaLib_requires += ['pango']
autovalaLib_requires += ['pangocairo']
pkg_mod = import('pkgconfig')
pkg_mod.generate(libraries : AutoVala_library,
	version : '1.0',
	name : 'AutoVala',
	filebase : 'AutoVala',
	description : 'AutoVala',
	requires : autovalaLib_requires)

install_data(join_paths(meson.current_source_dir(),'src/autovalaLib/AutoVala.deps'),install_dir: join_paths(get_option('prefix'),'share','vala','vapi'))
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts/install_autovalaLib.sh'))

cfg_autovalaPlugin = configuration_data()
cfg_autovalaPlugin.set('DATADIR', join_paths(get_option('prefix'),get_option('datadir')))
cfg_autovalaPlugin.set('PKGDATADIR', join_paths(get_option('prefix'),get_option('datadir'),'autovala'))
cfg_autovalaPlugin.set('GETTEXT_PACKAGE', 'autovala')
cfg_autovalaPlugin.set('RELEASE_NAME', 'autovala')
cfg_autovalaPlugin.set('PREFIX', get_option('prefix'))
cfg_autovalaPlugin.set('VERSION', '0.99')
cfg_autovalaPlugin.set('TESTSRCDIR', meson.current_source_dir())

cfgfile_7 = configure_file(input: 'src/autovalaPlugin/Config.vala.base',output: 'Config_7.vala',configuration: cfg_autovalaPlugin)

autovalaPlugin_deps = [atk_dep]
autovalaPlugin_deps += [cairo_dep]
autovalaPlugin_deps += [gdk_3_0_dep]
autovalaPlugin_deps += [gdk_pixbuf_2_0_dep]
autovalaPlugin_deps += [gee_0_8_dep]
autovalaPlugin_deps += [gio_2_0_dep]
autovalaPlugin_deps += [glib_2_0_dep]
autovalaPlugin_deps += [gobject_2_0_dep]
autovalaPlugin_deps += [gtk_3_0_dep]
autovalaPlugin_deps += [pango_dep]
autovalaPlugin_deps += [pangocairo_dep]
autovalaPlugin_deps += [vte_2_91_dep]
autovalaPlugin_deps += [x11_dep]
autovalaPlugin_sources = [cfgfile_7]
autovalaPlugin_sources += ['src/autovalaPlugin/CreateNewProject.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/PanedPercentage.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/ProjectProperties.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/ProjectViewerMenu.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/actionbuttons.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/fileview.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/outputview.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/projectview.vala']
autovalaPlugin_sources += ['src/autovalaPlugin/searchview.vala']
autovalaPlugin_sources += [extras_gresource_xml_file_c]
autovalaPlugin_vala_args = ['--gresources='+join_paths(meson.current_source_dir(),'data/extras.gresource.xml')]
autovalaPlugin_dependencies = [AutoVala_library]
autovalaPlugin_vala_args += ['--gir=AutovalaPlugin-0.0.gir']


AutovalaPlugin_library = shared_library('AutovalaPlugin',autovalaPlugin_sources,dependencies: autovalaPlugin_deps,vala_args: autovalaPlugin_vala_args,link_with: autovalaPlugin_dependencies,version: '0.99',soversion: '0',install: true)

autovalaPlugin_requires = []
autovalaPlugin_requires += ['AutoVala']
autovalaPlugin_requires += ['atk']
autovalaPlugin_requires += ['cairo']
autovalaPlugin_requires += ['gdk-3.0']
autovalaPlugin_requires += ['gdk-pixbuf-2.0']
autovalaPlugin_requires += ['gee-0.8']
autovalaPlugin_requires += ['gio-2.0']
autovalaPlugin_requires += ['glib-2.0']
autovalaPlugin_requires += ['gobject-2.0']
autovalaPlugin_requires += ['gtk+-3.0']
autovalaPlugin_requires += ['pango']
autovalaPlugin_requires += ['pangocairo']
autovalaPlugin_requires += ['vte-2.91']
autovalaPlugin_requires += ['x11']
pkg_mod = import('pkgconfig')
pkg_mod.generate(libraries : AutovalaPlugin_library,
	version : '0.99',
	name : 'AutovalaPlugin',
	filebase : 'AutovalaPlugin',
	description : 'AutovalaPlugin',
	requires : autovalaPlugin_requires)

install_data(join_paths(meson.current_source_dir(),'src/autovalaPlugin/AutovalaPlugin.deps'),install_dir: join_paths(get_option('prefix'),'share','vala','vapi'))
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts/install_autovalaPlugin.sh'))

cfg_autovala = configuration_data()
cfg_autovala.set('DATADIR', join_paths(get_option('prefix'),get_option('datadir')))
cfg_autovala.set('PKGDATADIR', join_paths(get_option('prefix'),get_option('datadir'),'autovala'))
cfg_autovala.set('GETTEXT_PACKAGE', 'autovala')
cfg_autovala.set('RELEASE_NAME', 'autovala')
cfg_autovala.set('PREFIX', get_option('prefix'))
cfg_autovala.set('VERSION', '1.0.0')
cfg_autovala.set('TESTSRCDIR', meson.current_source_dir())

cfgfile_8 = configure_file(input: 'src/Config.vala.base',output: 'Config_8.vala',configuration: cfg_autovala)

autovala_deps = [gio_2_0_dep]
autovala_deps += [gee_0_8_dep]
autovala_deps += [glib_2_0_dep]
autovala_sources = [cfgfile_8]
autovala_sources += ['src/autovala.vala']
autovala_sources += [extras_gresource_xml_file_c]
autovala_vala_args = ['--pkg','posix']
autovala_dependencies = [AutoVala_library]

executable('autovala',autovala_sources,dependencies: autovala_deps,vala_args: autovala_vala_args,link_with: autovala_dependencies,install: true)

