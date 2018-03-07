SeaborgNotebookImport[in_String] := Block[
	{SeaborgCell, SeaborgCellContainer, SeaborgTextCell, SeaborgEvaluationCell, SeaborgResultCell},
	If[NotebookImport[in, _ -> "HeldInterpretedCell", "FlattenCellGroups" -> False] === $Failed, Return["$Failed"]];
	Return[
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
		"<notebook version=\"1.0\">" <> ToString[
			NotebookImport[in, _ -> "HeldInterpretedCell", "FlattenCellGroups" -> False] //. {
				HoldComplete[C_[A_, B_, ___]] :> SeaborgCell[HoldComplete[A], B],
				{SeaborgCell[HoldComplete[A_], "Title"], B___} :> SeaborgCellContainer[ToString[A], 6, {B}],
				{SeaborgCell[HoldComplete[A_], "Chapter"], B___} :> SeaborgCellContainer[ToString[A], 5, {B}],
				{SeaborgCell[HoldComplete[A_], "Subchapter"], B___} :> SeaborgCellContainer[ToString[A], 4, {B}],
				{SeaborgCell[HoldComplete[A_], "Section"], B___} :> SeaborgCellContainer[ToString[A], 3, {B}],
				{SeaborgCell[HoldComplete[A_], "Subsection"], B___} :> SeaborgCellContainer[ToString[A], 2, {B}],
				{SeaborgCell[HoldComplete[A_], "Subsubsection"], B___} :> SeaborgCellContainer[ToString[A], 1, {B}],
				SeaborgCell[HoldComplete[A_], "Text"] :> SeaborgTextCell[ToString[A]],
				SeaborgCell[HoldComplete[A_], "Input"] :> SeaborgEvaluationCell[ToString[HoldForm[InputForm[A]]], {}], 
				SeaborgCell[HoldComplete[A_], "Code"] :> SeaborgEvaluationCell[ToString[HoldForm[InputForm[A]]], {}],
				SeaborgCell[HoldComplete[A_], "Output"] :> SeaborgResultCell[ToString[HoldForm[InputForm[A]]], {}],
				SeaborgCell[HoldComplete[A_], "Print"] :> SeaborgResultCell[ToString[HoldForm[InputForm[A]]], {}],
				SeaborgCell[HoldComplete[MessageTemplate[C_, D_, E___]], "Message"] :> SeaborgTextCell[ToString[C]<>"::"<>ToString[D]],
				SeaborgCell[HoldComplete[A_], B_] :> SeaborgTextCell[ToString[HoldForm[InputForm[A]]]]
			} //. {
				{A___,F_[E___], B___,{C___}, D___} :>{A, F[E], B, C, D} /; (F === SeaborgEvaluationCell || F === SeaborgResultCell || F === SeaborgTextCell || F === SeaborgCellContainer),
				{A___,{C___}, B___, F_[E___]  D___} :>{A, C, B, F[E], D} /; (F === SeaborgEvaluationCell || F === SeaborgResultCell || F === SeaborgTextCell || F === SeaborgCellContainer)
			} //. {
				{A___, B_[C___], D___, E_[F___], G___} :> {A, B[C], D, G} /; ((B === SeaborgEvaluationCell || B === SeaborgResultCell || B === SeaborgTextCell || B === SeaborgCellContainer) && ! (E === SeaborgEvaluationCell || E === SeaborgResultCell || E === SeaborgTextCell || E === SeaborgCellContainer)),
				{A___, E_[F___], D___, B_[C___] , G___} :> {A, D, B[C], G} /; ((B === SeaborgEvaluationCell || B === SeaborgResultCell || B === SeaborgTextCell || B === SeaborgCellContainer) && ! (E === SeaborgEvaluationCell || E === SeaborgResultCell || E === SeaborgTextCell || E === SeaborgCellContainer))
			} //. {
				{E___, SeaborgEvaluationCell[A_, {B___}], SeaborgResultCell[C___], D___} :> {E, SeaborgEvaluationCell[A, {B, C}], D}
			} //. {
				SeaborgResultCell[C___]:> {E, SeaborgTextCell[A, {B, C}], D}
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
		] <> 
		"</notebook>"
	];
];