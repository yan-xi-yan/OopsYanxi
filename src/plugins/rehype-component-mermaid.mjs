import { h } from "hastscript";

export function MermaidComponent(properties, children) {
	if (Array.isArray(children) && children.length !== 0) {
		return h("div", { class: "hidden" }, [
			'Invalid directive. ("mermaid" directive must be leaf type and does not accept children)',
		]);
	}

	if (typeof properties?.source !== "string" || properties.source.length === 0) {
		return h(
			"div",
			{ class: "hidden" },
			'Invalid directive. ("mermaid" directive requires a non-empty "source" attribute)',
		);
	}

	return h(
		"div",
		{ class: "mermaid-diagram not-prose", "data-mermaid-source": properties.source },
		[h("div", { class: "mermaid-diagram__viewport" }, [h("div", { class: "mermaid-diagram__canvas" })])],
	);
}
