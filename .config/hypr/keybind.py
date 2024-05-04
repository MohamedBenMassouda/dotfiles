def get_keybinds(path: str) -> dict:
    with open(path) as file:
        variables = {}
        binds = {}

        for line in file:
            line = line.strip()
            value = line.split("=")
            if len(line) <= 0 or line[0] == "#":
                continue

            if line[0] == "$":
                variables[value[0]] = value[1]

            elif value[0].strip() in ["bind", "bindr"]:
                bind = value[1].split(",")[:2]
                command = value[1].split(",")[2:]
                binds[bind.__str__()] = command

    return binds


import subprocess

# Define dynamic width and height variables
dynamic_width = 1200
dynamic_height = 800

# Define the yad command
yad_command = [
    "yad",
    "--width={}".format(dynamic_width),
    "--height={}".format(dynamic_height),
    "--center",
    "--title=Keybindings",
    "--no-buttons",
    "--list",
    "--column=Key:",
    "--column=Command:",
]

paths = [
    "/home/monarch/.config/hypr/UserConfigs/UserKeybinds.conf",
    "/home/monarch/.config/hypr/configs/Keybinds.conf",
]
binds = get_keybinds(paths[0])
binds.update(get_keybinds(paths[1]))

for key in binds.keys():
    yad_command.append(key)
    yad_command.append(str(binds[key]))


# Run the yad command
subprocess.run(yad_command)
