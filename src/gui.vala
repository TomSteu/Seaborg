using Gtk;
using GLib;
using Xml;

namespace Seaborg {

	// data structure to be send send to the backend during evaluation
	public struct EvaluationData {
		public void* cell;
		public string input;
		
	}

	public class SeaborgApplication : Gtk.Application {

		public SeaborgApplication () {
			Object (application_id: "org.seaborg.seaborg", flags: ApplicationFlags.HANDLES_OPEN);
			set_inactivity_timeout (10000);
		}

		// keeps track of correct stamp during evaluation
		public static ulong global_stamp = 0;

		public override void open(File[] files, string hint) {
			activate();
			foreach (File file in files) {
				load_notebook(file.get_path());
			}
		}

		// construct gui
		public override void activate() {

			// try to find seaborg CSS file
			css_provider = new CssProvider();

			try {

				css_provider.load_from_path("res/seaborg.css");

			} catch(GLib.Error error) {

				css_provider = CssProvider.get_default();
			}

			// reset ID generator for cells
			IdGenerator.reset();

			// reset background color for rendered formulas
			Parameter.font_color = (new Gtk.SourceView()).get_style_context().get_color(Gtk.StateFlags.NORMAL);
			
			// init widgets that might be affected by setting parameters
			main_window = new Gtk.ApplicationWindow(this);
			main_headerbar = new Gtk.HeaderBar();
			main_layout = new Gtk.Grid();
			message_bar = new Gtk.InfoBar();
			notebook_stack = new Seaborg.Stack();
			tab_switcher = new Seaborg.TabSwitcher(notebook_stack);
			notebook_scroll = new Gtk.ScrolledWindow(null,null);
			search_settings = new SourceSearchSettings();
			sidebar_revealer = new Gtk.Revealer();

			//some initializations for the window
			main_window.title = "Seaborg";
			main_window.set_titlebar(main_headerbar);
			main_window.show_menubar = false;

			// read config.xml
			load_preferences();

			// apply settings
			Gtk.Settings settings = Gtk.Settings.get_default();
			settings.gtk_application_prefer_dark_theme = Parameter.dark_theme;
			
			// shortcut menu
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
				                "<property name=\"accelerator\">&lt;ctrl&gt;Tab</property>"+
				                "<property name=\"title\" translatable=\"yes\">Cycle Tabs</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;Primary&gt;question &lt;Primary&gt;F1</property>"+
				                "<property name=\"title\" translatable=\"yes\">Show shortcuts</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;plus</property>"+
				                "<property name=\"title\" translatable=\"yes\">Zoom in</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;minus</property>"+
				                "<property name=\"title\" translatable=\"yes\">Zoom out</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;F</property>"+
				                "<property name=\"title\" translatable=\"yes\">Search</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;P</property>"+
				                "<property name=\"title\" translatable=\"yes\">Preferences</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;Q</property>"+
				                "<property name=\"title\" translatable=\"yes\">Quit App</property>"+
				              "</object>"+
				            "</child>"+
				          "</object>"+
				        "</child>"+
				        "<child>"+
				          "<object class=\"GtkShortcutsGroup\">"+
				            "<property name=\"visible\">1</property>"+
				            "<property name=\"title\" translatable=\"yes\">Notebooks</property>"+
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
				                "<property name=\"title\" translatable=\"yes\">Quicksave the notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;&lt;alt&gt;S</property>"+
				                "<property name=\"title\" translatable=\"yes\">Save the notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;I</property>"+
				                "<property name=\"title\" translatable=\"yes\">Import notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;E</property>"+
				                "<property name=\"title\" translatable=\"yes\">Export notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;Escape</property>"+
				                "<property name=\"title\" translatable=\"yes\">Select/Unselect notebook</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;W</property>"+
				                "<property name=\"title\" translatable=\"yes\">Close Notebook</property>"+
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
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;period</property>"+
				                "<property name=\"title\" translatable=\"yes\">Abort evaluation</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;y</property>"+
				                "<property name=\"title\" translatable=\"yes\">(Un)comment selected input</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;Up</property>"+
				                "<property name=\"title\" translatable=\"yes\">Previous cell</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;&lt;shift&gt;Up</property>"+
				                "<property name=\"title\" translatable=\"yes\">Previous cell, keep selection</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;Down</property>"+
				                "<property name=\"title\" translatable=\"yes\">Next cell</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;&lt;shift&gt;Down</property>"+
				                "<property name=\"title\" translatable=\"yes\">Next cell, keep selection</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;T</property>"+
				                "<property name=\"title\" translatable=\"yes\">Expand/Collapse cells</property>"+
				              "</object>"+
				            "</child>"+
				            "<child>"+
				              "<object class=\"GtkShortcutsShortcut\">"+
				                "<property name=\"visible\">1</property>"+
				                "<property name=\"accelerator\">&lt;ctrl&gt;M</property>"+
				                "<property name=\"title\" translatable=\"yes\">Transmute cell</property>"+
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

			// application icon
			try {
				main_icon_handle = new Rsvg.Handle.from_file(Parameter.dark_theme ? "res/seaborg-dark.svg" : "res/seaborg-light.svg");
			} catch (GLib.Error err) {
				main_icon_handle = null;
			}

			// message bar
			message_bar.set_default_response(0);
			message_bar.set_show_close_button(true);
			message_bar.set_message_type(MessageType.INFO);
			message_bar.set_no_show_all(true);
			message_bar.response.connect((i) => { message_bar.hide(); });

			
			// search bar
			// sync search settings with all notebooks
			search_settings.wrap_around = false;
			search_settings.notify["search-text"].connect((property, sender) => {
				if(notebook_stack.get_visible_child() != null)
					((Seaborg.Notebook) notebook_stack.get_visible_child()).search_settings.search_text = this.search_settings.search_text;
			});

			search_settings.notify["case-sensitive"].connect((property, sender) => {
				if(notebook_stack.get_visible_child() != null)
					((Seaborg.Notebook) notebook_stack.get_visible_child()).search_settings.case_sensitive = this.search_settings.case_sensitive;
			});

			search_settings.notify["at-word-boundaries"].connect((property, sender) => {
				if(notebook_stack.get_visible_child() != null)
					((Seaborg.Notebook) notebook_stack.get_visible_child()).search_settings.at_word_boundaries = this.search_settings.at_word_boundaries;
			});

			search_settings.notify["regex-enabled"].connect((property, sender) => {
				if(notebook_stack.get_visible_child() != null)
					((Seaborg.Notebook) notebook_stack.get_visible_child()).search_settings.regex_enabled = this.search_settings.regex_enabled;
			});

			// entry widget in search bar
			search_entry = new Gtk.SearchEntry();
			search_entry.hexpand = true;
			search_entry.halign = Gtk.Align.FILL;
			search_entry.set_width_chars(32);
			search_entry.search_changed.connect(() => {
				if(search_entry.text != null)
					search_settings.search_text = search_entry.text;
			});

			// button to toggle case sensitivity
			search_case = new Gtk.ToggleButton.with_label("Aa");
			search_case.has_tooltip = true;
			search_case.tooltip_text = "match case";
			search_case.active = search_settings.case_sensitive;
			search_case.toggled.connect(() => { 
				search_settings.case_sensitive = search_case.active;
			});

			// button to toggle whole word matching
			search_word = new Gtk.ToggleButton.with_label("\"W\"");
			search_word.has_tooltip = true;
			search_word.tooltip_text = "match whole word";
			search_word.active = search_settings.at_word_boundaries;
			search_word.toggled.connect(() => { search_settings.at_word_boundaries = search_word.active; });

			// button to toggle regex matching
			search_regex = new Gtk.ToggleButton.with_label(".*");
			search_regex.has_tooltip = true;
			search_regex.tooltip_text = "match regex";
			search_regex.active = search_settings.regex_enabled;
			search_regex.toggled.connect(() => { search_settings.regex_enabled = search_regex.active; });

			Gtk.Box match_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			match_button_box.pack_start(search_case);
			match_button_box.pack_start(search_word);
			match_button_box.pack_start(search_regex);

			// button for next search result
			search_next = new Gtk.Button.from_icon_name("go-down-symbolic");
			search_next.clicked.connect(() => {
				
				bool found_last = false;
				if(((Seaborg.Notebook)notebook_stack.get_visible_child()).do_forward_search(ref found_last))
					return;
				if(!found_last) {
					found_last = true;
					((Seaborg.Notebook)notebook_stack.get_visible_child()).do_forward_search(ref found_last);
				}

			});

			// button for previous search result
			search_prev = new Gtk.Button.from_icon_name("go-up-symbolic");
			search_prev.clicked.connect(() => {
				
				bool found_last = false;
				if(((Seaborg.Notebook)notebook_stack.get_visible_child()).do_backward_search(ref found_last))
					return;
				if(!found_last) {
					found_last = true;
					((Seaborg.Notebook)notebook_stack.get_visible_child()).do_backward_search(ref found_last);
				}

			});

			Gtk.Box search_select_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			search_select_box.pack_start(search_next);
			search_select_box.pack_start(search_prev);

			// entry widget to replace matches
			replace_entry = new Gtk.Entry();
			replace_entry.set_width_chars(16);

			// button to replace all search results
			replace_all_button = new Gtk.Button.with_label("Replace All");
			replace_all_button.clicked.connect(() => {
				if(!(replace_entry.text == null) && !(replace_entry.text == ""))
					((Seaborg.Notebook) notebook_stack.get_visible_child()).replace_all(replace_entry.text);
			});

			replace_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			replace_box.pack_start(replace_entry);
			replace_box.pack_start(replace_all_button);

			// button to hide replace box
			replace_expand = new Gtk.ToggleButton();
			replace_expand.set_image(new Gtk.Image.from_icon_name("edit-find-replace-symbolic", IconSize.BUTTON));
			replace_expand.has_tooltip = true;
			replace_expand.tooltip_text = "replace";
			replace_expand.active = false;
			replace_expand.notify["active"].connect((property, sender) => { replace_box.visible = replace_expand.active; });
			replace_box.notify["visible"].connect((property, sender) => { replace_expand.active = replace_box.visible; });
			search_select_box.pack_start(replace_expand);

			// assemble search bar, place empty grids to avoid awkward streches for small window sizes
			search_box = new Gtk.FlowBox();
			search_box.orientation = Gtk.Orientation.HORIZONTAL;
			search_box.selection_mode = Gtk.SelectionMode.NONE;
			search_box.homogeneous = false;
			search_box.min_children_per_line = 2;
			search_box.row_spacing = 0u;
			search_box.column_spacing = 0u;
			search_box.hexpand = true;
			search_box.halign = Gtk.Align.CENTER;
			search_box.add(match_button_box);
			search_box.add(new Gtk.Grid());
			search_box.add(search_entry);
			search_box.add(new Gtk.Grid());
			search_box.add(search_select_box);
			search_box.add(new Gtk.Grid());
			search_box.add(replace_box);

			// set up search bar and connect to search button
			search_bar = new Gtk.SearchBar();
			search_bar.add(search_box);
			search_bar.connect_entry(search_entry);
			search_bar.show_close_button = true;
			search_bar.search_mode_enabled = false;
			search_bar.hexpand = true;
			search_bar.halign = Gtk.Align.FILL;
			search_bar.notify["search-mode-enabled"].connect((property, sender) => {search_button.active = search_bar.search_mode_enabled;});

			// set up search button
			search_button = new Gtk.ToggleButton();
			search_button.always_show_image = true;
			search_button.set_image(new Gtk.Image.from_icon_name("edit-find-symbolic", IconSize.BUTTON));
			search_button.toggled.connect(() => {
				search_bar.search_mode_enabled = search_button.active;
			});


			// quick option popup menu

			Gtk.Box quick_option_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			
			// button to schedule evaluation 
			Gtk.Button eval_button = new Gtk.Button.with_label("Add to evaluation queue");
			eval_button.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			eval_button.get_style_context().add_class("popmenu-button");
			eval_button.set_alignment(0.0f, 0.5f);
			eval_button.clicked.connect(() => { 
				schedule_evaluation((Seaborg.Notebook)notebook_stack.get_visible_child());
				quick_option_button.popover.popdown();
			});
			quick_option_box.add(eval_button);

			// button to unschedule evaluation 
			Gtk.Button uneval_button = new Gtk.Button.with_label("Remove from evaluation queue");
			uneval_button.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			uneval_button.get_style_context().add_class("popmenu-button");
			uneval_button.set_alignment(0.0f, 0.5f);
			uneval_button.clicked.connect(() => { 
				unschedule_evaluation((Seaborg.Notebook)notebook_stack.get_visible_child());
				quick_option_button.popover.popdown();
			});
			quick_option_box.add(uneval_button);

			// button to abort evaluation 
			Gtk.Button cancel_button = new Gtk.Button.with_label("Cancel evaluation");
			cancel_button.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			cancel_button.get_style_context().add_class("popmenu-button");
			cancel_button.set_alignment(0.0f, 0.5f);
			cancel_button.clicked.connect(() => { 
				try_abort(kernel_connection);
				quick_option_button.popover.popdown();
			});
			quick_option_box.add(cancel_button);

			// button to restart kernel
			Gtk.Button restart_button = new Gtk.Button.with_label("Restart kernel");
			restart_button.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			restart_button.get_style_context().add_class("popmenu-button");
			restart_button.set_alignment(0.0f, 0.5f);
			restart_button.clicked.connect(() => { 
				reset_kernel();
				quick_option_button.popover.popdown();
			});
			quick_option_box.add(restart_button);
			
			quick_option_box.add(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));

