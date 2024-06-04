ouputDir="~/Pictures/Screenshots/"


screenshotWithSave() {
		hyprshot -m region -f "Screenshot-$(date '+%d-%b_%H-%M-%S').png" -o $outputDir
}

screenshotToClipboard() {
		hyprshot -m region -f "Screenshot-$(date '+%d-%b_%H-%M-%S').png" -o $outputDir --clipboard-only
}

if [[ "$1" == "--clipboard" ]]; then
	screenshotToClipboard
else
	screenshotWithSave
fi
