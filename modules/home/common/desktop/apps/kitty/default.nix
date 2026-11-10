{ lib, config, ... }:
let
  cfg = config.kor.desktop.apps.kitty;
in
{
  options.kor.desktop.apps.kitty = with lib; {
    enable = mkEnableOption "kitty terminal";
    makeFishAliases = mkOption { type = lib.types.bool; default = config.programs.fish.enable; };
    makeDefault = mkOption { type = lib.types.bool; default = true; };
  };

  config = lib.mkIf cfg.enable {
    # $TERM is set to xterm-kitty by default
    kor.desktop.uwsm.env = lib.mkIf cfg.makeDefault [ "TERMINAL=kitty" ];
    programs.fish.shellAliases = lib.mkIf cfg.makeFishAliases { s = "kitten ssh"; };
    programs.kitty = {
      enable = cfg.enable;
      enableGitIntegration = true;
      environment = { };
      font.name = "GeistMono NF";
      # font.size = 16;
      actionAliases = {
        "launch_tab" = "launch --cwd=current --type=tab";
        "launch_window" = "launch --cwd=current --type=os-window";
      };
      settings = {
        allow_remote_control = "yes"; # TODO make this finegrained for security? i basically just want this for fuzzel/kitty @ launch
        disable_ligatures = "cursor";
        italic_font = "auto";
        bold_italic_font = "auto";
        mouse_hide_wait = -1; # hide on typing, else compositor should handle it
        cursor_shape = "block";
        # url_color = "#0087bd";
        url_style = "dotted";
        #Close the terminal =  without confirmation;
        confirm_os_window_close = 0;
        background_opacity = "0.9";

        remember_window_size = "no"; # otherwise, starts maximized on Hyprland...

        # performance, maybe at the cost of energy usage
        # input_delay = 0;
        input_delay = 3;
        # repaint_delay = 2;
        repaint_delay = 8; # ~125fps
        sync_to_monitor = "no";
        wayland_enable_ime = "no"; # input method extensions; don't need it, and is said to be buggy+add input latency
      };
      # https://sw.kovidgoyal.net/kitty/mapping/#unmapping-default-shortcuts
      # https://sw.kovidgoyal.net/kitty/conf/#keyboard-shortcuts
      keybindings = {
        "ctrl+alt+t" = "new_tab_with_cwd";
        "ctrl+alt+w" = "new_window_with_cwd";

        # Tabs
        "" = "next_layout"; # kitty_mod+l by default
        "kitty_mod+l" = "next_tab";
        "kitty_mod+h" = "previous_tab";
      };
      quickAccessTerminalConfig =
        {
          # kitty_override ???
          # This would need to be valid, since kitty_override can appear multiple times!! :<
          # kitty_override = [
          #   "allow_remote_control=socket-only"
          #   "listen_on=unix:/tmp/quickitty"
          # ];
          kitty_override = "listen_on=unix:/tmp/quickitty";
          start_as_hidden = false;
          hide_on_focus_loss = false;
          background_opacity = 0.85;
        };
    };

  };
}
