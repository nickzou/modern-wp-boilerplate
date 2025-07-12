import { URLInput as WPURLInput } from "@wordpress/block-editor";
import type { ComponentProps } from "react";

const URLInput = (props: ComponentProps<typeof WPURLInput>) => {
	return (
		<WPURLInput
			{...props}
			className="ad:[&_input]:!border-2 ad:[&_input]:!border-gray-300 ad:[&_input]:!border-solid ad:[&_input]:!p-2 ad::[&_input]:!rounded ad::[&_input]:!w-full"
		/>
	);
};

export default URLInput;
