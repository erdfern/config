{ pkgs, inputs, ... }:
{
  imports = [
    ./wayle-conf.nix
  ];

  kor.desktop.enable = true;
  kor.desktop.apps.firefox.enable = true;
  kor.desktop.apps.firefox.makeDefault = true;
  kor.desktop.suites.gaming.enable = true;
  kor.desktop.suites.media.enable = true;

  # kor.development.neovim.enable = true;
  kor.development.vscode.enable = true;
  # kor.development.rider.enable = true;
  # kor.development.idea.enable = true;

  kor.desktop.enableHyprland = true;
  kor.desktop.hyprland.hyprpaper.enable = true;
  kor.desktop.hyprland.hyprpaper.wall = ./strata.png;

  # kor.desktop.apps.waybar.enable= true;
  # kor.desktop.apps.waybar.hyprlandAutostart = true;
  # kor.desktop.apps.hyprpanel.enable = true;
  kor.desktop.apps.wayle.enable = true;

  kor.desktop.apps.kitty.enable = true;
  # kor.desktop.apps.ghostty.enable = true;

  kor.desktop.apps.freecad.enable = true;
  # kor.desktop.apps.freecad.pythonPackages = ps: [ ps.numpy ];

  kor.desktop.apps.feh.enable = true; # imv (media suite) holds the image defaults

  home.packages = [
    # inputs.devenv.result.packages.x86_64-linux.default
    pkgs.devenv
    # pkgs.openscad-unstable
    # pkgs.openscad-lsp
    # pkgs.freecad-git
    # pkgs.orca-slicer
    pkgs.discord
    pkgs.luanti
    pkgs.kicad
    # pkgs.seamly2d
    # pkgs.valentina-git
  ];

  kor.desktop.uwsm.env = [
    "LIBVA_DRIVER_NAME=radeonsi"
    "VDPAU_DRIVER=radeonsi"

    # nvidia
    # "export GBM_BACKEND=nvidia-drm"
    # export __GL_GSYNC_ALLOWED=1
    # export __GL_VRR_ALLOWED=0
  ];

  kor.desktop.uwsm.envHyprland = [
    "AQ_DRM_DEVICES=/dev/dri/card1" # :dGPU
    # "AQ_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1" # iGPU:dGPU

    # "HYPRLAND_TRACE=1"
    # "AQ_TRACE=1"
  ];

  # home.packages = with pkgs; [
  #   npins
  #   inputs.nilla-cli.result.packages.nilla-cli.result.x86_64-linux
  #   inputs.nilla-utils.result.packages.nilla-utils-plugins.result.x86_64-linux
  # ];

  programs.claude-code = {
    enable = true;
  };

  home.stateVersion = "26.11";
}
