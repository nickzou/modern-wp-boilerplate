const moveBackward = <T>({
	index,
	list,
}: {
	index: number;
	list: Array<T>;
}) => {
	if (index <= 0) {
		return list;
	}

	const newList = [...list];
	const currentItem = newList[index];
	const previousItem = newList[index - 1];

	if (currentItem !== undefined && previousItem !== undefined) {
		newList[index] = previousItem;
		newList[index - 1] = currentItem;
	}

	return newList;
};

export default moveBackward;
