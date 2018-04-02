namespace Seaborg {

	static string get_version_major_string() { return Parameter.version.substring(0, Parameter.version.last_index_of("."));}

	static double get_version_major() {

		double res = 0.0;
		double.try_parse(get_version_major_string(), out res);
		return res;
	}

	static bool check_input(string str) {
		return str.replace(" ", "").replace("	", "").replace("\n", "") != "";
	}

	static void replace_characters(ref Gtk.SourceBuffer buf) {
			buf.text = buf.text

			 // small greek letters
			.replace("⋮a⋮", "α")
			.replace("⋮b⋮", "β")
			.replace("⋮g⋮", "γ")
			.replace("⋮d⋮", "δ")
			.replace("⋮e⋮", "ϵ")
			.replace("⋮z⋮", "z")
			.replace("⋮et⋮", "η")
			.replace("⋮h⋮", "η")
			.replace("⋮th⋮", "θ")
			.replace("⋮q⋮", "θ")
			.replace("⋮i⋮", "ι")
			.replace("⋮k⋮", "κ")
			.replace("⋮l⋮", "λ")
			.replace("⋮m⋮", "μ")
			.replace("⋮n⋮", "ν")
			.replace("⋮x⋮", "ξ")
			.replace("⋮om⋮", "ο")
			.replace("⋮p⋮", "π")
			.replace("⋮r⋮", "ρ")
			.replace("⋮s⋮", "σ")
			.replace("⋮t⋮", "τ")
			.replace("⋮u⋮", "υ")
			.replace("⋮ph⋮", "ϕ")
			.replace("⋮f⋮", "ϕ")
			.replace("⋮ch⋮", "χ")
			.replace("⋮c⋮", "χ")
			.replace("⋮ps⋮", "ψ")
			.replace("⋮y⋮", "ψ")
			.replace("⋮o⋮", "ω")
			.replace("⋮w⋮", "ω")

			// capital greek letters
			.replace("⋮A⋮", "Α")
			.replace("⋮B⋮", "Β")
			.replace("⋮G⋮", "Γ")
			.replace("⋮D⋮", "Δ")
			.replace("⋮E⋮", "Ε")
			.replace("⋮Z⋮", "Ζ")
			.replace("⋮Et⋮", "Η")
			.replace("⋮H⋮", "Η")
			.replace("⋮Th⋮", "Θ")
			.replace("⋮Q⋮", "Θ")
			.replace("⋮I⋮", "Ι")
			.replace("⋮K⋮", "Κ")
			.replace("⋮L⋮", "Λ")
			.replace("⋮M⋮", "Μ")
			.replace("⋮N⋮", "Ν")
			.replace("⋮X⋮", "Ξ")
			.replace("⋮O⋮", "Ο")
			.replace("⋮P⋮", "Π")
			.replace("⋮R⋮", "Ρ")
			.replace("⋮S⋮", "Σ")
			.replace("⋮T⋮", "Τ")
			.replace("⋮U⋮", "Υ")
			.replace("⋮Ph⋮", "Φ")
			.replace("⋮F⋮", "Φ")
			.replace("⋮Ch⋮", "Χ")
			.replace("⋮C⋮", "Χ")
			.replace("⋮Ps⋮", "Ψ")
			.replace("⋮Y⋮", "Ψ")
			.replace("⋮O⋮", "Ω")
			.replace("⋮W⋮", "Ω")

			// special letters
			.replace("⋮mi⋮", "µ")
			.replace("⋮Ang⋮", "Å")
			.replace("⋮hb⋮", "ℏ")
			.replace("⋮wp⋮", "℘")
			.replace("⋮ce⋮", "ε")
			.replace("⋮cth⋮", "ϑ")
			.replace("⋮cq⋮", "ϑ")
			.replace("⋮ck⋮", "ϰ")
			.replace("⋮cp⋮", "ϖ")
			.replace("⋮cr⋮", "ϱ")
			.replace("⋮fs⋮", "ς")
			.replace("⋮cph⋮", "φ")
			.replace("⋮j⋮", "φ")
			.replace("⋮cU⋮", "ϒ");

	}

	static string make_file_name(string _str) {
		string str = _str;
		int i;
		
		i = str.last_index_of("/");
		if(i >= 0)
			str = str.substring(i+1);

		i = str.last_index_of(".");
		if(i > 0)
			str = str.substring(0, i);

		return str;
	}

	static string save_replacement(string str) {
		return str.replace("\n", "$NEWLINE").replace("<", "$BRA").replace(">", "$KET").replace("&","$AMPERSAND");
	}

	static string load_replacement(string str) {
		return str.replace("$NEWLINE","\n").replace("$BRA", "<").replace("$KET", ">").replace("$AMPERSAND","&");
	}

	static string comment_transform(string str) {

		string test_str = str.replace(" ", "").replace("\n","");

		if(test_str.substring(0,2) == "(*" && test_str.substring(-2, 2) == "*)") {
			int pos1 = str.index_of("(*");
			int pos2 = str.last_index_of("*)");
			if( pos1 < 0 || pos1 > pos2 || pos2 >= str.length) return str;
			return str.substring(0, pos1) + str.substring(pos1+2, pos2-pos1-2) + str.substring(pos2+2, str.length-pos2-2);
		}

		return "(*" + str + "*)";
	}


	static string replace_form(string str) {
		switch (Parameter.output) {
			case Form.INPUT:
				return "ToString[InputForm[" + str + "]]";
			case Form.INPUTREPLACEGRAPHICS: 
				return "ToString[InputForm[ReplaceAll[{ Graphics[A___] :> Block[{plot}, plot = Graphics[A]; Export[\"tmp/\" <> IntegerString[Hash[ToString[InputForm[plot], CharacterEncoding->\"UTF8\"], \"SHA256\"], 16, 64] <> \".svg\", plot]; plot]," + 
				"Graphics3D[A___] :> Block[{plot}, plot = Graphics3D[A]; Export[\"tmp/\" <> IntegerString[Hash[ToString[InputForm[plot]], \"SHA256\"], 16, 64] <> \".svg\", plot]; plot] }]["+ str + "]]]";
			case Form.RENDERED:
				return "Function[{arg}, Export[\"tmp/\" <> IntegerString[Hash[ToString[InputForm[arg], CharacterEncoding->\"UTF8\"], \"SHA256\"], 16, 64] <> \".svg\", ToString[StandardForm[Style[arg, FontColor->RGBColor["
					+ Parameter.font_color.red.to_string() + ", " + Parameter.font_color.green.to_string() + ", " + Parameter.font_color.blue.to_string() + ", " + Parameter.font_color.alpha.to_string()
					+ "]]]]]; ToString[InputForm[arg]]][" + str + "]";
		}

		return "ToString[InputForm[" + str + "]]";
	}

	static int find_closing_bracket(string str, int start = 0) {
		
		if(start < 0 || start >= str.length)
			return -1;

		int brack_count = 0;
		int pos = start;
		int pos_open = str.index_of("[", start);
		int pos_close = str.index_of("]", start);
		int pos_string = str.index_of("\"", start);
			
		
		do {

			if(pos_string > 0 && (pos_string < pos_close || pos_close < 0) && (pos_string < pos_open || pos_open < 0)) {
				
				if(pos >= str.length-1)
					return -1;

				pos = str.index_of("\"", pos+1);
				
				if(pos < 0 || pos+1 >= str.length-1)
					return -1;

				pos_open = str.index_of("[", pos+1);
				pos_close = str.index_of("]", pos+1);
				pos_string = str.index_of("\"", pos+1);

				continue;
			}


			if( (pos_close < pos_open || pos_open < 0) && pos_close >= 0)  {
				brack_count--;
				pos = pos_close;
				pos_close = str.index_of("]", pos+1);
				continue;
			}

			if( (pos_open < pos_close || pos_close < 0) && pos_open >= 0) {
				brack_count++;
				pos = pos_open;
				pos_open = str.index_of("[", pos+1);
				continue;
			}

			break;

		} while(brack_count != 0 && pos < str.length - 1);

		return (brack_count == 0) ? pos : -1;
	}

	static int character_index_at_byte_index(string str, int byte_idx) {

		if(byte_idx > str.length-1)
			return -1;

		if(! str.valid_char(byte_idx))
			return -1;

		int char_idx = (byte_idx >= str.char_count()) ? str.char_count()-1 : byte_idx;
		int current_idx;

		while(char_idx >= 0 && char_idx < str.char_count()) {
			
			current_idx = str.index_of_nth_char(char_idx);

			if(current_idx == byte_idx)
				return char_idx;

			if(current_idx < byte_idx)
				return -1;

			char_idx--;

		}

		return -1;

	}

	public enum SearchType {
		StartForwards,
		EndBackwards,
		CursorForwards,
		CursorBackwards
	}
}