			// buttons to quickly change the form of output
			input_form_button = new Gtk.RadioButton.with_label_from_widget (null, "Input Form");
			svg_button = new Gtk.RadioButton.with_label_from_widget (input_form_button, "SVG output");

			// init and connect to global parameters
			input_form_button.active = (Parameter.output == Form.INPUT);
			svg_button.active = (Parameter.output == Form.RENDERED);
			
			input_form_button.toggled.connect(() => { Parameter.output = Form.INPUT; });
			svg_button.toggled.connect(() => { Parameter.output = Form.RENDERED; });

			quick_option_box.add(input_form_button);
			quick_option_box.add(svg_button);
			quick_option_box.show_all();


			quick_option_button = new Gtk.MenuButton();
			quick_option_button.use_popover = true;
			quick_option_button.always_show_image = true;
			quick_option_button.set_image(new Gtk.Image.from_icon_name("document-edit-symbolic", IconSize.BUTTON));
			quick_option_button.popover = new Gtk.Popover(quick_option_button);
			quick_option_button.popover.add(quick_option_box);

			

			// zoom control
			zoom_box = new Gtk.SpinButton.with_range(0.1, 3.0, 0.1);
			zoom_box.digits = 2u;
			zoom_box.numeric = true;
			zoom_box.snap_to_ticks = false;
			zoom_box.update_policy = Gtk.SpinButtonUpdatePolicy.IF_VALID;
			zoom_box.wrap = false;
			zoom_box.set_width_chars(4);
			zoom_box.hexpand = true;
			zoom_box.halign = Gtk.Align.END;
			
			// if no notebook is loaded, have default zoom
			if(notebook_stack.get_visible_child() != null) {
				zoom_box.value = zoom_factor;
			} else {
				zoom_box.value = 1.0;
			}
			
			// connect to application zoom factor
			zoom_box.value_changed.connect(() => {
				zoom_factor = zoom_box.value;
			});

			// things to be done when the notebook tabs are switched
			notebook_stack.notify["visible-child"].connect((property, sender) => {
				
				// update application zoom control from notebook factor
				zoom_box.value = zoom_factor;

				// update notebooks search settings from application settings
				if(notebook_stack.get_visible_child() != null) {
					Gtk.SourceSearchSettings child_settings = ((Seaborg.Notebook) notebook_stack.get_visible_child()).search_settings;
					child_settings.search_text = search_settings.search_text;
					child_settings.case_sensitive = search_settings.case_sensitive;
					child_settings.at_word_boundaries = search_settings.at_word_boundaries;
					child_settings.regex_enabled = search_settings.regex_enabled;
				}

				// update model for tree view from notebook
				notebook_tree.model = (notebook_stack.get_visible_child() != null) ? ((Seaborg.Notebook) notebook_stack.get_visible_child()).tree_model : new Gtk.TreeStore(4, typeof(string), typeof(uint), typeof(string), typeof(ICell));
				notebook_tree.expand_all();

				// if no notebook is visible, do not allow tree sidebar
				if(notebook_stack.get_visible_child() == null) {
					sidebar_revealer.reveal_child = false;
					sidebar_button.active = false;
				}
			});

			

			// preferences window
			preferences_window = new Gtk.Window();
			preferences_window.destroy_with_parent = true;
			preferences_window.set_no_show_all(true);
			preferences_window.window_position = Gtk.WindowPosition.MOUSE;
			preferences_window.deletable = false;
			preferences_window.key_press_event.connect((key) => {
				if(key.type == Gdk.EventType.KEY_PRESS && key.keyval == Gdk.Key.Escape)
					preferences_window.hide();

				return false;
			});

			// button to close window
			Gtk.Button pref_ok_button = new Gtk.Button.from_icon_name("emblem-ok-symbolic");
			pref_ok_button.clicked.connect(() => { preferences_window.hide(); });

			// contents of the preferences window
			Gtk.Grid pref_body = new Gtk.Grid();
			pref_body.halign = Gtk.Align.CENTER;
			pref_body.valign = Gtk.Align.CENTER;
			pref_body.column_spacing = 8;
			pref_body.row_spacing = 16;

			// heading for kernel options
			Gtk.Label kernel_heading = new Gtk.Label("Kernel");
			kernel_heading.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			kernel_heading.get_style_context().add_class("pref-heading");
			kernel_heading.halign = Gtk.Align.START;

			// text field for kernel string
			init_entry = new Gtk.Entry();
			init_entry.set_width_chars(28);
			init_entry.text = Parameter.kernel_init;
			init_entry.editable = true;
			init_entry.changed.connect(() => { Parameter.kernel_init = init_entry.get_text(); });
			
			// box for kernel init string
			Gtk.Box init_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			Gtk.Label init_string_label = new Gtk.Label("   Initialization String:      ");
			init_string_label.halign = Gtk.Align.START;
			init_box.pack_start(init_string_label);
			init_box.pack_end(init_entry);
			Gtk.ListBoxRow init_row = new Gtk.ListBoxRow();
			init_row.activatable = false;
			init_row.selectable = false;
			init_row.add(init_box);

			// list box to hold all kernel options
			Gtk.ListBox kernel_box = new Gtk.ListBox();
			kernel_box.selection_mode = Gtk.SelectionMode.NONE;
			kernel_box.add(init_row);

			// heading for appearence options
			Gtk.Label appearence_heading = new Gtk.Label("Appearence");
			appearence_heading.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			appearence_heading.get_style_context().add_class("pref-heading");
			appearence_heading.halign = Gtk.Align.START;

			// switch for the dark theme preference
			dark_theme_pref = new Gtk.Switch();
			dark_theme_pref.halign = Gtk.Align.CENTER;
			dark_theme_pref.active = Parameter.dark_theme;
			dark_theme_pref.notify["active"].connect((property, sender) => { Parameter.dark_theme = dark_theme_pref.active; });

			// box for the dark theme preference
			Gtk.Label dark_theme_label = new Gtk.Label("   Prefer dark theme   ");
			dark_theme_label.halign = Gtk.Align.START;
			dark_theme_label.hexpand = true;
			Gtk.Box dark_theme_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			dark_theme_box.pack_start(dark_theme_label);
			dark_theme_box.pack_end(dark_theme_pref);
			Gtk.ListBoxRow dark_theme_row = new Gtk.ListBoxRow();
			dark_theme_row.activatable = false;
			dark_theme_row.selectable = false;
			dark_theme_row.add(dark_theme_box);

			// list box to hold all appearence options
			Gtk.ListBox appearence_box = new Gtk.ListBox();
			appearence_box.selection_mode = Gtk.SelectionMode.NONE;
			appearence_box.add(dark_theme_row);

			// code highlighting heading
			Gtk.Label highlighting_heading = new Gtk.Label("Code highlighting");
			highlighting_heading.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			highlighting_heading.get_style_context().add_class("pref-heading");
			highlighting_heading.halign = Gtk.Align.START;

			// radio buttons for syntax highlighting
			highlight_none_button = new Gtk.RadioButton.with_label_from_widget(null, "None");
			highlight_nostdlib_button = new Gtk.RadioButton.with_label_from_widget(highlight_none_button, "Syntax only (recommended)");
			highlight_full_button = new Gtk.RadioButton.with_label_from_widget(highlight_none_button, "Full");
			highlight_none_button.active = (Parameter.code_highlighting == Highlighting.NONE);
			highlight_nostdlib_button.active = (Parameter.code_highlighting == Highlighting.NOSTDLIB);
			highlight_full_button.active = (Parameter.code_highlighting == Highlighting.FULL);
			highlight_none_button.toggled.connect(() => { Parameter.code_highlighting = Highlighting.NONE; });
			highlight_nostdlib_button.toggled.connect(() => { Parameter.code_highlighting = Highlighting.NOSTDLIB; });
			highlight_full_button.toggled.connect(() => { Parameter.code_highlighting = Highlighting.FULL; });

			// boxes for syntax highlighting preference
			Gtk.ListBoxRow highlighting_none_row = new Gtk.ListBoxRow();
			highlighting_none_row.activatable = false;
			highlighting_none_row.selectable = false;
			highlighting_none_row.add(highlight_none_button);
			Gtk.ListBoxRow highlighting_nostdlib_row = new Gtk.ListBoxRow();
			highlighting_nostdlib_row.activatable = false;
			highlighting_nostdlib_row.selectable = false;
			highlighting_nostdlib_row.add(highlight_nostdlib_button);
			Gtk.ListBoxRow highlighting_full_row = new Gtk.ListBoxRow();
			highlighting_full_row.activatable = false;
			highlighting_full_row.selectable = false;
			highlighting_full_row.add(highlight_full_button);

