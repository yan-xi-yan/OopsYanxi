<script lang="ts">
	import { onMount } from "svelte";

	import I18nKey from "../i18n/i18nKey";
	import { i18n } from "../i18n/translation";
	import { getPostUrlBySlug } from "../utils/url-utils";

	export let tags: string[] = [];
	export let categories: string[] = [];
	export let sortedPosts: Post[] = [];
	export let indexPosts: Post[] = [];

	let uncategorized: string | null = null;
	let groups: Group[] = [];
	let filteredIndexPosts: Post[] = [];

	interface Post {
		slug: string;
		data: {
			title: string;
			description?: string;
			tags: string[];
			category?: string;
			series?: string;
			section?: string;
			kind?: string;
			order?: number;
			published: Date;
		};
	}

	interface Group {
		year: number;
		posts: Post[];
	}

	function formatDate(date: Date) {
		const month = (date.getMonth() + 1).toString().padStart(2, "0");
		const day = date.getDate().toString().padStart(2, "0");
		return `${month}-${day}`;
	}

	function formatTag(tagList: string[]) {
		return tagList.map((tag) => `#${tag}`).join(" ");
	}

	function filterPostsByCategories(posts: Post[], selectedCategories: string[]) {
		return posts.filter(
			(post) => post.data.category && selectedCategories.includes(post.data.category),
		);
	}

	function compareIndexPosts(a: Post, b: Post) {
		const categoryA = a.data.category ?? "";
		const categoryB = b.data.category ?? "";
		const categoryCompare = categoryA.localeCompare(categoryB, "zh-CN");
		if (categoryCompare !== 0) {
			return categoryCompare;
		}

		const seriesA = a.data.series ?? "";
		const seriesB = b.data.series ?? "";
		const seriesCompare = seriesA.localeCompare(seriesB, "zh-CN");
		if (seriesCompare !== 0) {
			return seriesCompare;
		}

		const orderA = a.data.order ?? 0;
		const orderB = b.data.order ?? 0;
		if (orderA !== orderB) {
			return orderA - orderB;
		}

		return a.data.title.localeCompare(b.data.title, "zh-CN");
	}

	function getIndexMeta(post: Post) {
		const parts = [];

		if (post.data.category) {
			parts.push(post.data.category);
		}

		if (post.data.series && post.data.series !== post.data.category) {
			parts.push(post.data.series);
		}

		return parts.join(" / ");
	}

	function getIndexSection(post: Post) {
		if (!post.data.section || post.data.section === post.data.title) {
			return "";
		}

		return post.data.section;
	}

	onMount(() => {
		const params = new URLSearchParams(window.location.search);
		tags = params.has("tag") ? params.getAll("tag") : [];
		categories = params.has("category") ? params.getAll("category") : [];
		uncategorized = params.get("uncategorized");

		let filteredPosts: Post[] = sortedPosts;
		let matchedIndexPosts: Post[] = categories.length > 0 ? indexPosts : [];

		if (tags.length > 0) {
			filteredPosts = filteredPosts.filter(
				(post) =>
					Array.isArray(post.data.tags) &&
					post.data.tags.some((tag) => tags.includes(tag)),
			);
		}

		if (categories.length > 0) {
			filteredPosts = filterPostsByCategories(filteredPosts, categories);
			matchedIndexPosts = filterPostsByCategories(matchedIndexPosts, categories);
		}

		if (uncategorized) {
			filteredPosts = filteredPosts.filter((post) => !post.data.category);
			matchedIndexPosts = [];
		}

		filteredIndexPosts = matchedIndexPosts.slice().sort(compareIndexPosts);

		const grouped = filteredPosts.reduce<Record<number, Post[]>>((acc, post) => {
			const year = post.data.published.getFullYear();
			if (!acc[year]) {
				acc[year] = [];
			}
			acc[year].push(post);
			return acc;
		}, {});

		groups = Object.keys(grouped)
			.map((yearStr) => ({
				year: Number.parseInt(yearStr, 10),
				posts: grouped[Number.parseInt(yearStr, 10)],
			}))
			.sort((a, b) => b.year - a.year);
	});
