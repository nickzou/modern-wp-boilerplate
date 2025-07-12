import type { ComponentProps } from "react";
import { twMerge } from "tailwind-merge";

const Button = ({
	className,
	children,
	...props
}: ComponentProps<"button">) => {
	return (
		<button
			{...props}
			className={twMerge(
				"ad:disabled:text-gray-200 ad:disabled:border-gray-200 ad:disabled:cursor-not-allowed ad:rounded ad:cursor-pointer ad:border ad:border-solid ad:border-blue-500 ad:text-blue-500 ad:bg-white/70 ad:py-2 ad:px-3",
				className,
			)}
		>
			{children}
		</button>
	);
};

export default Button;
