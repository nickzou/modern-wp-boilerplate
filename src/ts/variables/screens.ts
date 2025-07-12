export type Names = "base" | "sm" | "md" | "lg" | "xl" | "2xl";

export type Screen = {
	name: Names;
	value: number;
};

const screens: Screen[] = [
	{ name: "base", value: 0 },
	{ name: "sm", value: 640 },
	{ name: "md", value: 768 },
	{ name: "lg", value: 1024 },
	{ name: "xl", value: 1280 },
	{ name: "2xl", value: 1536 },
];
export default screens;
