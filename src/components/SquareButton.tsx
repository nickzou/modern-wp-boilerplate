import type { ComponentProps } from "react";
import { twMerge } from "tailwind-merge";

const SquareButton = ({
	className,
	children,
	...props
}: ComponentProps<"button">) => {
	return (
		<button
			{...props}
			className={twMerge(
				"ad:aspect-square ad:disabled:hover:bg-transparent ad:disabled:text-gray-200 ad:disabled:border-gray-200 ad:disabled:cursor-not-allowed ad:flex ad:justify-center ad:hover:bg-gray-200 ad:transition-[hover] ad:cursor-pointer ad:duration-100 ad:items-center ad:w-8 ad:border ad:border-solid ad:border-gray-300 ad:rounded ad:text-black",
				className,
			)}
		>
			{children}
		</button>
	);
};

export default SquareButton;
