import type { ReactNode } from "react";

type Props = {
	name: string;
	children: ReactNode;
};
const BlockWrapper = ({ name, children }: Props) => {
	return (
		<div className="ad:gap-y-3 ad:flex ad:p-3 ad:flex-col ad:justify-center ad:items-center">
			<div className="ad:border-b ad:border-solid ad:border-gray-300 ad:pb-3 ad:md:max-w-[275px] ad:text-center ad:text-sm ad:text-gray-300 ad:w-1/2 ad:px-5 ad:tracking-wider ad:uppercase">
				{name}
			</div>
			<div className="ad:w-full">{children}</div>
		</div>
	);
};

export default BlockWrapper;
