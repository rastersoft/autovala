cfg_autovalaLib = configuration_data()
cfg_autovalaLib.set('DATADIR', join_paths(get_option('prefix'),get_option('datadir')))
cfg_autovalaLib.set('PKGDATADIR', join_paths(get_option('prefix'),get_option('datadir'),'autovala'))
cfg_autovalaLib.set('GETTEXT_PACKAGE', 'autovala')
cfg_autovalaLib.set('RELEASE_NAME', 'autovala')
cfg_autovalaLib.set('PREFIX', get_option('prefix'))
cfg_autovalaLib.set('VERSION', '1.2.0')
cfg_autovalaLib.set('TESTSRCDIR', meson.source_root())

cfgfile_4 = configure_file(input: 'Config.vala.base',output: 'Config.vala',configuration: cfg_autovalaLib)

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
autovalaLib_sources = [cfgfile_4]
autovalaLib_sources += ['autovalaLib.vala']
autovalaLib_sources += ['conditionalText.vala']
autovalaLib_sources += ['configuration.vala']
autovalaLib_sources += ['elementAppData.vala']
autovalaLib_sources += ['elementBDepend.vala']
autovalaLib_sources += ['elementBase.vala']
autovalaLib_sources += ['elementBashCompletion.vala']
autovalaLib_sources += ['elementBinary.vala']
autovalaLib_sources += ['elementCustom.vala']
autovalaLib_sources += ['elementDBus.vala']
autovalaLib_sources += ['elementDBusConf.vala']
autovalaLib_sources += ['elementData.vala']
autovalaLib_sources += ['elementDefine.vala']
autovalaLib_sources += ['elementDesktop.vala']
autovalaLib_sources += ['elementDoc.vala']
autovalaLib_sources += ['elementEosPlug.vala']
autovalaLib_sources += ['elementExternal.vala']
autovalaLib_sources += ['elementGResource.vala']
autovalaLib_sources += ['elementGlade.vala']
autovalaLib_sources += ['elementGlobal.vala']
autovalaLib_sources += ['elementIcon.vala']
autovalaLib_sources += ['elementIgnore.vala']
autovalaLib_sources += ['elementInclude.vala']
autovalaLib_sources += ['elementManpage.vala']
autovalaLib_sources += ['elementMimetype.vala']
autovalaLib_sources += ['elementPixmap.vala']
autovalaLib_sources += ['elementPo.vala']
autovalaLib_sources += ['elementPolkit.vala']
autovalaLib_sources += ['elementSDepend.vala']
autovalaLib_sources += ['elementScheme.vala']
autovalaLib_sources += ['elementTranslation.vala']
autovalaLib_sources += ['elementValaBinary.vala']
autovalaLib_sources += ['elementVapidir.vala']
autovalaLib_sources += ['findVala.vala']
autovalaLib_sources += ['genVapis.vala']
autovalaLib_sources += ['globals.vala']
autovalaLib_sources += ['gresource_xml.vala']
autovalaLib_sources += ['mesonCommon.vala']
autovalaLib_sources += ['packages.vala']
autovalaLib_sources += ['packages_deb.vala']
autovalaLib_sources += ['packages_pacman.vala']
autovalaLib_sources += ['packages_rpm.vala']
autovalaLib_sources += ['readPkgconfig.vala']
autovalaLib_vala_args = ['--pkg','posix']
autovalaLib_vala_args += ['--pkg','readline']
autovalaLib_link_args = ['-lreadline']
autovalaLib_vala_args += ['--gir=AutoVala-1.0.gir']


AutoVala_library = shared_library('AutoVala',autovalaLib_sources,dependencies: autovalaLib_deps,vala_args: autovalaLib_vala_args,link_args: autovalaLib_link_args,version: '1.2.0',soversion: '1',install: true)

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
	version : '1.2.0',
	name : 'AutoVala',
	filebase : 'AutoVala',
	description : 'AutoVala',
	requires : autovalaLib_requires)

install_data(join_paths(meson.current_source_dir(),'AutoVala.deps'),install_dir: join_paths(get_option('prefix'),'share','vala','vapi'))
meson.add_install_script(join_paths(meson.source_root(),'meson_scripts','install_library.sh'),'src/autovalaLib','AutoVala','AutoVala-1.0.gir')

