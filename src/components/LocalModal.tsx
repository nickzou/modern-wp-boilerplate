import type { ReactNode } from "react";
const LocalModal = ({ children }: { children: ReactNode }) => {
	return (
		<div className="ad:flex ad:flex-col ad:gap-y-2 ad:bg-white ad:shadow ad:absolute ad:w-full ad:top-1/2 ad:left-1/2 ad:-translate-x-1/2 ad:-translate-y-1/2 ad:z-10 ad:rounded ad:p-2">
			{children}
		</div>
	);
};

export default LocalModal;
