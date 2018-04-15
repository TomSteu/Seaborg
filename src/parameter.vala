using Gdk;

namespace Seaborg {

	public enum Form {
		INPUT,
		RENDERED
	}

	public enum Highlighting {
		NONE,
		NOSTDLIB,
		FULL
	}

	public struct Parameter {

		public const string version = "0.9.1";
		public static string kernel_init;
		public static Highlighting code_highlighting = Highlighting.NOSTDLIB;
		public static bool dark_theme = true;
		public static Form output = Form.INPUT;
		public static Gdk.RGBA font_color;
		public static Gtk.WrapMode wrap_mode = Gtk.WrapMode.WORD_CHAR;
		public static int chars_per_line = 80;

	}

}