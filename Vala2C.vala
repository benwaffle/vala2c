#!/usr/bin/vala --pkg=gtk+-3.0 --pkg=gio-2.0 --pkg gio-unix-2.0 --pkg gtksourceview-3.0

// vim: set shiftwidth=4 tabstop=4 expandtab:
class App : Gtk.Application {
    public App () {
        Object (application_id: "me.iofel.vala2c",
                flags: ApplicationFlags.FLAGS_NONE);
    }

    public override void activate () {
        var builder = new Gtk.Builder.from_file ("vala2c.ui");
        var window = builder.get_object ("window") as Gtk.Window;
        this.add_window (window);

        var valabuf = (builder.get_object ("valasrc") as Gtk.SourceView).buffer as Gtk.SourceBuffer;
        valabuf.highlight_syntax = true;
        valabuf.language = new Gtk.SourceLanguageManager ().get_language ("vala");

        var cbuf = (builder.get_object ("csrc") as Gtk.SourceView).buffer as Gtk.SourceBuffer;
        cbuf.highlight_syntax = true;
        cbuf.language = new Gtk.SourceLanguageManager ().get_language ("c");

        var args_field = builder.get_object ("entry1") as Gtk.Entry;

        (builder.get_object ("button1") as Gtk.Button).clicked.connect (b => {
            try {
                FileIOStream iostream;
                File tmp = File.new_tmp ("vala2c-XXXXXX.vala", out iostream);
                var data_out = new DataOutputStream (iostream.output_stream);
                data_out.put_string (valabuf.text);

                string[] args = {"valac", "-C", tmp.get_path ()};
                foreach (var arg in args_field.text.split (" "))
                    args += arg;

                var launcher = new SubprocessLauncher (SubprocessFlags.STDERR_PIPE);
                launcher.set_cwd ("/tmp");
                var compiler = launcher.spawnv (args);
                var mos = new MemoryOutputStream.resizable (); // errors
                mos.splice_async.begin (compiler.get_stderr_pipe (),
                                        OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET);

                compiler.wait_async.begin (null, (obj, res) => {
                    try {
                        compiler.wait_async.end (res);
                        if (compiler.get_successful ()) {
                            var cfile = /\.vala$/.replace (tmp.get_path (), -1, 0, ".c");
                            string ccode;
                            FileUtils.get_contents (cfile, out ccode);
                            cbuf.text = ccode;
                            File.new_for_path (cfile).delete ();
                        } else {
                            cbuf.text = (string)mos.data;
                        }
                        tmp.delete ();
                    } catch (Error e) {
                        warning (e.message);
                    }
                });
            } catch (Error e) {
                warning (e.message);
            }
        });

        window.show_all ();
    }

    static int main (string[] args) {
        return new App ().run (args);
    }
}
