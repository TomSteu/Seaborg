using Gtk;
using GLib;

// [CCode (cheader_filename = "include/wstp_connection.h")]
namespace Seaborg {

	/*[SimpleType]
    [CCode (cname = "WstpConnection", has_type_id = false)]
    public struct WstpConnection {
    }*/
    

	/*[CCode(cname = "init_connection", cheader_filename = "wstp_connection.h")]
	public extern WstpConnection init_connection(string  path);*/

	public class SeaborgApplication : Gtk.Application {
		
		protected override void activate() {
			
			// widgets
			SeaborgWindow = new Gtk.ApplicationWindow(this);
			SeaborgHeaderBar = new Gtk.HeaderBar();
			SeaborgStackSwitcher = new Gtk.StackSwitcher();
			SeaborgStack = new Gtk.Stack();
			ContentScroll = new Gtk.ScrolledWindow(null,null);
			SeaborgNotebook = new Seaborg.Notebook();
			


			// assemble gui
			EvaluationCell* cellA = new EvaluationCell(SeaborgNotebook);
			EvaluationCell* cellB = new EvaluationCell(SeaborgNotebook);
			EvaluationCell* cellC = new EvaluationCell(SeaborgNotebook);
			SeaborgNotebook.add_before(0, {cellA/*, cellB, cellC*/});

			SeaborgStackSwitcher.stack = SeaborgStack;
			SeaborgStack.add_titled(SeaborgNotebook, "Cell1", "Cell1");
			
			SeaborgHeaderBar.show_close_button = true;
			SeaborgHeaderBar.custom_title = SeaborgStackSwitcher;
			ContentScroll.add(SeaborgStack);
			
			SeaborgWindow.title = "Gtk Notebook";
			SeaborgWindow.set_titlebar(SeaborgHeaderBar);
			SeaborgWindow.add(ContentScroll);
			this.add_window(SeaborgWindow);

			// SeaborgWindow.default_size = something;
			SeaborgWindow.show_all();

		}

		protected override void startup() {
			base.startup();

			SeaborMenu = new GLib.Menu();
			SeaborMenu.append("New", "app.new");
			SeaborMenu.append("Open", "app.open");
			SeaborMenu.append("Save", "app.save");

			var new_action = new GLib.SimpleAction("new", null);
			var open_action = new GLib.SimpleAction("open", null);
			var save_action = new GLib.SimpleAction("save", null);
			var remove_action = new GLib.SimpleAction("rm", null);

			new_action.activate.connect(() => {

			});

			open_action.activate.connect(() => {
				
			});

			save_action.activate.connect(() => {
				
			});

			remove_action.activate.connect(() => {
				SeaborgNotebook.remove_recursively();
			});


			this.add_action(new_action);
			this.add_action(open_action);
			this.add_action(save_action);
			this.app_menu = SeaborMenu;


			const string[] new_accels = {"<Control>N", null};
			const string[] open_accels = {"<Control>O", null};
			const string[] save_accels = {"<Control>S", null};
			const string[] rm_accels = {"Delete", null};
			this.set_accels_for_action("app.new", new_accels);
			this.set_accels_for_action("app.open", open_accels);
			this.set_accels_for_action("app.save", save_accels);
			this.set_accels_for_action("app.rm", rm_accels);

			// connecting kernel


		}

		private Gtk.ApplicationWindow SeaborgWindow;
		private Gtk.HeaderBar SeaborgHeaderBar;
		private Gtk.StackSwitcher SeaborgStackSwitcher;
		private Gtk.Stack SeaborgStack;
		private GLib.Menu SeaborMenu;
		private Gtk.ScrolledWindow ContentScroll;
		private Seaborg.Notebook SeaborgNotebook;
		private EvaluationCell ecell;
	}


	int main(string[] args) {

		return new SeaborgApplication().run(args);
	}
}