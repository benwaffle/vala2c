all:
	vala "-g --pkg=gtk+-3.0 --pkg=gio-2.0 --pkg=gio-unix-2.0 --pkg=gtksourceview-3.0 --pkg=libvala-0.28" main.vala
