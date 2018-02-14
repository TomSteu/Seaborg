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

		public static const string kernel_init = "-linkname \"math -wstp -mathlink\"";
		public static Highlighting code_highlighting = Highlighting.NOSTDLIB;
		public static bool dark_theme = true;
		public static Form output = Form.RENDERED;
		public static Gdk.RGBA font_color;
	}

}