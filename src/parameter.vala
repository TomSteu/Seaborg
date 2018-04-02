using Gdk;

namespace Seaborg {

	public enum Form {
		INPUT,
		INPUTREPLACEGRAPHICS,
		RENDERED
	}

	public enum Highlighting {
		NONE,
		NOSTDLIB,
		FULL
	}

	public struct Parameter {

		public const string version = "0.9.0";
		public static string kernel_init;
		public static Highlighting code_highlighting = Highlighting.NOSTDLIB;
		public static bool dark_theme = true;
		public static Form output = Form.INPUTREPLACEGRAPHICS;
		public static Gdk.RGBA font_color;
		public static Gtk.WrapMode wrap_mode = Gtk.WrapMode.WORD_CHAR;

	}

}