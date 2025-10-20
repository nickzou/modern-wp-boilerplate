import type { ComponentProps } from "react";

const CTAButton = ({ children, ...props }: ComponentProps<"button">) => {
	return (
		<button
			{...props}
			className={
				"ad:w-full ad:cursor-pointer ad:text-black ad:py-2 ad:px-4 ad:rounded ad:bg-gray-300 ad:text-center"
			}
		>
			{children}
		</button>
	);
};

export default CTAButton;
