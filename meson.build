project('autovala',['c','vala'])

add_global_arguments('-DGETTEXT_PACKAGE="autovala"',language: 'c')

atk_dep = dependency('atk')
gio_2_0_dep = dependency('gio-2.0')
gtk_3_0_dep = dependency('gtk+-3.0')
x11_dep = dependency('x11')
cairo_dep = dependency('cairo')
gdk_3_0_dep = dependency('gdk-3.0')
gdk_pixbuf_2_0_dep = dependency('gdk-pixbuf-2.0')
gee_0_8_dep = dependency('gee-0.8')
glib_2_0_dep = dependency('glib-2.0')
gobject_2_0_dep = dependency('gobject-2.0')
libxml_2_0_dep = dependency('libxml-2.0')
pango_dep = dependency('pango')
pangocairo_dep = dependency('pangocairo')
vte_2_91_dep = dependency('vte-2.91')

subdir('po')
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_data.sh'),join_paths(get_option('prefix'),'share/autovala/debian'),join_paths(meson.current_source_dir(),'data/debian',''))

meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_data.sh'),join_paths(get_option('prefix'),'share/autovala/cmake'),join_paths(meson.current_source_dir(),'data/cmake',''))

extras_gresource_xml_generator = generator(find_program('glib-compile-resources'), arguments: [ '--sourcedir=@SOURCE_DIR@/data' , '--generate-source', '--target=@BUILD_DIR@/extras.gresource.xml.c', '@INPUT@'], output: '@PLAINNAME@.c')

extras_gresource_xml_file_c = extras_gresource_xml_generator.process(['data/extras.gresource.xml'])

meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_data.sh'),join_paths(get_option('prefix'),get_option('datadir'),'autovala'),join_paths(meson.current_source_dir(),'data/local','','*'))

installfile_1 = files('data/com.rastersoft.autovala.metainfo.xml')
install_data(installfile_1, install_dir: join_paths(get_option('prefix'),'appdata'))
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_data.sh'),join_paths(get_option('prefix'),get_option('datadir'),'doc','autovala'),join_paths(meson.current_source_dir(),'doc','','*'))

meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_manpage.sh'),
	'2', join_paths(get_option('mandir'),'man5'),
	'wiki/autovala-fileformat.5.md',
	'markdown_github',
	'autovala-fileformat.5'
)
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_manpage.sh'),
	'2', join_paths(get_option('mandir'),'man7'),
	'wiki/autovala-keep-changes.7.md',
	'markdown_github',
	'autovala-keep-changes.7'
)
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_manpage.sh'),
	'2', join_paths(get_option('mandir'),'man7'),
	'wiki/autovala-rules.7.md',
	'markdown_github',
	'autovala-rules.7'
)
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_manpage.sh'),
	'2', join_paths(get_option('mandir'),'man7'),
	'wiki/autovala-tricks.7.md',
	'markdown_github',
	'autovala-tricks.7'
)
meson.add_install_script(join_paths(meson.current_source_dir(),'meson_scripts','install_manpage.sh'),
	'2', join_paths(get_option('mandir'),'man1'),
	'wiki/autovala.1.md',
	'markdown_github',
	'autovala.1'
)
runoutput_2 = run_command('pkg-config',['--variable=completionsdir','bash-completion'])
if (runoutput_2.stdout().strip() != '')
	installfile_2 = files('data/bash_completion/autovala')
	install_data(installfile_2, install_dir: runoutput_2.stdout().strip())
else
	message('Bash completion isn\'t installed. Definitions will not be built.')
endif
check_files_retval = run_command(join_paths(meson.current_source_dir(),'meson_scripts','check_path.sh'),'/usr/include/readline/readline.h')
check_files_var = check_files_retval.returncode()
if (check_files_var != 0)
	error('The file /usr/include/readline/readline.h must exist to compile this project.')
endif
subdir('src/autovalaLib')
subdir('src/autovalaPlugin')
subdir('src')
