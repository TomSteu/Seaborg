SeaborgNotebookImport[in_String] := Block[
	{SeaborgCellContainer, SeaborgTextCell, SeaborgEvaluationCell, SeaborgResultCell},
	If[Import[in] === $Failed, Return["$Failed"];];
	Return[
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
		"<notebook version=\"1.0\">" <> ToString[
			Import[in] /. {
				Notebook[A_List, B___] :> A,
				 BoxData[A___] :> StripBoxes[A]
				} //. {
					Cell[A_, B___, f_[C___], D___] :> Cell[A, B, D] /; (f === Rule),
					BoxData[A___] :> MakeExpression[A, StandardForm],
					Cell[HoldComplete[MessageTemplate[A_, B_, C___]], D___] :> 
 					Cell[ToString[A] <> "::" <> ToString[B], "Output"],
 					{A___, ErrorBox[B___], C___} :> {A, C},
					HoldComplete[A_] :> ToString[HoldForm[InputForm[A]]]
				} //. {
					TextData[{A___, B_String, C_String, D___}] :> TextData[{A, B <> C, D}],
					TextData[{A___, Cell[B_String, C___], D___}] :> TextData[{A, B, D}],
					TextData[{A___, Cell[B_, C___], D___}] :> 
					TextData[{A,  ToString[HoldForm[InputForm[B]]], D}],
					TextData[{A___, B_, C___}] :> TextData[{A, C}] /; ! StringQ[B],
					TextData[{A___}] :> StringJoin[A],
					OutputFormData[A_, B_] :> A,
					RawData[A_] :> A /; StringQ[A],
					RawData[A_] :>  ToString[HoldForm[InputForm[A]]],
					{A___, Cell[B___, GraphicsData[C___], D___], E___} :> {A, E},
					{A___, Cell[B___, StyleData[C___], D___], E___} :> {A, E},
					HoldComplete[A_] :> ToString[HoldForm[InputForm[A]]],
					{A___, Cell[B___, CellGroupData[{C___}, D___], E___], F___} :> {A, {C}, F},
					{D___, Cell[A_], E___} :> {D, Cell[A, "Text"], E},
					Cell[{A___, B_String, C_String, D___}, E___] :> 
					Cell[{A, B <> ", " <> C, D}, E],
					Cell[{A_String}, B___] :> Cell["{" <> A <> "}", B]
				} //. {
					{Cell[A_, "Title"], B___} :> {SeaborgCellContainer[A, 6, {B}]},
					{Cell[A_, "Chapter"], B___} :> {SeaborgCellContainer[A, 5, {B}]},
					{Cell[A_, "Subchapter"], B___} :> {SeaborgCellContainer[A, 4, {B}]},
					{Cell[A_, "Section"], B___} :> {SeaborgCellContainer[A, 3, {B}]},
					{Cell[A_, "Subsection"], B___} :> {SeaborgCellContainer[A, 2, {B}]},
					{Cell[A_, "Subsubsection"], B___} :> {SeaborgCellContainer[A, 1, {B}]},
					Cell[A_, "Text"] :> SeaborgTextCell[A],
					Cell[A_, "Input"] :> SeaborgEvaluationCell[A, {}],
					Cell[A_, "Code"] :> SeaborgEvaluationCell[A, {}],
					Cell[A_, "Output"] :> SeaborgResultCell[A],
					Cell[A_, "Print"] :> SeaborgResultCell[A],
					Cell[A_String, B___] :> SeaborgTextCell[A],
					Cell[A_, B___] :> SeaborgTextCell[ToString[HoldForm[InputForm[A]]]]
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