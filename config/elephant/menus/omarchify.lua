--
-- Omarchify actions, searchable from Walker.
--
-- Rather than Omabuntu's nested category menu (Style/Setup/Install/...), which
-- mostly wraps machinery we deliberately skipped, this exposes the actions
-- themselves so they are reachable by typing: "lock", "bluetooth", "transcode".
--
-- Commands MUST be absolute: elephant runs as a systemd user service and does
-- not have ~/.local/bin on its PATH.
--
Name = "omarchify"
NamePretty = "Omarchify"
FixedOrder = false

local home = os.getenv("HOME")
local bin = home .. "/.local/bin/"

local actions = {
  -- session
  { "󰌾  Lock screen",          "loginctl lock-session" },
  { "󰍃  Log out",              "gnome-session-quit --logout --no-prompt" },
  { "󰤄  Suspend",              "systemctl suspend" },
  { "󰜉  Restart",              "systemctl reboot" },
  { "󰐥  Shut down",            "systemctl poweroff" },

  -- tools we built
  { "󰅇  Clipboard history",    bin .. "walker-clipboard" },
  { "󰆞  Screenshot",           "sh -c 'flatpak run org.flameshot.Flameshot gui'" },
  { "󰕧  Transcode media",      bin .. "omarchify-transcode" },
  { "󰌌  Keybindings",          bin .. "omarchify-menu-keybindings" },
  { "󰚩  Coding agent",         bin .. "omarchify-launch-agent" },
  { "󰖟  Install web app",      bin .. "omarchify-menu webapp" },

  -- toggles
  { "󰌵  Toggle night light",   "gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled " ..
                               "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled | grep -q true && echo false || echo true)" },
  { "󰂛  Toggle do not disturb", "gsettings set org.gnome.desktop.notifications show-banners " ..
                               "$(gsettings get org.gnome.desktop.notifications show-banners | grep -q true && echo false || echo true)" },
  { "󰔎  Toggle dark mode",     "sh -c 'test \"$(gsettings get org.gnome.desktop.interface color-scheme)\" = \"'\"'\"'prefer-dark'\"'\"'\" " ..
                               "&& gsettings set org.gnome.desktop.interface color-scheme default " ..
                               "|| gsettings set org.gnome.desktop.interface color-scheme prefer-dark'" },

  -- settings panels
  { "󰕾  Sound settings",       "gnome-control-center sound" },
  { "󰂯  Bluetooth settings",   "gnome-control-center bluetooth" },
  { "󰤨  Network settings",     "gnome-control-center wifi" },
  { "󰍹  Display settings",     "gnome-control-center display" },
  { "󰁹  Power settings",       "gnome-control-center power" },
}

function GetEntries()
  local entries = {}
  for _, a in ipairs(actions) do
    table.insert(entries, {
      Text = a[1],
      Actions = { activate = a[2] },
    })
  end
  return entries
end
