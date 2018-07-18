namespace Seaborg {
	
	public class IdGenerator : GLib.Object {

		public static void reset() {
			id = 0;
		}

		public static string get_id() {
			return (id++).to_string();
		}

  		private static int id = 0;
	}
	
}