using Gtk;
using GLib;

namespace Seaborg {

	public class SeaborgApplication : Gtk.Application {
		
		protected override void activate() {
			
			// widgets
			SeaborgWindow = new Gtk.ApplicationWindow(this);
			SeaborgHeaderBar = new Gtk.HeaderBar();
			SeaborgStackSwitcher = new Gtk.StackSwitcher();
			SeaborgStack = new Gtk.Stack();
			ContentScroll = new Gtk.ScrolledWindow(null,null);


			// assemble gui
			SeaborgStackSwitcher.stack = SeaborgStack;
			SeaborgStack.add_titled(new EvaluationCell(), "Cell1", "Cell1");
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

			new_action.activate.connect(() => {

			});

			open_action.activate.connect(() => {
				
			});

			save_action.activate.connect(() => {
				
			});


			this.add_action(new_action);
			this.add_action(open_action);
			this.add_action(save_action);
			this.app_menu = SeaborMenu;


			const string[] new_accels = {"<Control>N", null};
			const string[] open_accels = {"<Control>O", null};
			const string[] save_accels = {"<Control>S", null};
			this.set_accels_for_action("app.new", new_accels);
			this.set_accels_for_action("app.open", open_accels);
			this.set_accels_for_action("app.save", save_accels);

		}

		private Gtk.ApplicationWindow SeaborgWindow;
		private Gtk.HeaderBar SeaborgHeaderBar;
		private Gtk.StackSwitcher SeaborgStackSwitcher;
		private Gtk.Stack SeaborgStack;
		private GLib.Menu SeaborMenu;
		private Gtk.ScrolledWindow ContentScroll;
	}


	int main(string[] args) {

		return new SeaborgApplication().run(args);
	}
}