</script>

<div class="card-base px-8 py-6">
	{#if filteredIndexPosts.length > 0}
		<section class="mb-8">
			<div class="mb-4 flex items-end justify-between gap-4">
				<div>
					<div class="text-xs uppercase tracking-[0.2em] text-50">Index</div>
					<div class="text-xl font-bold text-90">索引文档</div>
				</div>
				<div class="text-sm text-50">{filteredIndexPosts.length}</div>
			</div>

			<div class="grid gap-4 md:grid-cols-2">
				{#each filteredIndexPosts as post}
					<a
						href={getPostUrlBySlug(post.slug)}
						aria-label={post.data.title}
						class="group block rounded-2xl border border-black/10 bg-[var(--btn-regular-bg)] p-5 transition hover:bg-[var(--btn-regular-bg-hover)] active:scale-[0.99] dark:border-white/10"
					>
						<div class="mb-2 text-xs uppercase tracking-[0.16em] text-50">
							{getIndexMeta(post) || "Knowledge Base"}
						</div>
						<div class="flex items-start justify-between gap-4">
							<div class="min-w-0">
								<div class="truncate text-lg font-bold text-90 transition group-hover:text-[var(--primary)]">
									{post.data.title}
								</div>
								{#if getIndexSection(post)}
									<div class="mt-1 text-sm text-50">{getIndexSection(post)}</div>
								{/if}
							</div>
							<div class="rounded-lg bg-[var(--card-bg)] px-2 py-1 text-xs font-semibold text-50">
								{String(post.data.order ?? 0).padStart(2, "0")}
							</div>
						</div>
						{#if post.data.description}
							<div class="mt-3 line-clamp-2 text-sm text-75">{post.data.description}</div>
						{/if}
					</a>
				{/each}
			</div>
		</section>
	{/if}

	{#each groups as group}
		<div>
			<div class="flex h-[3.75rem] w-full flex-row items-center">
				<div class="w-[15%] text-right text-2xl font-bold text-75 transition md:w-[10%]">
					{group.year}
				</div>
				<div class="w-[15%] md:w-[10%]">
					<div
						class="mx-auto h-3 w-3 rounded-full bg-none outline outline-3 outline-[var(--primary)] -outline-offset-[2px]"
					></div>
				</div>
				<div class="w-[70%] text-left text-50 transition md:w-[80%]">
					{group.posts.length} {i18n(group.posts.length === 1 ? I18nKey.postCount : I18nKey.postsCount)}
				</div>
			</div>

			{#each group.posts as post}
				<a
					href={getPostUrlBySlug(post.slug)}
					aria-label={post.data.title}
					class="group btn-plain !block h-10 w-full rounded-lg hover:text-[initial]"
				>
					<div class="flex h-full flex-row items-center justify-start">
						<div class="w-[15%] text-right text-sm text-50 transition md:w-[10%]">
							{formatDate(post.data.published)}
						</div>

						<div class="relative flex h-full w-[15%] items-center dash-line md:w-[10%]">
							<div
								class="mx-auto h-1 w-1 rounded bg-[oklch(0.5_0.05_var(--hue))] outline outline-4 outline-[var(--card-bg)] transition-all group-hover:h-5 group-hover:bg-[var(--primary)] group-hover:outline-[var(--btn-plain-bg-hover)] group-active:outline-[var(--btn-plain-bg-active)]"
							></div>
						</div>

						<div
							class="w-[70%] overflow-hidden text-ellipsis whitespace-nowrap pr-8 text-left font-bold text-75 transition-all group-hover:translate-x-1 group-hover:text-[var(--primary)] md:w-[65%] md:max-w-[65%]"
						>
							{post.data.title}
						</div>

						<div
							class="hidden overflow-hidden text-ellipsis whitespace-nowrap text-left text-sm text-30 transition md:block md:w-[15%]"
						>
							{formatTag(post.data.tags)}
						</div>
					</div>
				</a>
			{/each}
		</div>
	{/each}
</div>
