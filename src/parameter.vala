using Gdk;

namespace Seaborg {

	public enum Form {
		Input,
		InputReplaceGraphics,
		Rendered
	}

	public struct Parameter {

		public static const string kernel_init = "-linkname \"math -wstp -mathlink\"";
		public static bool code_highlighting = true;
		public static bool stdlib_highlighting = false;
		public static bool replace_plot = true;
		public static Form output = Form.Rendered;
		public static Gdk.RGBA font_color;
	}

}