SeaborgNotebookImport[in_String] := (
	If[NotebookImport[in, _ -> "HeldInterpretedCell", "FlattenCellGroups" -> False] === $Failed, Return["$Failed"]];
	"<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
	"<notebook version=\"1.0\">" <> (
		NotebookImport[in, _ -> "HeldInterpretedCell", "FlattenCellGroups" -> False] //. {
			HoldComplete[TextCell[A_, B_, ___]] :> TextCell[A, B],
			ExpressionCell[A_, B_, ___] :> ExpressionCell[A,B],
			{TextCell[A_String, "Title"], B___} :> SeaborgCellContainer[A, 6, {B}],
			{TextCell[A_String, "Chapter"], B___} :> SeaborgCellContainer[A, 5, {B}],
			{TextCell[A_String, "Subchapter"], B___} :> SeaborgCellContainer[A, 4, {B}],
			{TextCell[A_String, "Section"], B___} :> SeaborgCellContainer[A, 3, {B}],
			{TextCell[A_String, "Subsection"], B___} :> SeaborgCellContainer[A, 2, {B}],
			{TextCell[A_String, "Subsubsection"], B___} :> SeaborgCellContainer[A, 1, {B}],
			TextCell[A_String, "Text"] :> SeaborgTextCell[A],
			{A___, HoldComplete[ExpressionCell[Null, "Input"]], B___} :> {A, B},
			{A___, HoldComplete[ExpressionCell[{a___, Null, b___}, "Input"]], B___} :> {A, HoldComplete[ExpressionCell[{a, b}, "Input"]], B},
			HoldComplete[ExpressionCell[A_, "Input"]] :> SeaborgEvaluationCell[ToString[HoldForm[InputForm[A]]], {}], 
			HoldComplete[ExpressionCell[A_, "Code"]] :> SeaborgEvaluationCell[ToString[HoldForm[InputForm[A]]], {}],
			{SeaborgEvaluationCell[A_, {B___}], {HoldComplete[ExpressionCell[C_, "Print"]], D___}} :> {SeaborgEvaluationCell[A, {B, ToString[HoldForm[InputForm[C]]]}], D},
			{SeaborgEvaluationCell[A_, {B___}], {HoldComplete[ExpressionCell[C_, "Output"]], D___}} :> {SeaborgEvaluationCell[A, {B, ToString[HoldForm[InputForm[C]]]}], D},
			{SeaborgEvaluationCell[A_, {B___}], HoldComplete[ExpressionCell[C_, "Print"]], D___} :> {SeaborgEvaluationCell[A, {B, ToString[HoldForm[InputForm[C]]]}], D},
			{SeaborgEvaluationCell[A_, {B___}], HoldComplete[ExpressionCell[C_, "Output"]], D___} :> {SeaborgEvaluationCell[A, {B, ToString[HoldForm[InputForm[C]]]}], D},
			{SeaborgEvaluationCell[A_, {B___}], HoldComplete[ExpressionCell[MessageTemplate[C_, D_, E___], "Message"]], F___} :> {SeaborgEvaluationCell[A, {B, ToString[C]<>"::"<>ToString[D]}], F},
			{A___, {SeaborgEvaluationCell[B___]}, C___} :> {A, SeaborgEvaluationCell[B], C}
		} //. {
			{A___, HoldComplete[B___], C___} :> {A,C},
			{A___, {SeaborgEvaluationCell[B___]}, C___} :> {A, SeaborgEvaluationCell[B], C}
		} //. {
			SeaborgTextCell[A_] :> (
				"<cell type=\"text\"><level>0</level><content>" <> 
				StringReplace[A, {"\n" -> "$NEWLINE", "<" -> "$BRA", ">" -> "$KET", "&" -> "$AMPERSAND"}] <>
				"</content><results></results><children></children></cell>"
			),
			SeaborgEvaluationCell[A_, {B___}] :> (
				"<cell type=\"evaluation\"><level>0</level><content>" <> 
				StringReplace[A, {"\n" -> "$NEWLINE", "<" -> "$BRA", ">" -> "$KET", "&" -> "$AMPERSAND"}] <>
				"</content><results>" <>
				StringJoin @@ (("<result type=\"text\">" <> StringReplace[#, {"\n" -> "$NEWLINE", "<" -> "$BRA", ">" -> "$KET", "&" -> "$AMPERSAND"}] <> "</result>")& /@ {B}) <> 
				"</results><children></children></cell>"
			)
		} //. {
			SeaborgCellContainer[A_, B_, {C___}] :> (
				{"<cell type=\"container\"><level>"<> ToString[B] <>"</level><content>" <> 
				StringReplace[A, {"\n" -> "$NEWLINE", "<" -> "$BRA", ">" -> "$KET", "&" -> "$AMPERSAND"}] <>
				"</content><results></results><children>", C , "</children></cell>"}
			)
		} //. {
			List -> StringJoin
		}
	) <> 
	"</notebook>"
);