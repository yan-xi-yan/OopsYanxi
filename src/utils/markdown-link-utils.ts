import { getPostUrlBySlug } from "@utils/url-utils";
import path from "node:path";

type EntryWithSlugAndPath = {
	slug: string;
	filePath?: string;
};

const INTERNAL_MD_LINK_RE = /\.md(?:$|[?#])/i;
const EXTERNAL_LINK_RE = /^(?:[a-z][a-z\d+\-.]*:|\/\/|#)/i;

function toPosixPath(value: string) {
	return value.replaceAll("\\", "/");
}

export function normalizeContentFilePath(filePath: string) {
	return path.posix.normalize(toPosixPath(filePath));
}

function getParentDir(filePath: string) {
	const normalizedPath = normalizeContentFilePath(filePath);
	const lastSlashIndex = normalizedPath.lastIndexOf("/");
	if (lastSlashIndex === -1) {
		return "";
	}
	return normalizedPath.slice(0, lastSlashIndex + 1);
}

function escapeHtmlAttribute(value: string) {
	return value.replaceAll("&", "&amp;").replaceAll("\"", "&quot;");
}

export function buildMarkdownLinkMap(entries: EntryWithSlugAndPath[]) {
	return Object.fromEntries(
		entries.flatMap((entry) => {
			if (!entry.filePath) return [];
			return [[normalizeContentFilePath(entry.filePath), getPostUrlBySlug(entry.slug)]];
		}),
	);
}

export function resolveInternalMarkdownHref(
	href: string,
	sourcePath: string | null | undefined,
	linkMap: Record<string, string>,
) {
	if (!sourcePath || !INTERNAL_MD_LINK_RE.test(href) || EXTERNAL_LINK_RE.test(href)) {
		return null;
	}

	const baseUrl = new URL(`https://md.local/${getParentDir(sourcePath)}`);
	const resolvedUrl = new URL(href, baseUrl);
	const resolvedPath = normalizeContentFilePath(decodeURIComponent(resolvedUrl.pathname).replace(/^\/+/, ""));
	const targetUrl = linkMap[resolvedPath];

	if (!targetUrl) {
		return null;
	}

	return `${targetUrl}${resolvedUrl.search}${resolvedUrl.hash}`;
}

export function rewriteInternalMarkdownLinks(
	html: string,
	sourcePath: string | null | undefined,
	linkMap: Record<string, string>,
) {
	if (!html || !sourcePath) {
		return html;
	}

	return html.replace(/<a\b([^>]*?)\shref="([^"]+)"([^>]*)>/gi, (fullMatch, beforeHref, href, afterHref) => {
		const resolvedHref = resolveInternalMarkdownHref(href, sourcePath, linkMap);
		if (!resolvedHref) {
			return fullMatch;
		}

		return `<a${beforeHref} href="${escapeHtmlAttribute(resolvedHref)}"${afterHref}>`;
	});
}
