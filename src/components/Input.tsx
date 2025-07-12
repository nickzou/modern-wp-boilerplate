import type { ComponentProps } from "react";

const Input = (props: ComponentProps<"input">) => {
	return (
		<input
			{...props}
			className="ad:border-2 ad:border-gray-300 ad:border-solid ad:p-2 ad:rounded ad:w-full"
		/>
	);
};

export default Input;
