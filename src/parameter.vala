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

		public static string kernel_init;
		public static Highlighting code_highlighting = Highlighting.NOSTDLIB;
		public static bool dark_theme = true;
		public static Form output = Form.INPUTREPLACEGRAPHICS;
		public static Gdk.RGBA font_color;
	}

}