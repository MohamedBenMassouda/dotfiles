#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl

music_icon="$HOME/.config/swaync/icons/music.png"

# Play the next track
play_next() {
    playerctl next
    # show_music_notification
}

# Play the previous track
play_previous() {
    playerctl previous
    # show_music_notification
}

# Toggle play/pause
toggle_play_pause() {
    playerctl play-pause
    # show_music_notification
}

# Stop playback
stop_playback() {
    playerctl stop
    notify-send -e -u low -i "$music_icon" "Playback Stopped"
}

# Display notification with song information
show_music_notification() {
    status=$(playerctl status)
    if [[ "$status" == "Playing" ]]; then
        song_title=$(playerctl metadata title)
        song_artist=$(playerctl metadata artist)
        notify-send -e -u low -i "$music_icon" "Now Playing:" "$song_title\nby $song_artist"
    elif [[ "$status" == "Paused" ]]; then
        notify-send -e -u low -i "$music_icon" "Playback Paused"
    fi
}

show_music() {
    song_info=$(playerctl metadata --format "{{title}} - {{artist}}")
    # Check where song is coming from
    player=$(playerctl -l | head -n 1)
    logo=""

    # Check if player is spotify
    if [[ "$player" == "spotify" ]]; then
        logo=""     
    elif [[ "$player" == "firefox" ]]; then
        logo=""
    elif [[ "$player" == "chromium" ]]; then
        logo=""
    elif [[ "$player" == "mopidy" ]]; then
        logo=""
    elif [[ "$player" == "mpv" ]]; then
        logo="󰐹"
    elif [[ "$player" == "kdeconnect" ]]; then
        logo=""
    else
        logo=""
    fi

    echo $logo $song_info
}

# Get media control action from command line argument
case "$1" in
    "--nxt")
        play_next
        ;;
    "--prv")
        play_previous
        ;;
    "--pause")
        toggle_play_pause
        ;;
    "--stop")
        stop_playback
        ;;
    "show")
        show_music
        ;;
    *)
        echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
        exit 1
        ;;
esac
