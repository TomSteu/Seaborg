using Gdk;

namespace Seaborg {

	public enum Form {
		Input,
		InputReplaceGraphics,
		Rendered
	}

	public enum Highlighting {
		None,
		NoStdlib,
		Full
	}

	public struct Parameter {

		public static const string kernel_init = "-linkname \"math -wstp -mathlink\"";
		public static Highlighting code_highlighting = Highlighting.NoStdlib;
		public static bool replace_plot = true;
		public static bool dark_theme = true;
		public static Form output = Form.Rendered;
		public static Gdk.RGBA font_color;
	}

}