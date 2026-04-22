import { visit } from "unist-util-visit";

const OBSIDIAN_CALLOUT_PATTERN = /^\[!([a-z0-9_-]+)\]([+-])?(?:\s+(.*))?$/i;

const CALLOUT_TYPE_MAP = {
	abstract: "note",
	attention: "warning",
	bug: "caution",
	caution: "caution",
	check: "tip",
	danger: "caution",
	done: "tip",
	error: "caution",
	example: "important",
	fail: "caution",
	failure: "caution",
	faq: "important",
	help: "important",
	hint: "tip",
	important: "important",
	info: "note",
	missing: "caution",
	note: "note",
	question: "important",
	quote: "note",
	success: "tip",
	summary: "note",
	tip: "tip",
	tldr: "note",
	todo: "important",
	warning: "warning",
};

function collectText(node) {
	if (!node || typeof node !== "object") {
		return "";
	}

	if (node.type === "text" || node.type === "inlineCode") {
		return node.value ?? "";
	}

	if (Array.isArray(node.children)) {
		return node.children.map((child) => collectText(child)).join("");
	}

	return "";
}

function createTextParagraph(value, directiveLabel = false) {
	return {
		type: "paragraph",
		children: [{ type: "text", value }],
		data: directiveLabel ? { directiveLabel: true } : {},
	};
}

export function remarkObsidianCallouts() {
	return (tree) => {
		visit(tree, "blockquote", (node) => {
			if (!Array.isArray(node.children) || node.children.length === 0) {
				return;
			}

			const firstParagraph = node.children[0];
			if (!firstParagraph || firstParagraph.type !== "paragraph") {
				return;
			}

			const paragraphText = collectText(firstParagraph);
			const [firstLine = ""] = paragraphText.split(/\r?\n/, 1);
			const matched = firstLine.trim().match(OBSIDIAN_CALLOUT_PATTERN);
			if (!matched) {
				return;
			}

			const rawType = matched[1].toLowerCase();
			const mappedType = CALLOUT_TYPE_MAP[rawType] ?? "note";
			const foldMarker = matched[2] ?? null;
			const title = matched[3]?.trim() ?? "";
			const remainingText = paragraphText.slice(firstLine.length).replace(/^\r?\n/, "");
			const contentChildren = [];

			if (remainingText) {
				contentChildren.push(createTextParagraph(remainingText));
			}

			for (const child of node.children.slice(1)) {
				contentChildren.push(child);
			}

			if (title) {
				contentChildren.unshift(createTextParagraph(title, true));
			}

			node.type = "containerDirective";
			node.name = mappedType;
			node.attributes = {};
			node.children = contentChildren;
			delete node.value;

			if (foldMarker) {
				node.attributes.fold = foldMarker;
			}
		});
	};
}