			// list box to hold all syntax highlighting options
			Gtk.ListBox highlighting_box = new Gtk.ListBox();
			highlighting_box.selection_mode = Gtk.SelectionMode.NONE;
			highlighting_box.add(highlighting_none_row);
			highlighting_box.add(highlighting_nostdlib_row);
			highlighting_box.add(highlighting_full_row);

			// code wrap heading
			Gtk.Label wrap_heading = new Gtk.Label("Text wrapping");
			wrap_heading.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			wrap_heading.get_style_context().add_class("pref-heading");
			wrap_heading.halign = Gtk.Align.START;

			// radio buttons for code wrapping
			wrap_none_button = new Gtk.RadioButton.with_label_from_widget(null, "static after characters:   ");
			char_wrap_count_box = new Gtk.SpinButton.with_range(4, 120, 1);
			wrap_char_button = new Gtk.RadioButton.with_label_from_widget(wrap_none_button, "break characters");
			wrap_word_button = new Gtk.RadioButton.with_label_from_widget(wrap_none_button, "break words");
			wrap_word_char_button = new Gtk.RadioButton.with_label_from_widget(wrap_none_button, "break words then characters");
			wrap_none_button.active = (Parameter.wrap_mode == Gtk.WrapMode.NONE);
			wrap_char_button.active = (Parameter.wrap_mode == Gtk.WrapMode.CHAR);
			wrap_word_button.active = (Parameter.wrap_mode == Gtk.WrapMode.WORD);
			wrap_word_char_button.active = (Parameter.wrap_mode == Gtk.WrapMode.WORD_CHAR);
			char_wrap_count_box.value = Parameter.chars_per_line;
			char_wrap_count_box.sensitive = (Parameter.wrap_mode == Gtk.WrapMode.NONE);
			wrap_none_button.toggled.connect(() => { 
				Parameter.wrap_mode = Gtk.WrapMode.NONE; 
				char_wrap_count_box.sensitive = true;
				
				foreach (Gtk.Widget child in notebook_stack.get_children()) {
					((Seaborg.Notebook) child).set_wrap_mode(Parameter.wrap_mode);
				}

				main_window.show_all();
			});
			wrap_char_button.toggled.connect(() => { 
				Parameter.wrap_mode = Gtk.WrapMode.CHAR;
				char_wrap_count_box.sensitive = false;

				foreach (Gtk.Widget child in notebook_stack.get_children()) {
					((Seaborg.Notebook) child).set_wrap_mode(Parameter.wrap_mode);
				}

				main_window.show_all();
			 });
			wrap_word_button.toggled.connect(() => { 
				Parameter.wrap_mode = Gtk.WrapMode.WORD;
				char_wrap_count_box.sensitive = false;

				foreach (Gtk.Widget child in notebook_stack.get_children()) {
					((Seaborg.Notebook) child).set_wrap_mode(Parameter.wrap_mode);
				}

				main_window.show_all();
			});
			wrap_word_char_button.toggled.connect(() => { 
				Parameter.wrap_mode = Gtk.WrapMode.WORD_CHAR;
				char_wrap_count_box.sensitive = false;

				foreach (Gtk.Widget child in notebook_stack.get_children()) {
					((Seaborg.Notebook) child).set_wrap_mode(Parameter.wrap_mode);
				}

				main_window.show_all();
			});
			char_wrap_count_box.notify["value"].connect((property, sender) => {
				Parameter.chars_per_line = (int) char_wrap_count_box.value;
			});

			// boxes for syntax highlighting preference
			Gtk.ListBoxRow  wrap_none_row = new Gtk.ListBoxRow();
			wrap_none_row.activatable = false;
			wrap_none_row.selectable = false;
			Gtk.Box wrap_static_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			wrap_static_box.add(wrap_none_button);
			wrap_static_box.add(char_wrap_count_box);
			wrap_none_row.add(wrap_static_box);
			Gtk.ListBoxRow  wrap_char_row = new Gtk.ListBoxRow();
			wrap_char_row.activatable = false;
			wrap_char_row.selectable = false;
			wrap_char_row.add(wrap_char_button);
			Gtk.ListBoxRow  wrap_word_row = new Gtk.ListBoxRow();
			wrap_word_row.activatable = false;
			wrap_word_row.selectable = false;
			wrap_word_row.add(wrap_word_button);
			Gtk.ListBoxRow  wrap_word_char_row = new Gtk.ListBoxRow();
			wrap_word_char_row.activatable = false;
			wrap_word_char_row.selectable = false;
			wrap_word_char_row.add(wrap_word_char_button);

			// list box to hold all syntax highlighting options
			Gtk.ListBox wrap_box = new Gtk.ListBox();
			wrap_box.selection_mode = Gtk.SelectionMode.NONE;
			wrap_box.add(wrap_none_row);
			wrap_box.add(wrap_char_row);
			wrap_box.add(wrap_word_row);
			wrap_box.add(wrap_word_char_row);



			// phantom boxes to stabilize the layout
			Gtk.Grid l_grid = new Gtk.Grid();
			l_grid.hexpand = true;
			Gtk.Grid r_grid = new Gtk.Grid();
			r_grid.hexpand = true;
			Gtk.Grid t_grid = new Gtk.Grid();
			t_grid.hexpand = true;
			t_grid.vexpand = true;
			Gtk.Grid b_grid = new Gtk.Grid();
			b_grid.hexpand = true;
			b_grid.vexpand = true;

			pref_body.attach(t_grid, 0, 0, 3, 1);
			pref_body.attach(l_grid, 0, 1, 1, 8);
			pref_body.attach(kernel_heading, 1, 1, 1, 1);
			pref_body.attach(kernel_box, 1, 2, 1, 1);
			pref_body.attach(appearence_heading, 1, 3, 1, 1);
			pref_body.attach(appearence_box, 1, 4, 1, 1);
			pref_body.attach(highlighting_heading, 1, 5, 1, 1);
			pref_body.attach(highlighting_box, 1, 6, 1, 1);
			pref_body.attach(wrap_heading, 1, 7, 1, 1);
			pref_body.attach(wrap_box, 1, 8, 1, 1);
			pref_body.attach(r_grid , 2, 1, 1, 8);
			pref_body.attach(b_grid, 0, 9, 3, 1);

			// scrollbar for preferences window
			Gtk.ScrolledWindow pref_scroll = new Gtk.ScrolledWindow(null, null);
			pref_scroll.add(pref_body);
			pref_scroll.show_all();
			
			//header of preferences window
			Gtk.HeaderBar preferences_header = new Gtk.HeaderBar();
			preferences_header.title = "Preferences";
			preferences_header.pack_end(pref_ok_button);
			preferences_header.show_close_button = false;
			preferences_header.show_all();
			
			preferences_window.set_titlebar(preferences_header);
			preferences_window.set_default_size(800, 400);
			preferences_window.add(pref_scroll);
			if(main_icon_handle != null)
				preferences_window.icon = main_icon_handle.get_pixbuf();


			// treeview of notebook
			notebook_tree = new Gtk.TreeView();
			notebook_tree.activate_on_single_click = true;
			notebook_tree.enable_grid_lines = TreeViewGridLines.NONE;
			notebook_tree.enable_search = false;
			notebook_tree.enable_tree_lines = true;
			notebook_tree.headers_visible = false;
			notebook_tree.headers_clickable = false;
			notebook_tree.hover_expand = false;
			notebook_tree.hover_selection = false;
			notebook_tree.reorderable = false;
			notebook_tree.rubber_banding = true;
			notebook_tree.rules_hint = false;
			notebook_tree.show_expanders = true;
			notebook_tree.get_selection().mode = Gtk.SelectionMode.MULTIPLE;

			// focus cell when doing single click on an item
			notebook_tree.row_activated.connect((path, column) => {

				Gtk.TreeIter iter;
				GLib.Value val;

				notebook_tree.model.get_iter(out iter, path);
				notebook_tree.model.get_value(iter, 3, out val);
				((ICell) val.get_object()).focus_cell();

			});

			// select all cells selected in treeview
			notebook_tree.get_selection().set_select_function((selection, model, path, selected) => {
				
				Gtk.TreeIter iter;
				GLib.Value val;
				
				model.get_iter(out iter, path);
				model.get_value(iter, 3, out val);


				((ICell) val.get_object()).marker_selected = !selected;

				return true;

			});

			// popup context menu for cells
			notebook_tree.button_press_event.connect((event) => {
				if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
					
					Gtk.TreeSelection selection = notebook_tree.get_selection();
					
					if(selection.count_selected_rows() == 1) {
						Gtk.TreeIter iter;
						GLib.Value val;
						Gtk.TreeModel model = notebook_tree.model;

						model.get_iter(out iter, selection.get_selected_rows(out model).data);
						model.get_value(iter, 3, out val);

						ICell cell = (ICell) val.get_object();
						if(cell != null) {
							ContextMenu context = new ContextMenu(cell);
							context.popup_at_pointer();
						}
					}
				}

				return false;
			});

			notebook_tree.hexpand = true;
			notebook_tree.halign = Gtk.Align.FILL;
			notebook_tree.resize_mode = Gtk.ResizeMode.PARENT;


			Gtk.CellRendererText renderer = new Gtk.CellRendererText();
			notebook_tree.insert_column_with_attributes(-1, "Title", renderer, "text", 2, null);


			// revealer for tree sidebar
			tree_scroll = new Gtk.ScrolledWindow(null, null);
			tree_scroll.add(notebook_tree);
			tree_scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			tree_scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
			sidebar_revealer.add(tree_scroll);
			sidebar_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
			sidebar_revealer.reveal_child = false;
			sidebar_revealer.hexpand = false;
			sidebar_revealer.halign = Gtk.Align.FILL;
			sidebar_revealer.resize_mode = Gtk.ResizeMode.PARENT;


			// sidebar revealer button
			sidebar_button = new Gtk.ToggleButton();
			sidebar_button.always_show_image = true;
			sidebar_button.set_image(new Gtk.Image.from_icon_name("emblem-shared-symbolic", IconSize.BUTTON));
			sidebar_button.active = sidebar_revealer.reveal_child;
			sidebar_button.toggled.connect(() => {

				if(notebook_stack.get_visible_child() != null) {
					sidebar_revealer.reveal_child = sidebar_button.active;
					main_layout.check_resize();
				} else {
					sidebar_button.active = false;
					sidebar_revealer.reveal_child = false;

				}

			});

			// header
			main_headerbar.show_close_button = true;
			main_headerbar.custom_title = tab_switcher;
			main_headerbar.pack_start(sidebar_button);
			main_headerbar.pack_start(quick_option_button);
			main_headerbar.pack_start(search_button);
			main_headerbar.pack_end(zoom_box);


			// scroll for notebooks
			notebook_scroll.add(notebook_stack);
			// block scrolling on zoom
			notebook_scroll.scroll_event.connect((scroll) => {

				if((bool)(scroll.state & Gdk.ModifierType.CONTROL_MASK)) {
					return true;
				} 
				return false;
			});

