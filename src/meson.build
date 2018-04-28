cfg_autovala = configuration_data()
cfg_autovala.set('DATADIR', join_paths(get_option('prefix'),get_option('datadir')))
cfg_autovala.set('PKGDATADIR', join_paths(get_option('prefix'),get_option('datadir'),'autovala'))
cfg_autovala.set('GETTEXT_PACKAGE', 'autovala')
cfg_autovala.set('RELEASE_NAME', 'autovala')
cfg_autovala.set('PREFIX', get_option('prefix'))
cfg_autovala.set('VERSION', '1.8.0')
cfg_autovala.set('TESTSRCDIR', meson.source_root())

cfgfile_3 = configure_file(input: 'Config.vala.base',output: 'Config.vala',configuration: cfg_autovala)

autovala_deps = [gio_2_0_dep]
autovala_deps += [gee_0_8_dep]
autovala_deps += [glib_2_0_dep]
autovala_sources = [cfgfile_3]
autovala_sources += ['autovala.vala']
autovala_vala_args = ['--pkg','posix']
autovala_dependencies = [AutoVala_library]
autovala_hfolders = ['../src/autovalaLib']

executable('autovala',autovala_sources,dependencies: autovala_deps,vala_args: autovala_vala_args,link_with: autovala_dependencies,include_directories: include_directories(autovala_hfolders),install: true)

