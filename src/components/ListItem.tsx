import { Plus, X } from "lucide-react";
import Input from "./Input";
import SquareButton from "./SquareButton";

type BaseListItemProps = {
	value: string;
	placeholder?: string;
	onChange: (value: string) => void;
};

type EditProps = BaseListItemProps & {
	variant: "edit";
	onRemove: () => void;
};

type AddProps = BaseListItemProps & {
	variant: "add";
	onAdd: () => void;
	disabled?: boolean;
};

type ListItemProps = EditProps | AddProps;

const ListItem = (props: ListItemProps) => {
	const { value, placeholder = "Add a list item", onChange, variant } = props;

	return (
		<div className="ad:flex ad:justify-center ad:items-center ad:gap-x-1">
			<Input
				placeholder={placeholder}
				value={value}
				onChange={(e) => onChange(e.target.value)}
			/>
			<SquareButton
				className="ad:h-full"
				disabled={variant === "add" ? props.disabled : false}
				onClick={variant === "edit" ? props.onRemove : props.onAdd}
			>
				{props.variant === "edit" ? <X /> : <Plus />}
			</SquareButton>
		</div>
	);
};

export default ListItem;
