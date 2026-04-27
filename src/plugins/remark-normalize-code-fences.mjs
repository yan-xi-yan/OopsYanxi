import { visit } from "unist-util-visit";

const LANGUAGE_ALIASES = {
	dotenv: "bash",
	env: "bash",
	git: "bash",
	gitignore: "txt",
	py: "python",
	sh: "bash",
	shell: "bash",
	shellscript: "bash",
	zsh: "bash",
};

export function remarkNormalizeCodeFences() {
	return (tree) => {
		visit(tree, "code", (node) => {
			if (!node.lang || typeof node.lang !== "string") {
				return;
			}

			const normalized = node.lang.trim().toLowerCase();
			node.lang = LANGUAGE_ALIASES[normalized] ?? normalized;
		});
	};
}
