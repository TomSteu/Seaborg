using Gtk;
using GLib;

namespace Seaborg {

	public class SeaborgApplication : Gtk.Application {

		protected override void activate() {

			this.set_resource_base_path("/tst/seaborg/./res/");
			
			// widgets
			main_window = new Gtk.ApplicationWindow(this);
			main_headerbar = new Gtk.HeaderBar();
			tab_switcher = new Gtk.StackSwitcher();
			notebook_stack = new Gtk.Stack();
			notebook_scroll = new Gtk.ScrolledWindow(null,null);
			notebook = new Seaborg.Notebook();
			string shortcut_builder_string = 
				"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"+
				"<interface>"+
				  "<object class=\"GtkShortcutsWindow\" id=\"shortcuts\">"+
				    "<property name=\"modal\">1</property>"+
				    "<child>"+
				      "<object class=\"GtkShortcutsSection\">"+
				        "<property name=\"visible\">1</property>"+
				        "<property name=\"section-name\">shortcuts</property>"+
				        "<property name=\"max-height\">12</property>"+
				        "<child>"+
				          "<object class=\"GtkShortcutsGroup\">"+
				            "<property name=\"visible\">1</property>"+
				            "<property name=\"title\" translatable=\"yes\">Window</property>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;N</property>"+
				                "<property name=\"title\" translatable=\"yes\">Create new notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;O</property>"+
				                "<property name=\"title\" translatable=\"yes\">Open a notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;S</property>"+
				                "<property name=\"title\" translatable=\"yes\">Save the notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;Primary&gt;question &lt;Primary&gt;F1</property>"+
				                "<property name=\"title\" translatable=\"yes\">Show shortcuts</property>"+
				              "</object>"+
				            "</child>"+
				    	  "</object>"+
				    	"</child>"+
				    	"<child>"+
				    	  "<object class=\"GtkShortcutsGroup\">"+
				            "<property name=\"visible\">1</property>"+
				            "<property name=\"title\" translatable=\"yes\">Cells</property>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;D &lt;ctrl&gt;Delete</property>"+
				                "<property name=\"title\" translatable=\"yes\">Delete selected cells</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;Return</property>"+
				                "<property name=\"title\" translatable=\"yes\">Evaluate cells</property>"+
				              "</object>"+
				            "</child>"+
				          "</object>"+
				        "</child>"+
				      "</object>"+
				    "</child>"+
				  "</object>"+
				"</interface>";
			Gtk.Builder shortcut_builder = new Gtk.Builder.from_string(shortcut_builder_string, shortcut_builder_string.length);
			shortcuts = shortcut_builder.get_object("shortcuts") as Gtk.ShortcutsWindow;


			// assemble gui
			EvaluationCell* cellA = new EvaluationCell(notebook);
			EvaluationCell* cellB = new EvaluationCell(notebook);
			EvaluationCell* cellC = new EvaluationCell(notebook);
			notebook.add_before(0, {cellA, cellB, cellC});

			tab_switcher.stack = notebook_stack;
			notebook_stack.add_titled(notebook, "Cell1", "Cell1");
			
			main_headerbar.show_close_button = true;
			main_headerbar.custom_title = tab_switcher;
			notebook_scroll.add(notebook_stack);
			
			main_window.title = "Gtk Notebook";
			main_window.set_titlebar(main_headerbar);
			main_window.add(notebook_scroll);
			main_window.set_help_overlay(shortcuts);
			this.add_window(main_window);

			main_window.set_default_size(800, 600);
			main_window.show_all();

		}

		protected override void startup() {
			base.startup();

			main_menu = new GLib.Menu();
			main_menu.append("New", "app.new");
			main_menu.append("Open", "app.open");
			main_menu.append("Save", "app.save");
			main_menu.append("Keyboard Shortcuts", "win.show-help-overlay");

			this.app_menu = main_menu;

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
				notebook.remove_recursively();
			});


			this.add_action(new_action);
			this.add_action(open_action);
			this.add_action(save_action);
			this.add_action(remove_action);


			const string[] new_accels = {"<Control>N", null};
			const string[] open_accels = {"<Control>O", null};
			const string[] save_accels = {"<Control>S", null};
			const string[] rm_accels = {"<Control>Delete","<Control>D", null};
			const string[] shortcut_accels ={"<Control>F1", "<Control>question",null};

			this.set_accels_for_action("app.new", new_accels);
			this.set_accels_for_action("app.open", open_accels);
			this.set_accels_for_action("app.save", save_accels);
			this.set_accels_for_action("app.rm", rm_accels);
			this.set_accels_for_action("win.show-help-overlay", shortcut_accels);
			
			// connecting kernel
			reset_kernel();


		}

		private void reset_kernel() {
			if(kernel_connection != null) {
				if(check_connection(kernel_connection) != -1) {
					close_connection(kernel_connection);
				}
			}

			kernel_connection = init_connection("math");
		}

		[CCode(cname = "init_connection", cheader_filename = "wstp_connection.h")]
		private extern void* init_connection(char* path);

		[CCode(cname = "close_connection", cheader_filename = "wstp_connection.h")]
		private extern void close_connection(void* connection);

		[CCode(cname = "abort_calculation", cheader_filename = "wstp_connection.h")]
		private extern int abort_calculation(void* connection);

		private static delegate void callback_str(char* string_to_write);

		[CCode(cname = "evaluate", cheader_filename = "wstp_connection.h")]
		private extern void evaluate(void* con, char* input, callback_str callback);

		[CCode(cname = "check_connection", cheader_filename = "wstp_connection.h")]
		private extern int check_connection(void* con);

		[CCode(cname = "try_abort", cheader_filename = "wstp_connection.h")]
		private extern int try_abort(void* con);

		private Gtk.ApplicationWindow main_window;
		private Gtk.HeaderBar main_headerbar;
		private Gtk.StackSwitcher tab_switcher;
		private Gtk.Stack notebook_stack;
		private GLib.Menu main_menu;
		private Gtk.ScrolledWindow notebook_scroll;
		private Seaborg.Notebook notebook;
		private Gtk.ShortcutsWindow shortcuts;
		private void* kernel_connection;
	}


	int main(string[] args) {

		return new SeaborgApplication().run(args);
	}
}