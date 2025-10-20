const moveForward = <T>({ index, list }: { index: number; list: Array<T> }) => {
	if (list.length <= 0) {
		return list;
	}

	const newList = [...list];
	const currentItem = newList[index];
	const nextItem = newList[index + 1];

	if (currentItem !== undefined && nextItem !== undefined) {
		newList[index] = nextItem;
		newList[index + 1] = currentItem;
	}

	return newList;
};

export default moveForward;
