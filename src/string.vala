namespace Seaborg {

	static bool check_input_packet(string _str) {
		
		string str = _str.replace(" ", "").replace("\n", "");
		
		if(str == "") return false;
		if(str.replace("[","").length != str.replace("]","").length) return false;
		if(str.replace("(","").length != str.replace(")","").length) return false;
		if(str.replace("{","").length != str.replace("}","").length) return false;
		
		return true;
	}

	static string replace_characters(string _str) {
		string str = _str

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

			

		return str;
	}

	static string make_file_name(string str) {
		return str;
	}

}