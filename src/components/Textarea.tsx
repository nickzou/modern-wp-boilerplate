import type { ComponentProps } from "react";

const Textarea = (props: ComponentProps<"textarea">) => {
	return (
		<textarea
			{...props}
			className="ad:w-full ad:!border-2 ad:!border-gray-300 ad:border-solid ad:p-2 ad:rounded"
		/>
	);
};

export default Textarea;
