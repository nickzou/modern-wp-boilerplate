import { MediaUpload, MediaUploadCheck } from "@wordpress/block-editor";
import type MediaUploadObject from "../types/blocks/MediaUploadObject";
import Button from "./Button";

type Props = {
	hasImage: boolean;
	handleSelect: (image: MediaUploadObject) => void;
	handleRemove: () => void;
	image: Partial<MediaUploadObject>;
};
const ImageSelector = ({
	hasImage,
	handleSelect,
	image,
	handleRemove,
}: Props) => {
	return (
		<div className="ad:aspect-square ad:min-h-64 ad:lg:aspect-auto ad:lg:h-full ad:bg-gray-100 ad:overflow-hidden ad:relative ad:lg:pl-1.5 ad:rounded ad:flex ad:gap-x-2 ad:justify-center ad:items-center">
			{!hasImage && (
				<MediaUploadCheck>
					<MediaUpload
						allowedTypes={["image"]}
						onSelect={handleSelect}
						value={image.id}
						render={({ open }) => (
							<Button type="button" onClick={open} className="ad:z-[2]">
								Select image
							</Button>
						)}
					/>
				</MediaUploadCheck>
			)}
			{hasImage && (
				<>
					<MediaUploadCheck>
						<MediaUpload
							allowedTypes={["image"]}
							onSelect={handleSelect}
							value={image.id}
							render={({ open }) => (
								<Button type="button" onClick={open} className="ad:z-[2]">
									Replace image
								</Button>
							)}
						/>
					</MediaUploadCheck>
					<MediaUploadCheck>
						<button
							type="button"
							onClick={handleRemove}
							className="ad:rounded ad:cursor-pointer ad:z-[2] ad:cusror-pointer ad:border ad:border-solid ad:border-blue-500 ad:text-blue-500 ad:bg-white/70 ad:py-2 ad:px-3"
						>
							Remove image
						</button>
					</MediaUploadCheck>
				</>
			)}
			{hasImage && (
				<img
					src={image.url}
					alt={"Currently Selected"}
					className="ad:absolute ad:z-[0] ad:max-w-full ad:max-h-full"
				/>
			)}
		</div>
	);
};

export default ImageSelector;
