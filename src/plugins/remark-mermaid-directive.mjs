import { visit } from "unist-util-visit";

export function remarkMermaidDirective() {
	return (tree) => {
		visit(tree, "code", (node, index, parent) => {
			if (
				index === undefined ||
				!parent ||
				!node.lang ||
				node.lang.trim().toLowerCase() !== "mermaid"
			) {
				return;
			}

			parent.children[index] = {
				type: "leafDirective",
				name: "mermaid",
				attributes: {
					source: node.value ?? "",
				},
				children: [],
			};
		});
	};
}
