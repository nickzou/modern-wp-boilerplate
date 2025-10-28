import screens, { type Screen } from "./variables/screens";

document.addEventListener("alpine:init", () => {
	window.Alpine.store("mobileMenu", {
		open: false,
		toggle() {
			this.open = !this.open;
		},
	} as {
		open: boolean;
		toggle(): () => void;
	});

	window.Alpine.store("screen", {
		size: screens.find((screen) => window.innerWidth < screen.value),
	} as { size: Screen });
});
