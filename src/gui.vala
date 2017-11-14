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
			SeaborgNotebook = new Seaborg.Notebook(1);
			SeaborgNotebook.add_before(0, {new EvaluationCell(), new EvaluationCell(), new EvaluationCell()});
			
			

			var ggd = new Gtk.Grid();
			ggd.attach(SeaborgNotebook,0,0,1,1);
			var btn = new Gtk.Button.with_label("-");
			btn.clicked.connect(() => { 
				/*Gtk.MessageDialog msg = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, "My message!");
				msg.show();*/
				SeaborgNotebook.remove_recursively();
			});
			ggd.attach(btn, 0, 1, 1, 1);

			// assemble gui
			SeaborgStackSwitcher.stack = SeaborgStack;
			SeaborgStack.add_titled(ggd, "Cell1", "Cell1");
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

		}

		private Gtk.ApplicationWindow SeaborgWindow;
		private Gtk.HeaderBar SeaborgHeaderBar;
		private Gtk.StackSwitcher SeaborgStackSwitcher;
		private Gtk.Stack SeaborgStack;
		private GLib.Menu SeaborMenu;
		private Gtk.ScrolledWindow ContentScroll;
		private Seaborg.Notebook SeaborgNotebook;
	}


	int main(string[] args) {

		return new SeaborgApplication().run(args);
	}
}