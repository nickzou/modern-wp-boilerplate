interface Metadata {
	apiVersion: number;
	name: string;
	title: string;
	category: string;
	icon?: string;
	description: string;
	keywords?: string[];
	version: string;
	textdomain: string;
	editorScript?: string;
	script?: string;
	viewScript?: string;
	editorStyle?: string;
	style?: string;
	//This is AI generated, I do not known if this is complete
	supports?: {
		align?: boolean | string[];
		alignWide?: boolean;
		anchor?: boolean;
		className?: boolean;
		color?: {
			background?: boolean;
			gradients?: boolean;
			text?: boolean;
		};
		customClassName?: boolean;
		html?: boolean;
		inserter?: boolean;
		multiple?: boolean;
		reusable?: boolean;
		spacing?: {
			margin?: boolean | string[];
			padding?: boolean | string[];
		};
		typography?: {
			fontSize?: boolean;
			lineHeight?: boolean;
		};
	};
	attributes?: Record<
		string,
		{
			type: string;
			source?: string;
			selector?: string;
			attribute?: string;
			default?:
				| string
				| number
				| boolean
				| null
				| undefined
				| Record<string, unknown>
				| unknown[];
			multiline?: string;
		}
	>;
	example?: {
		attributes?: Record<
			string,
			| string
			| number
			| boolean
			| null
			| undefined
			| Record<string, unknown>
			| unknown[]
		>;
		viewportWidth?: number;
	};
	parent?: string[];
	ancestor?: string[];
	providesContext?: Record<string, string>;
	usesContext?: string[];
	styles?: Array<{
		name: string;
		label: string;
		isDefault?: boolean;
	}>;
}

export default Metadata;