			notebook_scroll.hadjustment.notify["page-size"].connect((property, sender) => {
				if(notebook_stack.visible_child != null && notebook_scroll.hadjustment.upper - notebook_scroll.hadjustment.lower > notebook_scroll.hadjustment.page_size) {
					//notebook_stack.visible_child.width_request = (int) notebook_scroll.hadjustment.page_size;
					
					//int minimum_height, natural_height;
					//int width = (int) (0.9*notebook_scroll.hadjustment.page_size);
					
					//notebook_scroll.get_preferred_height_for_width (width, out minimum_height, out natural_height);
					//notebook_scroll.set_size_request(width, minimum_height);

				}
			});


			// main layout
			main_layout.attach(message_bar, 0, 0, 2, 1);
			main_layout.attach(search_bar, 0, 1, 2, 1);
			main_layout.attach(sidebar_revealer, 0, 2, 1, 1);
			main_layout.attach(notebook_scroll, 1, 2, 1, 1);
			main_layout.column_homogeneous = false;
			main_layout.row_homogeneous = false;
			
			// main window
			main_window.add(main_layout);
			main_window.set_help_overlay(shortcuts);
			main_window.destroy.connect(quit_app);
			main_window.window_position = Gtk.WindowPosition.MOUSE;
			if(main_icon_handle != null)
				main_window.icon = main_icon_handle.get_pixbuf();

			// cycle open notebooks
			main_window.key_press_event.connect( (key) => {
				
				if(key.type == Gdk.EventType.KEY_PRESS && (bool)(key.state & Gdk.ModifierType.CONTROL_MASK) && key.keyval == Gdk.Key.Tab) {

					if(notebook_stack.get_children().length() > 1u ) {
						
						if(notebook_stack.get_visible_child() != notebook_stack.get_children().last().data) {
							
							notebook_stack.set_visible_child(
								notebook_stack.get_children().find(notebook_stack.get_visible_child()).next.data
							);

						} else {
							
							notebook_stack.set_visible_child(notebook_stack.get_children().first().data);
						}

					}

					return true;
				}

				return false;

			});

			// zoom by scrolling
			main_window.scroll_event.connect((scroll) => {

				if((bool)(scroll.state & Gdk.ModifierType.CONTROL_MASK)) {

					if(scroll.direction == Gdk.ScrollDirection.UP) { zoom_factor += 0.1; }
					if(scroll.direction == Gdk.ScrollDirection.DOWN) { zoom_factor -= 0.1; }

					return true;
				} 

				return false;
			});

			this.add_window(main_window);

			// if no notebook has been opened, create a new one
			if(notebook_stack.get_children().length() <= 0u)
				new_notebook();

			// connecting kernel
			reset_kernel();
			eval_queue = new Queue<EvaluationData?>();

			main_window.show_all();
			replace_expand.active = false;

