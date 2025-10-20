type MediaUploadObject = {
	id: number;
	title: string;
	filename: string;
	url: string;
	link: string;
	alt: string;
	author: string;
	description: string;
	caption: string;
	name: string;
	status: string;
	uploadedTo: number;
	date: string;
	modified: string;
	menuOrder: number;
	mime: string;
	type: string;
	subtype: string;
	icon: string;
	dateFormatted: string;
	nonces: {
		update: string;
		delete: string;
		edit: string;
	};
	editLink: string;
	meta: boolean | object;
	authorName: string;
	authorLink: string;
	uploadedToTitle: string;
	uploadedToLink: string;
	filesizeInBytes: number;
	filesizeHumanReadable: string;
	context: string;
	height: number;
	width: number;
	orientation: "landscape" | "portrait" | "square";
	sizes: {
		[sizeName: string]: {
			height: number;
			width: number;
			url: string;
			orientation: "landscape" | "portrait" | "square";
		};
	};
	compat: {
		item: string;
		meta: string;
	};
};

export default MediaUploadObject;
