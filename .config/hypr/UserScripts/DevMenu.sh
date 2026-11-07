#!/usr/bin/env bash
# Dev menu (SUPER+ALT+D):
#   Containers  docker containers: start / stop / logs / shell (starts Docker if it's off)
#   Ports       what listens on which port; pick one to stop that process
#   Lazygit     open lazygit in a project (same list as SUPER+T)
source "$HOME/.config/hypr/UserScripts/applet.sh"
menu_toggle dev || exit 0
term=(kitty)
PROJECT_DIR="/mnt/Data/Programming"

choice=$(applet "Dev" $'\U000F0868|Containers' $'\U000F031A|Ports' $'\U000F02A2|Lazygit') || exit 0

case $choice in
0)  # ---- containers ----
    if ! docker info >/dev/null 2>&1; then
      confirm "Docker is off. Start it?" || exit 0
      systemctl start docker || exit 1          # polkit asks for the password
    fi
    mapfile -t rows < <(docker ps -a --format '{{.Names}}|{{.State}}|{{.Image}}|{{.Status}}')
    [[ ${#rows[@]} -gt 0 ]] || { qs ipc call osd toast dev "Containers" "None"; exit 0; }
    pick=$(for r in "${rows[@]}"; do
             IFS='|' read -r name state image status <<<"$r"
             [[ $state == running ]] && dot="🟢" || dot="⚪"
             printf '%s %s  ·  %s  ·  %s\n' "$dot" "$name" "$image" "$status"
           done | rofi -dmenu -i -p Containers -format i) || exit 0
    IFS='|' read -r name state _ <<<"${rows[$pick]}"
    if [[ $state == running ]]; then
      act=$(applet "$name" $'\U000F04DB|Stop' $'\U000F0450|Restart' $'\U000F0219|Logs' $'\U000F018D|Shell') || exit 0
      case $act in
        0) docker stop "$name" >/dev/null ;;
        1) docker restart "$name" >/dev/null ;;
        2) exec "${term[@]}" --title "logs: $name" docker logs -f --tail 200 "$name" ;;
        3) exec "${term[@]}" --title "shell: $name" docker exec -it "$name" sh -c 'command -v bash >/dev/null && exec bash || exec sh' ;;
      esac
    else
      act=$(applet "$name" $'\U000F040A|Start' $'\U000F0219|Logs') || exit 0
      case $act in
        0) docker start "$name" >/dev/null ;;
        1) exec "${term[@]}" --title "logs: $name" docker logs --tail 200 "$name" ;;
      esac
    fi
    qs ipc call osd toast dev "$name" "Done" >/dev/null 2>&1 ;;

1)  # ---- listening ports ----
    mapfile -t rows < <(ss -ltnpH | awk '{
        n = split($4, a, ":"); port = a[n]
        proc = "?"; pid = ""
        if (match($0, /users:\(\("[^"]+",pid=[0-9]+/)) {
          s = substr($0, RSTART + 9, RLENGTH - 9); split(s, b, "\",pid=")
          proc = b[1]; pid = b[2]
        }
        print port "|" proc "|" pid
      }' | sort -t'|' -k1,1n -u)
    [[ ${#rows[@]} -gt 0 ]] || exit 0
    pick=$(for r in "${rows[@]}"; do
             IFS='|' read -r port proc pid <<<"$r"
             printf ':%-6s %s%s\n' "$port" "$proc" "${pid:+  (pid $pid)}"
           done | rofi -dmenu -i -p Ports -format i) || exit 0
    IFS='|' read -r port proc pid <<<"${rows[$pick]}"
    [[ -n $pid ]] || { qs ipc call osd toast dev "Port $port" "Owned by another user (root?)"; exit 0; }
    confirm "Stop $proc on :$port?" && kill "$pid" &&
      qs ipc call osd toast dev "Port $port" "Stopped $proc" >/dev/null 2>&1 ;;

2)  # ---- lazygit in a project ----
    mapfile -t dirs < <(find "$PROJECT_DIR" -mindepth 1 -maxdepth 3 -type d -name .git 2>/dev/null | sed 's|/\.git$||' | sort)
    pick=$(for d in "${dirs[@]}"; do printf '%s\0icon\x1f%s\n' "${d#"$PROJECT_DIR"/}" folder-git; done |
           rofi -dmenu -i -p Lazygit -show-icons -format i) || exit 0
    exec "${term[@]}" --directory "${dirs[$pick]}" lazygit ;;
esac
