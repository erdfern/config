{ config, lib, pkgs, me, ... }:
let
  inherit (me) user;
  cfg = config.kor.gaming;
in
{
  options.kor.gaming = with lib; {
    enable = mkEnableOption "gaming";
  };

  config = lib.mkIf cfg.enable {

    programs.gamescope = {
      enable = false;
      #   capSysNice = true;
    };
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      # gamescopeSession = { enable = true; };

      extest.enable = true; # translate x11 input event to uinput (for steam input on wayland?)
      protontricks.enable = true;

      extraCompatPackages = [ pkgs.proton-ge-bin ];

      package = pkgs.steam.override {
        extraPkgs = pkgs: [
          #   pkgs.openssl_1_1
          #   (pkgs.callPackage ../pkgs/openldap_2_4.nix { })
          #   pkgs.libnghttp2
          #   pkgs.libidn2
          #   pkgs.rtmpdump
          #   pkgs.libpsl
          pkgs.usbutils # steam wants this in some shell script i think
          pkgs.xdg-utils # latest client doesn't find these otherwise...
        ];
        extraLibraries = pkgs: (with config.hardware.graphics;
          [ package ] ++ extraPackages);
        # if pkgs.hostPlatform.is64bit
        # then [ package ] ++ extraPackages
        # else [ package32 ] ++ extraPackages32);
      };
    };

    # udev rules for steam-supported controllers and such
    hardware.steam-hardware.enable = true;
    # gamecube controller support
    # services.udev.packages = with pkgs; [ dolphin-emu ];

    programs.gamemode.enable = true;
    users.users.${user}.extraGroups = [ "gamemode" ];

    environment = {
      systemPackages = with pkgs; [
        # just custom desktop items for launching steam with -pipewire and so on
        steam-pipewire

        # protonup-qt # installer for proton versions
        # protonup-rs # cli

        mangohud

        # (bottles.override { removeWarningPopup = true; })
        # wineWowPackages.stable
        # wineWowPackages.full
        # wineWowPackages.staging
        # wineWowPackages.waylandFull
        wineWow64Packages.full # experimental compat layer for running 32bit without installing 32bit libs, idk

        winetricks

        (heroic.override {
          extraPkgs = pkgs: [
            gamescope
            gamemode
            # pkgs.proton-ge-bin
            wineWow64Packages.full
            winetricks
          ];
        })

        # nexusmods-app-unfree # unfree for RAR support; DISCONTINUEEEED :[
      ];
      sessionVariables = {
        STEAM_COMPAT_DATA_PATH = "/home/${me.user}/.local/share/Steam/steamapps/compatdata";
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${me.user}/.local/share/Steam/compatibilitytools.d";
      };
    };
  };
}
