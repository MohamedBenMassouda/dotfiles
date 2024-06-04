chosen=$(echo "Play/Pause\nNext\nPrevious" | rofi -dmenu -p "PlayerCtl")

case $chosen in
    Play/Pause)
        playerctl play-pause
        ;;
    Next)
        playerctl next
        ;;
    Previous)
        playerctl previous
        ;;
esac
