<button
    @click="$store.mobileMenu.toggle()"
    x-cloak
    class="absolute top-1/2 right-0 flex h-12 w-12 -translate-y-1/2 flex-col items-center justify-center lg:hidden"
>
    <div class="relative h-6 w-6">
        <span
            class="absolute block h-0.5 w-6 transform bg-gray-800 transition-all duration-250"
            :class="$store.mobileMenu.open ? 'rotate-45 translate-y-2.5' : 'translate-y-1'"
        ></span>
        <span
            class="absolute top-2.5 block h-0.5 w-6 transform bg-gray-800 transition-all duration-250"
            :class="$store.mobileMenu.open ? 'opacity-0' : 'opacity-100'"
        ></span>
        <span
            class="absolute block h-0.5 w-6 transform bg-gray-800 transition-all duration-250"
            :class="$store.mobileMenu.open ? '-rotate-45 translate-y-2.5' : 'translate-y-4'"
        ></span>
    </div>
</button>
