import { ComboboxControl } from "@wordpress/components";
import { store as coreDataStore } from "@wordpress/core-data";
import { useSelect } from "@wordpress/data";
import { useState } from "react";

type PostProps = {
	id: number;
	title: string;
};

const PostSelector = ({
	value,
	parentSetter,
}: {
	value?: PostProps;
	parentSetter: (e: PostProps) => void;
}) => {
	const [searchTerm, setSearchTerm] = useState("");
	const posts = useSelect(
		(select) => {
			return select(coreDataStore).getEntityRecords("postType", "post", {
				search: searchTerm,
				per_page: 10,
			});
		},
		[searchTerm],
	);
	const options = posts
		? posts.map((post) => ({
				//@ts-expect-error id exists
				value: post.id.toString(),
				//@ts-expect-error title.rendered exists
				label: post.title.rendered,
			}))
		: [];
	const handleChange = (e: string | null | undefined) => {
		const post = options
			.filter((p) => p.value === e)
			.map((p) => ({ id: Number(p.value), title: p.label as string }))[0];
		if (post) {
			parentSetter(post);
		}
	};
	return (
		<ComboboxControl
			label="Select a Post"
			value={value?.id.toString()}
			onChange={handleChange}
			options={options}
			onFilterValueChange={setSearchTerm}
		/>
	);
};

export default PostSelector;