			// init notebook tree view
			notebook_tree.model = (notebook_stack.get_visible_child() != null) ? ((Seaborg.Notebook) notebook_stack.get_visible_child()).tree_model : new Gtk.TreeStore(4, typeof(string), typeof(uint), typeof(string), typeof(ICell));
			notebook_tree.expand_all();
			notebook_tree.show_all();




		}

		// connect all global actions to the main menu and its hotkeys
		protected override void startup() {
			base.startup();

			main_menu = new GLib.Menu();
			main_menu.append("New", "app.new");
			main_menu.append("Open", "app.open");
			main_menu.append("Save", "app.save");
			main_menu.append("Save as", "app.saveas");
			main_menu.append("Import", "app.import");
			main_menu.append("Find", "app.find");
			main_menu.append("Preferences", "app.pref");
			main_menu.append("Keyboard Shortcuts", "win.show-help-overlay");
			main_menu.append("Close Notebook", "app.close");
			main_menu.append("Quit", "app.quit");

			this.app_menu = main_menu;

			var new_action = new GLib.SimpleAction("new", null);
			var open_action = new GLib.SimpleAction("open", null);
			var save_action = new GLib.SimpleAction("save", null);
			var save_as_action = new GLib.SimpleAction("saveas", null);
			var import_action = new GLib.SimpleAction("import", null);
			var export_action = new GLib.SimpleAction("export", null);
			var remove_action = new GLib.SimpleAction("rm", null);
			var quit_action = new GLib.SimpleAction("quit", null);
			var eval_action = new GLib.SimpleAction("eval", null);
			var stop_eval_action = new GLib.SimpleAction("stop", null);
			var close_action = new GLib.SimpleAction("close", null);
			var zoom_in_action = new GLib.SimpleAction("zoomin", null);
			var zoom_out_action = new GLib.SimpleAction("zoomout", null);
			var find_action = new GLib.SimpleAction("find", null);
			var pref_action = new GLib.SimpleAction("pref", null);
			var sel_action = new GLib.SimpleAction("sel", null);
			var expand_action = new GLib.SimpleAction("expand", null);

			new_action.activate.connect(() => {
				new_notebook();
			});

			open_action.activate.connect(() => {
				load_dialog();
			});

			save_action.activate.connect(() => {
				if(notebook_stack.get_visible_child != null) {
					
					GLib.FileStream? fs = GLib.FileStream.open(notebook_stack.get_visible_child_name(), "r");
					
					if(fs != null) {

						save_notebook(notebook_stack.get_visible_child_name());
					
					} else {

						save_dialog();
					}
					
				}
			});

			save_as_action.activate.connect(() => {
				save_dialog();
			});

			import_action.activate.connect(() => {
				import_dialog();
			});

			export_action.activate.connect(() => {
				export_dialog();
			});

			quit_action.activate.connect(() => {
				quit_app();
			});

			close_action.activate.connect(() => {

				Gtk.Widget? child = notebook_stack.get_visible_child();

				if(child == null)
					return;
				
				notebook_stack.remove_by_name(notebook_stack.get_visible_child_name());
				delete ((Seaborg.Notebook*) child);
				
			});

			remove_action.activate.connect(() => {
				if(notebook_stack.get_visible_child() != null)
					notebook_remove_children((Seaborg.Notebook)notebook_stack.get_visible_child());
			});

			eval_action.activate.connect(() => {
				if(notebook_stack.get_visible_child() != null)
					schedule_evaluation((Seaborg.Notebook)notebook_stack.get_visible_child());

			});

			stop_eval_action.activate.connect(() => {
				
				try_abort(kernel_connection);
			
			});

			zoom_in_action.activate.connect(() => {
				zoom_factor += 0.1;
			});

			zoom_out_action.activate.connect(() => {
				zoom_factor -= 0.1;
			});

			find_action.activate.connect(() => {
				
				string? sel = Gtk.Clipboard.get_for_display(main_window.get_display(), Gdk.SELECTION_CLIPBOARD).wait_for_text();
				
				if(sel != null) {
					search_entry.set_text(sel);
					
					bool found_last = false;
					if(!((Seaborg.Notebook)notebook_stack.get_visible_child()).do_forward_search(ref found_last)) {
						if(!found_last) {
							found_last = true;
							((Seaborg.Notebook)notebook_stack.get_visible_child()).do_forward_search(ref found_last);
						}
					}
				}
				
				search_bar.search_mode_enabled = true;
			});

			pref_action.activate.connect(() => {
				
				preferences_window.present();

			});

			sel_action.activate.connect(() => {
				if(notebook_stack.get_visible_child() != null) {
					if(!((Seaborg.Notebook) notebook_stack.visible_child).marker_selected) {
						((Seaborg.Notebook) notebook_stack.visible_child).marker_selected = true;
						return;
					} else {
						((Seaborg.Notebook) notebook_stack.visible_child).marker_selection_recursively(false);
						sidebar_button.grab_focus();
					}
				}
			});

			expand_action.activate.connect(() => {
				
				Seaborg.Notebook nb = (Seaborg.Notebook) notebook_stack.visible_child;
				
				if(nb != null) {
					
					ICell first_cell = nb.first_selected_child();
					
					// there is a cell selected
					if(first_cell == null) {
						
						// notebook is empty 
						if(nb.children_cells.data.length <= 0)
							return; 
								
						// grab the first cell in the notebook to decide if expanding or collapsing
						first_cell = nb.children_cells.data[0];
					}

					// the first selected cell is not the notebook itself - use it to determine expand or collapse
					if(first_cell.cell_expanded) {
						((Seaborg.Notebook) notebook_stack.visible_child).collapse_children(! nb.marker_selected, false);
					} else {
						((Seaborg.Notebook) notebook_stack.visible_child).expand_children(! nb.marker_selected);
					}				
				}
			});


			this.add_action(new_action);
			this.add_action(open_action);
			this.add_action(save_action);
			this.add_action(save_as_action);
			this.add_action(import_action);
			this.add_action(export_action);
			this.add_action(remove_action);
			this.add_action(eval_action);
			this.add_action(stop_eval_action);
			this.add_action(quit_action);
			this.add_action(close_action);
			this.add_action(zoom_in_action);
			this.add_action(zoom_out_action);
			this.add_action(find_action);
			this.add_action(pref_action);
			this.add_action(sel_action);
			this.add_action(expand_action);


			const string[] new_accels = {"<Control>N", null};
			const string[] open_accels = {"<Control>O", null};
			const string[] save_accels = {"<Control>S", null};
			const string[] save_as_accels = {"<Control><Alt>S", null};
			const string[] import_accels = {"<Control>I", null};
			const string[] export_accels = {"<Control>E", null};
			const string[] rm_accels = {"<Control>Delete","<Control>D", null};
			const string[] shortcut_accels = {"<Control>F1", "<Control>question", null};
			const string[] eval_accels = {"<Control>Return", "<Control>KP_Enter", null};
			const string[] stop_eval_accels = {"<Control>period", "<Control>S", null};
			const string[] close_accels = {"<Control>W", null};
			const string[] quit_accels = {"<Control>Q", null};
			const string[] zoom_in_accels = {"<Control>plus", "<Control>ZoomIn", "<Control>KP_Add", null};
			const string[] zoom_out_accels = {"<Control>minus", "<Control>ZoomOut", "<Control>KP_Subtract", null};
			const string[] find_accels = {"<Control>F", null};
			const string[] pref_accels = {"<Control>P", null};
			const string[] sel_accels = {"<Control>Escape", null};
			const string[] expand_accels = {"<Control>T", null};

			this.set_accels_for_action("app.new", new_accels);
			this.set_accels_for_action("app.open", open_accels);
			this.set_accels_for_action("app.save", save_accels);
			this.set_accels_for_action("app.saveas", save_as_accels);
			this.set_accels_for_action("app.import", import_accels);
			this.set_accels_for_action("app.export", export_accels);
			this.set_accels_for_action("app.rm", rm_accels);
			this.set_accels_for_action("app.close", close_accels);
			this.set_accels_for_action("app.quit", quit_accels);
			this.set_accels_for_action("win.show-help-overlay", shortcut_accels);
			this.set_accels_for_action("app.eval", eval_accels);
			this.set_accels_for_action("app.stop", stop_eval_accels);
			this.set_accels_for_action("app.zoomin", zoom_in_accels);
			this.set_accels_for_action("app.zoomout", zoom_out_accels);
			this.set_accels_for_action("app.find", find_accels);
			this.set_accels_for_action("app.pref", pref_accels);
			this.set_accels_for_action("app.sel", sel_accels);
			this.set_accels_for_action("app.expand", expand_accels);



		}

		// save the state of the app and quit
		public void quit_app() {

			try {
				GLib.Dir tmp = GLib.Dir.open("tmp/");
				string fn;
				
				while(true) {
					
					fn = tmp.read_name();
					
					if(fn == null)
						break;
					
					GLib.FileUtils.remove("tmp/*.svg" + fn);
					GLib.FileUtils.remove("tmp/*.txt" + fn);
				}
			} catch(GLib.FileError err) {}

			save_preferences();
			
			this.quit();
		}

		// removes all selected cells
		public void notebook_remove_children(ICellContainer container) {

			ICell? cell = null;

			// find cell to be focused after removal
			find_next_cell_after_selected(container, out cell);
			// remove cells
			container.remove_recursively();

			if(container == null)
				return;

			// notebook wiped clean - add the first evaluation cell
			if(container.children_cells.data.length == 0) {
				EvaluationCell* newCell = new EvaluationCell(container);
				container.add_before(-1, {newCell});
				main_window.show_all();
				newCell->focus_cell();
				return;
			}

			// no next cell, or being removed for some reason - default to the first one within the notebook
			if(cell == null)
				cell = container.children_cells.data[container.children_cells.data.length-1];

			// grab focus
			cell.focus_cell();
			return;

		}

		// finds the cell to be focused after removal of the selected ones
		private bool find_next_cell_after_selected(ICellContainer container, out ICell? cell) {
			
			cell = null;
			
			for(int i=container.children_cells.data.length-1; i>=0; i--) {
				
				if(container.children_cells.data[i].marker_selected) {
					if(i+1 < container.children_cells.data.length) {
						cell = container.children_cells.data[i+1];
					} else {
						cell = null;
					}

					return true;
				}

				if(container.children_cells.data[i].get_level() > 0u) {
					if(find_next_cell_after_selected((ICellContainer) container.children_cells.data[i], out cell)) {
						if(cell == null) {
							if(i+1 < container.children_cells.data.length)
								cell = container.children_cells.data[i+1];
						}
						return true;
					}
				}
			}

			return false;
		}

		// queues all selected cells in 'container' for evaluation and focuses the next cell
		public void schedule_evaluation(ICellContainer? container) {

			// no notebook loaded
			if(container == null)
				return;
			
			
			ICellContainer? last_container = null;
			int last_pos = -1;
			bool select_all = false;

			// queue all selected evaluation cells
			schedule_evaluation_recursively(container, ref last_container, ref last_pos, ref select_all);

			// start the evaluation thread if necessary
			start_evalutation_thread();
			
			// no cell was selected
			if(last_pos < 0 || last_container == null)
				return;

			
			// last cell was last element within its parent, create new evaluation cell at its end
			if(last_pos+1 >= last_container.children_cells.data.length) {
				EvaluationCell* newCell = new EvaluationCell(last_container);
				last_container.add_before(-1, {newCell});
				main_window.show_all();
				newCell->focus_cell();
				return;

			}

			// grab focus on next cell
			last_container.children_cells.data[last_pos+1].focus_cell();

		}

		// recursive function to queue all selected cells in 'container' for evaluation, keeps a reference for the parent and child number of the last selected cell
		private void schedule_evaluation_recursively(ICellContainer container, ref ICellContainer? last_container, ref int last_pos, ref bool select_all) {
			
			EvaluationCell eva;
			if(! select_all && container.marker_selected)
				select_all = true;

			// add evalutation cells to be evaluated
			for(int i=0; i<container.children_cells.data.length; i++) {
				
				// schedule cell container children
				if(container.children_cells.data[i] is ICellContainer) {
					schedule_evaluation_recursively((ICellContainer) container.children_cells.data[i], ref last_container, ref last_pos, ref select_all);
					continue;
				}

				// cell is not a container and selected
				if((container.children_cells.data[i].marker_selected || select_all) && container.children_cells.data[i].get_level() == 0 ) {
					last_container = container;
					last_pos = i;

					// cell is an unscheduled valuation cell
					if((! container.children_cells.data[i].lock) && container.children_cells.data[i] is EvaluationCell) {
						eva = (EvaluationCell) container.children_cells.data[i];
						if(check_input(eva.get_text())) {	
							eva.lock = true;
							eva.remove_text();
							lock(eval_queue) {
								eval_queue.push_tail( EvaluationData() { 
									cell = (void*) eva,
									input = replace_form(eva.get_text())
								});
							}
						}
					}
				}
			}
		}

		// removes selected queued evaluation cell in 'container' from the queue, recursive function
		public void unschedule_evaluation(ICellContainer? container) {

			if(container == null)
				return;

			EvaluationCell eva;
			EvaluationData edata;

			// add evalutation cells to be evaluated
			for(int i=0; i<container.children_cells.data.length; i++) {
				
				// unschedule children of container
				if(container.children_cells.data[i] is ICellContainer)
					unschedule_evaluation((ICellContainer) container.children_cells.data[i]);

				// unschedule selected and scheduled evaluation cells
				if(container.children_cells.data[i].marker_selected && ( container.children_cells.data[i].lock) && container.children_cells.data[i].get_level() == 0 && container.children_cells.data[i] is EvaluationCell) {
						
					eva = (EvaluationCell) container.children_cells.data[i];

					lock(eval_queue) {

						for(uint index=0; index < eval_queue.length; index++) {
							edata = eval_queue.peek_nth(index);
							if((EvaluationCell) edata.cell != null && ((EvaluationCell) edata.cell).name == eva.name) {
								eval_queue.pop_nth(index);
							} 
						}
					}
					
					// release lock for unscheduled cells
					eva.lock = false;
						
				}
			}
			
		}
			
		// start evaluation thread, if not already running
		public void start_evalutation_thread() {

			if(listener_thread != null && (!listener_thread_is_running))
				listener_thread.join();

			if(! listener_thread_is_running) {

				listener_thread = new GLib.Thread<void*>("seaborg-listener", () => {

					listener_thread_is_running = true;
					current_cell = EvaluationData();
					while(true) {

						//get next cell data
						lock(eval_queue) {
								
							if(eval_queue.length <= 0)
								break;

							current_cell = eval_queue.pop_head();
						}

						// wait for fist packet
						lock(global_stamp) {
							global_stamp = 1;
						}

						// something is wrong
						if(check_connection(kernel_connection) != 1) {
							GLib.Idle.add( () => {
								abort_eval();
								return false;
							});
							return null;
						}

						evaluate(kernel_connection, current_cell.input, write_to_evaluation_cell, current_cell.cell);

						// something is wrong
						if(check_connection(kernel_connection) != 1) {

   								GLib.Idle.add( () => {
									abort_eval();
									return false;
								});
							return null;
						}

						// wait for evaluation to finish
						while(true) {
							lock(global_stamp) {
								if(global_stamp == 0)
									break;
							}
							GLib.Thread.usleep(200);
						}

							
					}

					listener_thread_is_running = false;
					return null;
				});
			}
		}

		// aborts current evaluation and reset everything
		private void abort_eval() {

			// no new packets to be written
			lock(global_stamp) {
				global_stamp = 0;
			}

			// remove locks
			EvaluationCell* cell = (EvaluationCell*)current_cell.cell;

			if(cell != null) cell->lock = false;
			lock(eval_queue) {
				while(true) {
					
					if(eval_queue.length <= 0)
						break;

					cell = (EvaluationCell*) eval_queue.pop_head().cell;
					if(cell != null) cell->lock = false;
				}

			}

			// reset connection and check sanity
			int res = check_connection(kernel_connection);
			if(res != 1) {
				
				// connection in abort status
				if(res == 2) {

					try_reset_after_abort(kernel_connection);
					if(check_connection(kernel_connection) != 1)
						kernel_msg("Kernel connection lost");

				} else {
					kernel_msg("Kernel connection lost");
				}
			}

			listener_thread_is_running = false;

		}


		private void reset_kernel() {

			if(kernel_connection != null) {
				if(check_connection(kernel_connection) != -1) {
					abort_calculation(kernel_connection);
					close_connection(kernel_connection);


				}
			}

			kernel_connection = init_connection(Parameter.kernel_init);
			if(check_connection(kernel_connection) != 1) {
				kernel_msg("Error resetting connection");
			}
		}

		public void kernel_msg(string msg) {

			foreach (Gtk.Widget child in message_bar.get_content_area().get_children()) {
				message_bar.get_content_area().remove(child);
			}

			Gtk.Label label = new Gtk.Label(msg);
			message_bar.get_content_area().add(label);
			label.show();
			message_bar.show();
		}

		private static  callback_str write_to_evaluation_cell = (_string_to_write, cell_ptr, _stamp, _break) => {
			string string_to_write;

			if(_string_to_write == null) {
				string_to_write = "";
			} else {
				string_to_write = (string) _string_to_write;
			}

			//append to GLib main loop
			GLib.Idle.add( () => {

				lock(global_stamp) {

					// get packet with right stamp
					if(global_stamp != _stamp) {

						// abort has been sent already, throw away packet
						if(global_stamp == 0)
							return false;
						return true;
					}
				
					Seaborg.EvaluationCell* cell_to_write = (Seaborg.EvaluationCell*) cell_ptr;
					
					if( cell_to_write != null) {

						if(string_to_write != "") {
							cell_to_write->add_text("\n"+ string_to_write);
							cell_to_write->expand_all();
						}

						if(_break != 0) {
							cell_to_write->lock=false;
							global_stamp = 0;
							return false;
						}
					}

					global_stamp++;

					return false;
				}
			});

			return;
		};

		private void save_dialog() {
			Gtk.FileChooserDialog saver = new Gtk.FileChooserDialog(
				"Save Notebook",
				main_window,
				Gtk.FileChooserAction.SAVE,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Save",
				Gtk.ResponseType.ACCEPT
			);
			saver.select_multiple = false;
			
			if(notebook_stack.get_visible_child() != null)
				saver.set_filename(notebook_stack.get_visible_child_name());
			
			if(saver.run() == Gtk.ResponseType.ACCEPT ) {
				GLib.SList<string> filenames = saver.get_filenames();
				foreach (string fn in filenames) {
					save_notebook(fn);	
				}
			}

			saver.close();
		}

		private void load_dialog() {
			Gtk.FileChooserDialog loader = new Gtk.FileChooserDialog(
				"Load Notebooks",
				main_window,
				Gtk.FileChooserAction.OPEN,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Load",
				Gtk.ResponseType.ACCEPT
			);
			loader.select_multiple = true;

			Gtk.FileFilter xmlFilter = new Gtk.FileFilter();
			xmlFilter.set_name("Seaborg Notebook *.xml");
			xmlFilter.add_pattern("*.xml");
			loader.add_filter(xmlFilter);
			
			if(notebook_stack.get_visible_child != null)
				loader.set_filename(notebook_stack.get_visible_child_name());
			

			
			if(loader.run() == Gtk.ResponseType.ACCEPT ) {
				GLib.SList<string> filenames = loader.get_filenames();
				foreach (string fn in filenames) {
					load_notebook(fn);	
				}
			}

			loader.close();
		}

		private void import_dialog() {
			Gtk.FileChooserDialog loader = new Gtk.FileChooserDialog(
				"Import Notebooks",
				main_window,
				Gtk.FileChooserAction.OPEN,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Load",
				Gtk.ResponseType.ACCEPT
			);

			loader.select_multiple = false;

			Gtk.FileFilter nbFilter = new Gtk.FileFilter();
			nbFilter.set_name("Mathematica Notebook");
			nbFilter.add_pattern("*.nb");
			nbFilter.add_pattern("*.cdf");
			loader.add_filter(nbFilter);

			Gtk.FileFilter mFilter = new Gtk.FileFilter();
			mFilter.set_name("Plain Text Script");
			mFilter.add_pattern("*.m");
			mFilter.add_pattern("*.txt");
			mFilter.add_pattern("*.wl");
			mFilter.add_pattern("*.wls");
			loader.add_filter(mFilter);

			
			if(loader.run() == Gtk.ResponseType.ACCEPT ) {
				GLib.SList<string> filenames = loader.get_filenames();
				foreach (string fn in filenames) {
					
					if(fn.substring(fn.length-3) == ".nb") {
						process_for_import(fn);
					} else {
						import_plaintext(fn);
					}
				}
			}

			loader.close();
		}

		private void export_dialog() {
			Gtk.FileChooserDialog saver = new Gtk.FileChooserDialog(
				"Save Notebook",
				main_window,
				Gtk.FileChooserAction.SAVE,
				"_Cancel",
				Gtk.ResponseType.CANCEL,
				"_Export",
				Gtk.ResponseType.ACCEPT
			);
			saver.select_multiple = false;
			if(notebook_stack.get_visible_child_name() == "") {
				saver.set_filename("~/New notebook.nb");
			} else {
				saver.set_filename(notebook_stack.get_visible_child_name() + ".nb");
			}
			
			Gtk.FileFilter nbFilter = new Gtk.FileFilter();
			nbFilter.set_name("Mathematica Notebook *.nb");
			nbFilter.add_pattern("*.nb");

			Gtk.FileFilter mFilter = new Gtk.FileFilter();
			mFilter.set_name("Plain Text Script *.m");
			mFilter.add_pattern("*.m");

			saver.add_filter(nbFilter);
			saver.add_filter(mFilter);

			
			if(saver.run() == Gtk.ResponseType.ACCEPT ) {
				GLib.SList<string> filenames = saver.get_filenames();
				foreach (string fn in filenames) {
					if(saver.filter == nbFilter)
						export_notebook(fn);
					if(saver.filter == mFilter)
						export_plaintext(fn);
				}
			}

			saver.close();
		}

		public void new_notebook() {

			Seaborg.Notebook* notebook = new Seaborg.Notebook();
			EvaluationCell* cell = new EvaluationCell(notebook);
			notebook->add_before(0, {cell});

			// check available name
			string base_name = "~/New Notebook";
			Gtk.Widget? child;

			child = notebook_stack.get_child_by_name(base_name + ".xml");
			if(child == null) {
				add_notebook(notebook, base_name + ".xml", make_file_name(base_name + ".xml"));
				cell->focus_cell();
				return;
			} 

			for(int i=2; i>0; i++) {
				child = notebook_stack.get_child_by_name(base_name + "(" + i.to_string() + ").xml");
				if(child == null) {
					add_notebook(notebook, base_name + "(" + i.to_string() + ").xml", make_file_name(base_name + "(" + i.to_string() + ").xml"));
					cell->focus_cell();
					return;
				} 
			}

			kernel_msg("Failed to create new notebook");
			
		}

		public void save_notebook(string fn) {
			GLib.FileStream save_file = GLib.FileStream.open(fn, "w");
			if(save_file == null) {
				kernel_msg("Error saving file: " + fn);
				return;
			}

			string identation="	"; // this is a tab
			save_file.printf("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n\n<notebook version=\"" + get_version_major_string() + "\">\n");
			for(int i = 0; i<((Seaborg.Notebook)notebook_stack.get_visible_child()).children_cells.data.length; i++) {
				write_recursively(((Seaborg.Notebook)notebook_stack.get_visible_child()).children_cells.data[i], save_file, identation);
			}
			save_file.printf("</notebook>");
			save_file.flush();

			if(notebook_stack.get_visible_child_name() != fn) {
				
				notebook_stack.child_amend_name_title(notebook_stack.get_visible_child_name(), fn, make_file_name(fn));
			}

			kernel_msg("File saved successfully");

			return;
		}

		public void load_notebook(string fn) {

			// check if already open

			Gtk.Widget? child = notebook_stack.get_child_by_name(fn);
			
			if(child != null) {
				notebook_stack.visible_child = child;
				return;
			}

			// check if file exists
			GLib.FileStream? file = GLib.FileStream.open(fn, "r");
			if(file == null){
				return;
			}

			// check if it is xml
			char buff[6];
			string? first_chars = file.gets(buff);
			
			if(first_chars == null || first_chars != "<?xml")
				return;

			string? version;

			// parse file 
			Xml.Doc* doc = Xml.Parser.parse_file(fn);
			if(doc == null) {
				kernel_msg("Error opening file: " + fn);
				return;
			}

			// get root node
			Xml.Node* root = doc->get_root_element ();
			if(root == null) {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}
			if(root->name != "notebook") {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}

			// get property
			version = root->get_prop("version");
			if(version == null) {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}
			if(double.parse(version) > get_version_major()) {
				kernel_msg("Warning: file was saved in newer version");
			}

			Seaborg.Notebook* notebook = new Seaborg.Notebook();
			assemble_recursively(root, (ICellContainer*)notebook);
			add_notebook(notebook, fn, make_file_name(fn));
			main_window.show_all();

			delete doc;
			return;
		}

		public void import_notebook(string xml, string fn) {

			// check if already imported

			Gtk.Widget? child = notebook_stack.get_child_by_name(fn + ".xml");
			
			if(child != null) {
				notebook_stack.visible_child = child;
				return;
			}

			// parse xml string 
			Xml.Doc* doc = Xml.Parser.parse_memory(xml, xml.length);
			if(doc == null) {
				kernel_msg("Error opening file: " + fn);
				return;
			}

			// get root node
			Xml.Node* root = doc->get_root_element ();
			if(root == null) {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}
			if(root->name != "notebook") {
				kernel_msg("Error parsing file: " + fn);
				delete doc;
				return;
			}


			Seaborg.Notebook* notebook = new Seaborg.Notebook();
			assemble_recursively(root, (ICellContainer*)notebook);
			add_notebook(notebook, fn + ".xml", make_file_name(fn));
			main_window.show_all();

			delete doc;
			return;


		}


		public void export_notebook(string fn) {

			if(listener_thread_is_running) {
				kernel_msg("Cannot export notebook: kernel is busy");
				return;
			}

			string export_string = "Export[\"" + fn + "\", Notebook[{" + list_cells_recursively((Seaborg.ICellContainer)notebook_stack.get_visible_child()) + "}]]";

			listener_thread_is_running = true;
			listener_thread = new GLib.Thread<void*>("seaborg-export", () => {

				// wait for fist packet
				lock(global_stamp) {
					global_stamp = 1;
				}

				// something is wrong
				if(check_connection(kernel_connection) != 1) {
					abort_listener_thread();
					return null;
				}

				current_cell = EvaluationData() {
					cell = (void*) this,
					input = fn
				};

				evaluate(
					kernel_connection, 
					export_string,
					export_notebook_callback, 
					(void*) &current_cell
				);

				// something is wrong
				if(check_connection(kernel_connection) != 1) {
					abort_listener_thread();
					return null;
				}

				while(true) {
					
					GLib.Thread.usleep(200);
					
					lock(global_stamp) {
					
						if(global_stamp == 0)
							break;
					}
				}
				
				listener_thread_is_running = false;
				return null;

			});
		}

		public void import_plaintext(string fn) {

			// check if already open

			Gtk.Widget? child = notebook_stack.get_child_by_name(fn + ".xml");
			
			if(child != null) {
				notebook_stack.visible_child = child;
				return;
			}

			// check if file exists
			GLib.FileStream? fs = GLib.FileStream.open(fn, "r");
			if(fs == null){
				kernel_msg("Error opening file: " + fn);
				return;
			}

			string content = "";
			string? line = null;

			while(! fs.eof()) {
				
				line = fs.read_line();
				if(line == null)
					break;
				content = content + "\n" + line;
			}

			Seaborg.Notebook* notebook = new Seaborg.Notebook();
			Seaborg.EvaluationCell* cell = new Seaborg.EvaluationCell(notebook);
			cell->set_text(content);
			notebook->add_before(0, {cell});
			
			add_notebook(notebook, fn + ".xml", make_file_name(fn));
			main_window.show_all();

		}

		public void export_plaintext(string fn) {

			GLib.FileStream? fs = GLib.FileStream.open(fn, "w");
			if(fs == null) {
				kernel_msg("Could not open file: " + fn);
				return;
			}
			
			if((ICellContainer) notebook_stack.get_visible_child() != null)
				write_plaintext_receursively(fs, (ICellContainer) notebook_stack.get_visible_child());

			fs.flush();

			kernel_msg("File exported successfully: " + fn);
		}

		private void write_plaintext_receursively(GLib.FileStream fs, ICellContainer container) {
			
			string cell_text;
			
			for(int i=0; i<container.children_cells.data.length; i++) {

				cell_text = container.children_cells.data[i].get_text();
				
				if(container.children_cells.data[i].get_level() == 0) {
					if(container.children_cells.data[i] is EvaluationCell) {
						
						fs.printf(cell_text + "\n");
					
					} else {
						
						fs.printf("(*\n" + cell_text + "\n*)\n");
					}
				} else {

					fs.printf("\n");
					cell_text = cell_text.replace("\n","");
					fs.printf("(*" + string.nfill(cell_text.length + 2, '*') + "*)\n(* " + cell_text + " *)\n(*" + string.nfill(cell_text.length + 2, '*') + "*)\n");

					write_plaintext_receursively(fs, (ICellContainer) container.children_cells.data[i]);

				}

				fs.printf("\n");
			}

		}

		private string list_cells_recursively(ICellContainer container) {
			string str = "";
			for(int i=0; i<container.children_cells.data.length; i++) {
				if((container.children_cells.data[i]) is TextCell) {
					
					if(str != "")
						str += ", ";

					str += "Cell[\"" + ((Seaborg.TextCell) container.children_cells.data[i]).get_text().replace("\"", "\\\"")  + "\", \"Text\"]";
					continue;
				}

				if((container.children_cells.data[i]) is EvaluationCell) {
					
					if(str != "")
						str += ", ";

					str += "Cell[BoxData[RowBox[{\"" + ((Seaborg.EvaluationCell) container.children_cells.data[i]).get_text().replace("\"", "\\\"") + "\"}]], \"Input\"],";
					str += "Cell[BoxData[RowBox[{\"" + ((Seaborg.EvaluationCell) container.children_cells.data[i]).get_output_text().replace("\"", "\\\"")  + "\"}]], \"Output\"]";
					continue;
				}

				if((container.children_cells.data[i]) is CellContainer) {
					
					if(str != "")
						str += ", ";

					switch(((Seaborg.CellContainer) container.children_cells.data[i]).get_level()) {
						case 1:
							str += "Cell[\"" + ((Seaborg.CellContainer) container.children_cells.data[i]).get_text().replace("\n", "").replace("\"", "\\\"") + "\", \"Subsubsection\"]";
							break;
						case 2:
							str += "Cell[\"" + ((Seaborg.CellContainer) container.children_cells.data[i]).get_text().replace("\n", "").replace("\"", "\\\"") + "\", \"Subsection\"]";
							break;
						case 3:
							str += "Cell[\"" + ((Seaborg.CellContainer) container.children_cells.data[i]).get_text().replace("\n", "").replace("\"", "\\\"") + "\", \"Section\"]";
							break;
						case 4:
							str += "Cell[\"" + ((Seaborg.CellContainer) container.children_cells.data[i]).get_text().replace("\n", "").replace("\"", "\\\"") + "\", \"Subchapter\"]";
							break;
						case 5:
							str += "Cell[\"" + ((Seaborg.CellContainer) container.children_cells.data[i]).get_text().replace("\n", "").replace("\"", "\\\"") + "\", \"Chapter\"]";
							break;
						case 6:
							str += "Cell[\"" + ((Seaborg.CellContainer) container.children_cells.data[i]).get_text().replace("\n", "").replace("\"", "\\\"") + "\", \"Title\"]";
							break;
						default:
							str += "Cell[\"" + ((Seaborg.CellContainer) container.children_cells.data[i]).get_text().replace("\n", "").replace("\"", "\\\"") + "\", \"Text\"]";
							break;
					}

					if(((Seaborg.CellContainer) container.children_cells.data[i]).children_cells.data.length > 0) {
						str += ", " + list_cells_recursively(((Seaborg.ICellContainer*) container.children_cells.data[i]));
					}
					
					continue;
				}
			}

			return str;

		}


		private void assemble_recursively(Xml.Node* root, ICellContainer* container) {
			
			string? type;
			Seaborg.TextCell* tcell;
			Seaborg.EvaluationCell* ecell;
			Seaborg.CellContainer* ccell;


			for(Xml.Node* iter = root->children; iter != null; iter = iter->next) {
				if(iter->type == Xml.ElementType.ELEMENT_NODE) {
					if(iter->name == "cell") {
						
						type = iter->get_prop("type");
						if(type == null) continue;

						switch (type) {
							case "evaluation":
								ecell = new EvaluationCell(container);
								for(Xml.Node* iter2 = iter->children; iter2 != null; iter2 = iter2->next) {

									if(iter2->name == "content") {
										ecell->set_text(load_replacement(iter2->get_content()));
									} else {
										if(iter2->name == "results") {
											for(Xml.Node* iter3 = iter2->children; iter3 != null; iter3 = iter3->next) {
												if(iter3->name == "result") {
													switch (iter3->get_prop("type")) {
														case null: 
															break;
														case "text":
															ecell->add_text("\n" + load_replacement(iter3->get_content()));
															ecell->expand_all();
															break;							
													}
												}
											}
										}
									}
								}
								container->add_before(-1, {ecell});
								break;
							case "text":
								for(Xml.Node* iter2 = iter->children; iter2 != null; iter2 = iter2->next) {
									if(iter2->name == "content") {
										tcell = new Seaborg.TextCell(container);
										tcell->set_text(load_replacement(iter2->get_content()));
										container->add_before(-1, {tcell});
									}	
								}
								break;
							case "container":
								ccell = new CellContainer(container, 1);
								for(Xml.Node* iter2 = iter->children; iter2 != null; iter2 = iter2->next) {
									if(iter2->name == "content") {
										ccell->set_text(load_replacement(iter2->get_content()));
									} else {
										if(iter2->name == "level") {
											ccell->set_level((uint) int.parse(iter2->get_content()));
										} else {
											if(iter2->name == "children") { 
												assemble_recursively(iter2, (ICellContainer*)ccell);
												ccell->expand_all();
											}
										}
									}
								}
								container->add_before(-1, {ccell});
								break;

						}
					}
				}
			}
		}


		private void write_recursively(ICell cell, FileStream file, string identation) {
			if(cell is TextCell) {
				TextCell textcell = (TextCell) cell;
				
				file.printf(identation + "<cell type=\"text\">\n");
				file.printf(identation + "	<level>0</level>\n");
				file.printf(identation + "	<content>%s</content>\n", save_replacement(textcell.get_text()));
				file.printf(identation + "	<results></results>\n");
				file.printf(identation + "	<children></children>\n");
				file.printf(identation + "</cell>\n");
			}
			if(cell is EvaluationCell) {
				EvaluationCell evalcell = (EvaluationCell) cell;

				file.printf(identation + "<cell type=\"evaluation\">\n");
				file.printf(identation + "	<level>0</level>\n");
				file.printf(identation + "	<content>%s</content>\n", save_replacement(evalcell.get_text()));
				file.printf(identation + "	<results>\n" + identation + "		<result type=\"text\">%s</result>\n" + identation + "	</results>\n", save_replacement(evalcell.get_output_text()));
				file.printf(identation + "	<children></children>\n");
				file.printf(identation + "</cell>\n");
			}
			if(cell is CellContainer) {
				CellContainer cellcontainer = (CellContainer)cell;
				
				file.printf(identation + "<cell type=\"container\">\n");
				file.printf(identation + "	<level>%i</level>\n", cellcontainer.get_level());
				file.printf(identation + "	<content>%s</content>\n", save_replacement(cellcontainer.get_text()));
				file.printf(identation + "	<results></results>\n");
				file.printf(identation + "	<children>\n");

				for(int i=0; i<cellcontainer.children_cells.data.length; i++)
					write_recursively(cellcontainer.children_cells.data[i], file, identation + "		");


				file.printf(identation + "	</children>\n");
				file.printf(identation + "</cell>\n");
			}
		}

		private void process_for_import(string fn) {
			
			if(listener_thread_is_running) {
				kernel_msg("Cannot import notebook: kernel is busy");
				return;
			}

			listener_thread_is_running = true;
			listener_thread = new GLib.Thread<void*>("seaborg-import", () => {

				// wait for fist packet
				lock(global_stamp) {
					global_stamp = 1;
				}

				// something is wrong
				if(check_connection(kernel_connection) != 1) {
					abort_listener_thread();
					return null;
				}


				FileStream? import_script = FileStream.open("res/wolfram_scripts/import.m", "r");
				
				if(import_script == null) {
					abort_listener_thread();
					return null;
				}

				string import_string = "";

				while(!import_script.eof()) {
					import_string += import_script.read_line();
				}

				current_cell = EvaluationData() {
					cell = (void*) this,
					input = fn
				};

				evaluate(
					kernel_connection, 
					import_string + "\nSeaborgNotebookImport[\"" + fn + "\"]",
					receive_notebook_xml, 
					(void*) &current_cell
				);

				// something is wrong
				if(check_connection(kernel_connection) != 1) {
					abort_listener_thread();
					return null;
				}

				while(true) {
					
					GLib.Thread.usleep(200);
					
					lock(global_stamp) {
					
						if(global_stamp == 0)
							break;
					}
				}
				
				listener_thread_is_running = false;
				return null;

			});

		}

		private void save_preferences() {
			GLib.FileStream save_file = GLib.FileStream.open("config.xml", "w");
			if(save_file == null) {
				kernel_msg("Error saving preferences");
				return;
			}

			int w_width, w_height;
			string? fn = null;

			main_window.get_size(out w_width, out w_height);

			save_file.printf("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
			save_file.printf("<seaborg version=\"" + get_version_major_string() + "\">\n");
			save_file.printf("	<kernel_init>" + Parameter.kernel_init  + "</kernel_init>\n");
			save_file.printf("	<code_highlighting>" + Parameter.code_highlighting.to_string() + "</code_highlighting>\n");
			save_file.printf("	<dark_theme>" + Parameter.dark_theme.to_string() + "</dark_theme>\n");
			save_file.printf("	<output>" + Parameter.output.to_string() + "</output>\n");
			save_file.printf("	<wrap_mode>" + Parameter.wrap_mode.to_string() + "</wrap_mode>\n");
			save_file.printf("	<chars_per_line>" + Parameter.chars_per_line.to_string() + "</chars_per_line>\n");
			save_file.printf("	<search_match_case>" + search_settings.case_sensitive.to_string() + "</search_match_case>\n");
			save_file.printf("	<search_match_word>" + search_settings.at_word_boundaries.to_string() + "</search_match_word>\n");
			save_file.printf("	<search_match_regex>" + search_settings.regex_enabled.to_string() + "</search_match_regex>\n");
			save_file.printf("	<window_width>" + w_width.to_string() + "</window_width>\n");
			save_file.printf("	<window_height>" + w_height.to_string() + "</window_height>\n");
			save_file.printf("	<open_notebooks>\n");

			foreach (Gtk.Widget child in notebook_stack.get_children()) {

				notebook_stack.set_visible_child(child);
				fn = notebook_stack.get_visible_child_name();

				if(fn != null && fn != "") {

					save_file.printf("		<notebook>\n");
					save_file.printf("			<name>" + fn + "</name>\n");
					save_file.printf("			<zoom>" + ((Seaborg.Notebook) child).zoom_factor.to_string() + "</zoom>\n");
					save_file.printf("		</notebook>\n");

				}

				
			}

			save_file.printf("	</open_notebooks>\n");
			save_file.printf("</seaborg>\n");
			save_file.flush();

			return;
		}

		private void load_preferences() {

			// apply defaults
			int width = 800;
			int height = 600;
			double zfactor;
			string fn,version;

			main_window.set_default_size(width, height);

			Parameter.kernel_init = "-linkname \"math -wstp -mathlink\"";

			// check if preference file exists at all
			GLib.FileStream? pref = GLib.FileStream.open("config.xml", "r");
			if(pref == null)
				return;

			// parse xml string 
			Xml.Doc* doc = Xml.Parser.parse_file("config.xml");
			if(doc == null) {
				return;
			}

			// get root node
			Xml.Node* root = doc->get_root_element ();
			if(root == null) {
				kernel_msg("Error parsing config file");
				delete doc;
				return;
			}

			if(root->name != "seaborg") {
				delete doc;
				return;
			}

			// get version
			version = root->get_prop("version");
			if(version == null) {
				kernel_msg("Error parsing config file");
				delete doc;
				return;
			}
			if(double.parse(version) > get_version_major()) {
				kernel_msg("Warning: config file belongs to newer version");
			}

			for(Xml.Node* iter = root->children; iter != null; iter = iter->next) {
				if(iter->type == Xml.ElementType.ELEMENT_NODE) {
					switch (iter->name) {
						
						case "kernel_init":
							
							Parameter.kernel_init = iter->get_content();				
							break;
					
						case "code_highlighting":
							
							switch(iter->get_content()) {
								case "SEABORG_HIGHLIGHING_NONE":
									Parameter.code_highlighting = Highlighting.NONE;
									break;
								case "SEABORG_HIGHLIGHING_NOSTDLIB":
									Parameter.code_highlighting = Highlighting.NOSTDLIB;
									break;
								case "SEABORG_HIGHLIGHING_FULL":
									Parameter.code_highlighting = Highlighting.FULL;
									break;
							}
							break;

						case "dark_theme":

							Parameter.dark_theme = bool.parse(iter->get_content());
							break;

						case "output":

							switch (iter->get_content()) {
								case "SEABORG_FORM_INPUT":
									Parameter.output = Form.INPUT;
									break;
								case "SEABORG_FORM_RENDERED":
									Parameter.output = Form.RENDERED;
									break;
							}
							break;

						case "wrap_mode":

							switch (iter->get_content()) {
								case "GTK_WRAP_NONE":
									Parameter.wrap_mode = Gtk.WrapMode.NONE;
									break;
								case "GTK_WRAP_CHAR":
									Parameter.wrap_mode = Gtk.WrapMode.CHAR;
									break;
								case "GTK_WRAP_WORD":
									Parameter.wrap_mode = Gtk.WrapMode.WORD;
									break;
								case "GTK_WRAP_WORD_CHAR":
									Parameter.wrap_mode = Gtk.WrapMode.WORD_CHAR;
									break;
							}
							break;

						case "chars_per_line":
							
							Parameter.chars_per_line = int.parse(iter->get_content());
							if(Parameter.chars_per_line < 4 || Parameter.chars_per_line > 120)
								Parameter.chars_per_line = 80;
							break;

						case "search_match_case":

							search_settings.case_sensitive = bool.parse(iter->get_content());
							break;

						case "search_match_word":

							search_settings.at_word_boundaries = bool.parse(iter->get_content());
							break;

						case "search_match_regex":

							search_settings.regex_enabled = bool.parse(iter->get_content());
							break;

						case "window_width":
							
							width = int.parse(iter->get_content());
							if(width <= 0)
								width = 800;
							break;

						case "window_height":
							
							height = int.parse(iter->get_content());
							if(height <= 0)
								height = 600;
							break;

						case "open_notebooks":

							for(Xml.Node* iter2 = iter->children; iter2 != null; iter2 = iter2->next) {
								if(iter2->name == "notebook") {
									
									zfactor = 1.0;
									fn = "";

									for(Xml.Node* iter3 = iter2->children; iter3 != null; iter3 = iter3->next) {

										

										switch (iter3->name) {
											case "name":
												fn = iter3->get_content();
												break;

											case "zoom":
												zfactor = double.parse(iter3->get_content());
												if(zfactor < 0.1 || zfactor > 3.0) {
													zfactor = 1.0;
												}
												break;
										}

									}

									if(fn != null && fn != "") {
										load_notebook(fn);
										zoom_factor = zfactor;
									}
								}
							}

							break;
					
					}
				}
			}

			main_window.resize(width, height);

			delete doc;
			return;
		}


		private void abort_listener_thread() {

			// no new packets to be written
			lock(global_stamp) {
				global_stamp = 0;
			}

			// reset connection and check sanity
			int res = check_connection(kernel_connection);
			if(res != 1) {
				if(res == 2) {

					try_reset_after_abort(kernel_connection);
					if(check_connection(kernel_connection) != 1)
						kernel_msg("Kernel connection lost");

				} else {
					kernel_msg("Kernel connection lost");
				}
			}

			listener_thread_is_running = false;

		}

		// adding notebook to stack
		private void add_notebook(Seaborg.Notebook* nb, string name, string title) {

			notebook_stack.add_titled(nb, name, title);

			// update visible treemodel on switch of tabs
			nb->notify["tree-model"].connect((property, sender) => {
				if(notebook_stack.get_visible_child() != null && ((Seaborg.Notebook) notebook_stack.get_visible_child()).name == nb->name) {
					notebook_tree.model = nb->tree_model;
					notebook_tree.expand_all();
				}
			});

			// jump to cell when focused
			nb->cell_focused.connect((widget) => {
				if(notebook_stack.get_visible_child() != null && ((Seaborg.Notebook) notebook_stack.get_visible_child()).name == nb->name) {
					int x,y;
					main_window.check_resize();
					if(notebook_stack.translate_coordinates(widget, 0, 0, out x, out y)) {
						// scroll to the cell, but keep a tiny bit space on top
						if(((double) y).abs() > notebook_scroll.vadjustment.value + notebook_scroll.vadjustment.page_size)
							notebook_scroll.vadjustment.value = ((double) y).abs() - notebook_scroll.vadjustment.step_increment;
					}
				}
			});
		}

		// callback to convert mathematica notebook into seaborg notebook
		private static  callback_str receive_notebook_xml = (_string_to_write, data_ptr, _stamp, _break) => {

			string string_to_write = (string) _string_to_write;
			EvaluationData* data = (EvaluationData*) data_ptr;

			//append to GLib main loop
			GLib.Idle.add( () => {

				lock(global_stamp) {
					
					// get packet with right stamp
					if(global_stamp != _stamp) {

						// abort has been sent already, throw away packet
						if(global_stamp == 0)
							return false;
						return true;
					}

					// only interested in last package
					if(_break != 0) {
						
						if(string_to_write == null || data == null)
							return false;

						if(data->cell == null || data->input == null)
							return false;

						SeaborgApplication* app = (SeaborgApplication*) data->cell;

						if(app == null)
							return false;

						if(string_to_write.substring(0, 5) != "<?xml") {
							app->kernel_msg("Error importing notebook");
						}

						app->import_notebook(string_to_write, data->input);


						global_stamp = 0;
						return false;

					}

					global_stamp++;

					return false;
				}
			});

			return;
		};

		// callback function for exporting to mathematica notebook
		private static  callback_str export_notebook_callback = (_string_to_write, data_ptr, _stamp, _break) => {


			//append to GLib main loop
			GLib.Idle.add( () => {

				lock(global_stamp) {
					
					// get packet with right stamp
					if(global_stamp != _stamp) {

						// abort has been sent already, throw away packet
						if(global_stamp == 0)
							return false;
						return true;
					}

					// only interested in last package
					if(_break != 0) {

						string string_to_write = (string) _string_to_write;
						EvaluationData* data = (EvaluationData*) data_ptr;
						
						if(string_to_write == null || data == null)
							return false;

						if(data->cell == null || data->input == null)
							return false;

						SeaborgApplication* app = (SeaborgApplication*) data->cell;

						if(app == null)
							return false;

						if(string_to_write != data->input) {
							app->kernel_msg("Error exporting notebook");
						}


						global_stamp = 0;
						return false;

					}

					global_stamp++;

					return false;
				}
			});

			return;
		};

		private EvaluationData current_cell;

		// kernel connection backend

		[CCode (has_target = false)]
		private delegate void callback_str(char* string_to_write, void* callback_data, ulong stamp, int break_after);

		[CCode(cname = "init_connection", cheader_filename = "wstp_connection.h")]
		private extern static void* init_connection(char* path);

		[CCode(cname = "close_connection", cheader_filename = "wstp_connection.h")]
		private extern static void close_connection(void* connection);

		[CCode(cname = "evaluate", cheader_filename = "wstp_connection.h")]
		private extern static void evaluate(void* con, char* input, callback_str callback, void* callback_data);

		[CCode(cname = "check_connection", cheader_filename = "wstp_connection.h")]
		private extern static int check_connection(void* con);

		[CCode(cname = "try_abort", cheader_filename = "wstp_connection.h")]
		private extern static int try_abort(void* con);

		[CCode(cname = "try_reset_after_abort", cheader_filename = "wstp_connection.h")]
		private extern static int try_reset_after_abort(void* con);

		[CCode(cname = "abort_calculation", cheader_filename = "wstp_connection.h")]
		private extern static int abort_calculation(void* con);

		private double zoom_factor {
			get {
				return (notebook_stack.get_visible_child()) != null ? ((Seaborg.Notebook)notebook_stack.get_visible_child()).zoom_factor : 1.0;
			}

			set {
				
				if(value > 3.0 || value < 0.1)
					return;

				if(notebook_stack.get_visible_child() != null)
					((Seaborg.Notebook)notebook_stack.get_visible_child()).zoom_font(value);
				if(zoom_box != null)
					zoom_box.value = zoom_factor;

			}
		}

		private Gtk.ApplicationWindow main_window;
		private Gtk.HeaderBar main_headerbar;
		private Seaborg.TabSwitcher tab_switcher;
		private Seaborg.Stack notebook_stack;
		private GLib.Menu main_menu;
		private Gtk.Grid main_layout;
		private Gtk.Revealer sidebar_revealer;
		private Gtk.InfoBar message_bar;
		private Gtk.SearchBar search_bar;
		private Gtk.SearchEntry search_entry;
		private Gtk.ToggleButton search_button;
		private Gtk.SourceSearchSettings search_settings;
		private Gtk.FlowBox search_box;
		private Gtk.ToggleButton search_case;
		private Gtk.ToggleButton search_word;
		private Gtk.ToggleButton search_regex;
		private Gtk.Button search_next;
		private Gtk.Button search_prev;
		private Gtk.ToggleButton replace_expand;
		private Gtk.Box replace_box;
		private Gtk.Entry replace_entry;
		private Gtk.Button replace_all_button;
		private Gtk.SpinButton zoom_box;
		private Gtk.ScrolledWindow notebook_scroll;
		private Gtk.ShortcutsWindow shortcuts;
		private Gtk.MenuButton quick_option_button;
		private Gtk.RadioButton input_form_button;
		private Gtk.RadioButton svg_button;
		private Gtk.Window preferences_window;
		private Gtk.Entry init_entry;
		private Gtk.Switch dark_theme_pref;
		private Gtk.RadioButton highlight_none_button;
		private Gtk.RadioButton highlight_nostdlib_button;
		private Gtk.RadioButton highlight_full_button;
		private Gtk.SpinButton char_wrap_count_box;
		private Gtk.RadioButton wrap_none_button;
		private Gtk.RadioButton wrap_char_button;
		private Gtk.RadioButton wrap_word_button;
		private Gtk.RadioButton wrap_word_char_button;
		private Gtk.ToggleButton sidebar_button;
		private Gtk.TreeView notebook_tree;
		private Gtk.ScrolledWindow tree_scroll;
		private void* kernel_connection;
		private GLib.Queue<EvaluationData?> eval_queue;
		private GLib.Thread<void*> listener_thread;
		private bool listener_thread_is_running=false;
		private CssProvider css_provider;
		private Rsvg.Handle? main_icon_handle;
	}


	int main(string[] args) {

		// command line interface
		bool cli_version = false;

		GLib.OptionEntry[] options = new GLib.OptionEntry[2];
		options[0] = { "version", 0, 0, OptionArg.NONE, ref cli_version, "Display version number", null };
		options[1] = { null };


		try {
			
			OptionContext opt_context = new OptionContext ("[NOTEBOOKS]");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries ( options , null);
			opt_context.parse (ref args);
		
		} catch (OptionError e) {
			
			stdout.printf ("error: %s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			
			return 0;
		}

		// return only version
		if(cli_version) {
			
			stdout.printf("Seaborg %s \n", Parameter.version);
			return 0;
		}

		return new SeaborgApplication().run(args);
		
	}
}
