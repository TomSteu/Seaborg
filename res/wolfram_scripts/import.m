SeaborgNotebookImport[in_String] := Block[
	{SeaborgCellContainer, SeaborgContainerCell, SeaborgTextCell, SeaborgEvaluationCell, SeaborgResultCell, Recombine},
	If[Import[in] === $Failed, Return["$Failed"];];	
	If[Length[SyntaxInformation[NotebookImport]] == 0, Return["$Failed"];];	
	Recombine[parts_List] := Block[
		{},
		If[parts === {}, Return[Nothing];];
		If[And @@ (MatchQ[#, {}]& /@ parts), Return[{}];];
		Return[Join[
			Flatten[Function[x, TakeWhile[x, (! ListQ[#])& ]] /@ parts],
			{Recombine[Function[x, SelectFirst[x, ListQ, {}]] /@ parts]},
			Recombine[Function[x, If[FirstPosition[x, _List, {Length[x]}, 1][[1]] < Length[x], x[[FirstPosition[x, _List, {Length[x]}, 1][[1]] + 1 ;;]], {}]] /@ parts]
		] //. {a___, {}, b___} :> {a,b}];
	];
	Return[
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>	
		"<notebook version=\"1.0\">" <> ToString[
		Recombine[{
				UsingFrontEnd[NotebookImport[in, "Title" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgContainerCell[s, 6]],
				UsingFrontEnd[NotebookImport[in, "Chapter" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgContainerCell[s, 5]],
				UsingFrontEnd[NotebookImport[in, "Subchapter" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgContainerCell[s, 4]],
				UsingFrontEnd[NotebookImport[in, "Section" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgContainerCell[s, 3]],
				UsingFrontEnd[NotebookImport[in, "Subsection" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgContainerCell[s, 2]],
				UsingFrontEnd[NotebookImport[in, "Subsubsection" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgContainerCell[s, 1]],
				UsingFrontEnd[NotebookImport[in, "Text" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgTextCell[s]],
				UsingFrontEnd[NotebookImport[in, "Code" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgEvaluationCell[s, {}]],	
				UsingFrontEnd[NotebookImport[in, "Input" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgEvaluationCell[s, {}]],
				UsingFrontEnd[NotebookImport[in, "Message" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgResultCell[s]],
				UsingFrontEnd[NotebookImport[in, "Print" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgResultCell[s]],
				UsingFrontEnd[NotebookImport[in, "Output" -> "Text", "FlattenCellGroups" -> False] /. s_String :> SeaborgResultCell[s]]
			}] //. {
				{SeaborgContainerCell[s_, l_], c___} :> SeaborgCellContainer[s, l, {c}],
				{SeaborgEvaluationCell[s_, {c___}], SeaborgResultCell[t_], r___} :> {SeaborgEvaluationCell[s, {c, t}], r}
			} //. {	
				SeaborgResultCell[s_] :> SeaborgTextCell[s],
				SeaborgContainerCell[s_, l_] :> SeaborgCellContainer[s, l, {}]
			} //. {
				{a___, {b___}, c___} :> {a, b, c}
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