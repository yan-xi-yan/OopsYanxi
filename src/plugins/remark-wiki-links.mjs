import fs from "node:fs";
import path from "node:path";

const CONTENT_ROOT = path.resolve(process.cwd(), "src/content/posts");
const MARKDOWN_FILE_RE = /\.md$/i;
const WIKI_LINK_RE = /\[\[([^[\]]+?)\]\]/g;
const BLOCK_ID_RE = /^\^([A-Za-z0-9_-]+)$/;

let cachedIndex = null;

function toPosixPath(value) {
	return value.replaceAll("\\", "/");
}

function normalizePath(value) {
	return path.posix.normalize(toPosixPath(value));
}

function normalizeLookupKey(value) {
	return value
		.normalize("NFKC")
		.toLowerCase()
		.replace(MARKDOWN_FILE_RE, "")
		.replace(/[\s_-]+/g, "")
		.replace(/[()[\]{}"'`“”‘’<>《》【】,，.。:：;；!?！？/\\|]/g, "");
}

function slugifyHeading(value) {
	return value
		.normalize("NFKC")
		.toLowerCase()
		.trim()
		.replace(/[()[\]{}"'`“”‘’<>《》【】,，.。:：;；!?！？/\\|]/g, "")
		.replace(/\s+/g, "-")
		.replace(/-+/g, "-")
		.replace(/^-|-$/g, "");
}

function extractFileMetadata(filePath) {
	const raw = fs.readFileSync(filePath, "utf8");
	const frontmatterMatch = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/);
	const frontmatter = frontmatterMatch?.[1] ?? "";
	const titleMatch = frontmatter.match(/^title:\s*(.+)$/m);
	const body = raw.slice(frontmatterMatch?.[0]?.length ?? 0);

	const headings = new Map();
	const blockIds = new Set();

	let inFence = false;
	for (const line of body.split(/\r?\n/)) {
		if (/^```/.test(line)) {
			inFence = !inFence;
			continue;
		}
		if (inFence) {
			continue;
		}

		const blockIdMatch = line.trim().match(BLOCK_ID_RE);
		if (blockIdMatch) {
			blockIds.add(blockIdMatch[1]);
			continue;
		}

		const headingMatch = line.match(/^(#{1,6})\s+(.+?)\s*$/);
		if (!headingMatch) {
			continue;
		}

		const headingText = headingMatch[2].replace(/\s+#+\s*$/, "").trim();
		const normalizedHeading = normalizeLookupKey(headingText);
		if (!normalizedHeading) {
			continue;
		}

		headings.set(normalizedHeading, slugifyHeading(headingText));
	}

	return {
		title: titleMatch?.[1]?.trim() ?? "",
		headings,
		blockIds,
	};
}

function getWikiLinkIndex() {
	if (cachedIndex) {
		return cachedIndex;
	}

	const entries = [];
	const lookup = new Map();
	const stack = [CONTENT_ROOT];

	while (stack.length > 0) {
		const currentDir = stack.pop();
		for (const dirent of fs.readdirSync(currentDir, { withFileTypes: true })) {
			const absolutePath = path.join(currentDir, dirent.name);
			if (dirent.isDirectory()) {
				stack.push(absolutePath);
				continue;
			}
			if (!dirent.isFile() || !MARKDOWN_FILE_RE.test(dirent.name)) {
				continue;
			}

			const relativePath = normalizePath(path.relative(process.cwd(), absolutePath));
			const basename = path.basename(dirent.name, ".md");
			const metadata = extractFileMetadata(absolutePath);
			const entry = {
				path: relativePath,
				basename,
				title: metadata.title,
				headings: metadata.headings,
				blockIds: metadata.blockIds,
			};

			entries.push(entry);

			for (const key of [basename, metadata.title]) {
				const normalizedKey = normalizeLookupKey(key);
				if (!normalizedKey) {
					continue;
				}
				if (!lookup.has(normalizedKey)) {
					lookup.set(normalizedKey, []);
				}
				lookup.get(normalizedKey).push(entry);
			}
		}
	}

	cachedIndex = { entries, lookup };
	return cachedIndex;
}

function scoreCandidate(sourceDir, candidatePath) {
	const relativePath = normalizePath(path.posix.relative(sourceDir, candidatePath));
	const segments = relativePath.split("/");
	const parentHops = segments.filter((segment) => segment === "..").length;
	return parentHops * 1000 + relativePath.length;
}

function pickBestCandidate(sourcePath, candidates) {
	if (!sourcePath || candidates.length <= 1) {
		return candidates[0] ?? null;
	}

	const sourceDir = path.posix.dirname(sourcePath);
	return [...candidates].sort((left, right) => {
		return scoreCandidate(sourceDir, left.path) - scoreCandidate(sourceDir, right.path);
	})[0] ?? null;
}

function toRelativeMarkdownHref(sourcePath, targetPath, anchor) {
	const sourceDir = path.posix.dirname(sourcePath);
	let relativePath = normalizePath(path.posix.relative(sourceDir, targetPath));
	if (!relativePath.startsWith(".")) {
		relativePath = `./${relativePath}`;
	}
	if (!anchor) {
		return relativePath;
	}
	return `${relativePath}#${anchor}`;
}

function resolveWikiHref(sourcePath, rawTarget) {
	if (!sourcePath) {
		return null;
	}

	const [targetWithoutAlias, rawAlias] = rawTarget.split("|");
	const [rawPageTarget, rawAnchor] = targetWithoutAlias.split("#");
	const pageTarget = rawPageTarget.trim();
	const alias = rawAlias?.trim() || "";
	const normalizedTarget = normalizeLookupKey(pageTarget);
	if (!normalizedTarget) {
		return null;
	}

	const { lookup } = getWikiLinkIndex();
	const candidates = lookup.get(normalizedTarget) ?? [];
	const matchedEntry = pickBestCandidate(sourcePath, candidates);
	if (!matchedEntry) {
		return null;
	}

	let anchor = "";
	if (rawAnchor) {
		const trimmedAnchor = rawAnchor.trim();
		if (trimmedAnchor.startsWith("^")) {
			const blockId = trimmedAnchor.slice(1);
			if (matchedEntry.blockIds.has(blockId)) {
				anchor = `^${blockId}`;
			}
		} else {
			const matchedHeading = matchedEntry.headings.get(normalizeLookupKey(trimmedAnchor));
			anchor = matchedHeading || slugifyHeading(trimmedAnchor);
		}
	}

	const href = toRelativeMarkdownHref(sourcePath, matchedEntry.path, anchor);
	const label = alias || pageTarget;
	return { href, label };
}

function transformWikiLinks(children, sourcePath) {
	for (let childIndex = 0; childIndex < children.length; childIndex += 1) {
		const child = children[childIndex];
		if (!child || typeof child !== "object") {
			continue;
		}

		if (child.type === "paragraph") {
			if (
				child.children?.length === 1 &&
				child.children[0]?.type === "text"
			) {
				const blockIdMatch = child.children[0].value.trim().match(BLOCK_ID_RE);
				if (blockIdMatch) {
					children.splice(childIndex, 1, {
						type: "html",
						value: `<span id="^${blockIdMatch[1]}" data-block-ref-anchor="true"></span>`,
					});
					continue;
				}
			}
		}

		if (child.type === "text") {
			const text = child.value;
			if (!text || !text.includes("[[")) {
				continue;
			}

			const nextChildren = [];
			let lastIndex = 0;
			WIKI_LINK_RE.lastIndex = 0;

			for (const match of text.matchAll(WIKI_LINK_RE)) {
				const [fullMatch, rawTarget] = match;
				const matchIndex = match.index ?? 0;
				if (matchIndex > lastIndex) {
					nextChildren.push({
						type: "text",
						value: text.slice(lastIndex, matchIndex),
					});
				}

				const resolvedLink = resolveWikiHref(sourcePath, rawTarget);
				if (!resolvedLink) {
					nextChildren.push({
						type: "text",
						value: fullMatch,
					});
				} else {
					nextChildren.push({
						type: "link",
						url: resolvedLink.href,
						children: [
							{
								type: "text",
								value: resolvedLink.label,
							},
						],
					});
				}

				lastIndex = matchIndex + fullMatch.length;
			}

			if (lastIndex < text.length) {
				nextChildren.push({
					type: "text",
					value: text.slice(lastIndex),
				});
			}

			if (nextChildren.length > 0) {
				children.splice(childIndex, 1, ...nextChildren);
				childIndex += nextChildren.length - 1;
			}
			continue;
		}

		if (child.children && !["code", "inlineCode", "link", "definition", "html"].includes(child.type)) {
			transformWikiLinks(child.children, sourcePath);
		}
	}
}

export function remarkWikiLinks() {
	return (tree, file) => {
		const sourcePath = file?.path
			? normalizePath(path.relative(process.cwd(), file.path))
			: null;

		if (!sourcePath || !Array.isArray(tree.children)) {
			return;
		}

		transformWikiLinks(tree.children, sourcePath);
	};
}
