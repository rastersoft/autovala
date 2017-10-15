cfg_autovalaPlugin = configuration_data()
cfg_autovalaPlugin.set('DATADIR', join_paths(get_option('prefix'),get_option('datadir')))
cfg_autovalaPlugin.set('PKGDATADIR', join_paths(get_option('prefix'),get_option('datadir'),'autovala'))
cfg_autovalaPlugin.set('GETTEXT_PACKAGE', 'autovala')
cfg_autovalaPlugin.set('RELEASE_NAME', 'autovala')
cfg_autovalaPlugin.set('PREFIX', get_option('prefix'))
cfg_autovalaPlugin.set('VERSION', '0.99')
cfg_autovalaPlugin.set('TESTSRCDIR', meson.current_source_dir())

cfgfile_5 = configure_file(input: 'Config.vala.base',output: 'Config.vala',configuration: cfg_autovalaPlugin)

autovalaPlugin_deps = [atk_dep]
autovalaPlugin_deps += [gtk_3_0_dep]
autovalaPlugin_deps += [x11_dep]
autovalaPlugin_deps += [cairo_dep]
autovalaPlugin_deps += [gdk_3_0_dep]
autovalaPlugin_deps += [gdk_pixbuf_2_0_dep]
autovalaPlugin_deps += [gee_0_8_dep]
autovalaPlugin_deps += [gio_2_0_dep]
autovalaPlugin_deps += [glib_2_0_dep]
autovalaPlugin_deps += [gobject_2_0_dep]
autovalaPlugin_deps += [pango_dep]
autovalaPlugin_deps += [pangocairo_dep]
autovalaPlugin_deps += [vte_2_91_dep]
autovalaPlugin_sources = [cfgfile_5]
autovalaPlugin_sources += ['CreateNewProject.vala']
autovalaPlugin_sources += ['PanedPercentage.vala']
autovalaPlugin_sources += ['ProjectProperties.vala']
autovalaPlugin_sources += ['ProjectViewerMenu.vala']
autovalaPlugin_sources += ['actionbuttons.vala']
autovalaPlugin_sources += ['fileview.vala']
autovalaPlugin_sources += ['outputview.vala']
autovalaPlugin_sources += ['projectview.vala']
autovalaPlugin_sources += ['searchview.vala']
autovalaPlugin_sources += [extras_gresource_xml_file_c]
autovalaPlugin_vala_args = ['--gresources='+join_paths(meson.source_root(),'data/extras.gresource.xml')]
autovalaPlugin_dependencies = [AutoVala_library]
autovalaPlugin_vala_args += ['--gir=AutovalaPlugin-0.0.gir']


AutovalaPlugin_library = shared_library('AutovalaPlugin',autovalaPlugin_sources,dependencies: autovalaPlugin_deps,vala_args: autovalaPlugin_vala_args,link_with: autovalaPlugin_dependencies,version: '0.99',soversion: '0',install: true)

autovalaPlugin_requires = []
autovalaPlugin_requires += ['AutoVala']
autovalaPlugin_requires += ['atk']
autovalaPlugin_requires += ['gtk+-3.0']
autovalaPlugin_requires += ['x11']
autovalaPlugin_requires += ['cairo']
autovalaPlugin_requires += ['gdk-3.0']
autovalaPlugin_requires += ['gdk-pixbuf-2.0']
autovalaPlugin_requires += ['gee-0.8']
autovalaPlugin_requires += ['gio-2.0']
autovalaPlugin_requires += ['glib-2.0']
autovalaPlugin_requires += ['gobject-2.0']
autovalaPlugin_requires += ['pango']
autovalaPlugin_requires += ['pangocairo']
autovalaPlugin_requires += ['vte-2.91']
pkg_mod = import('pkgconfig')
pkg_mod.generate(libraries : AutovalaPlugin_library,
	version : '0.99',
	name : 'AutovalaPlugin',
	filebase : 'AutovalaPlugin',
	description : 'AutovalaPlugin',
	requires : autovalaPlugin_requires)

install_data(join_paths(meson.current_source_dir(),'AutovalaPlugin.deps'),install_dir: join_paths(get_option('prefix'),'share','vala','vapi'))
meson.add_install_script(join_paths(meson.source_root(),'meson_scripts','install_library.sh'),'src/autovalaPlugin','AutovalaPlugin','AutovalaPlugin-0.0.gir')

