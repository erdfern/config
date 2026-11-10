{ lib
, config
, pkgs
, me
, ...
}:
let
  inherit (me) user;
  cfg = config.kor.system.audio;
in
{
  # uh... this might not be idiomatic
  # imports = lib.optionals (lib.versionAtLeast lib.version "25.05pre-git") [
  #   { services.pulseaudio.enable = lib.mkForce false; }
  # ];

  options.kor.system.audio = {
    enable = lib.mkEnableOption "audio support";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;

    services.pulseaudio.enable = lib.mkForce false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true; # pulse emulation

      wireplumber.enable = true;
    };

    environment.systemPackages = with pkgs; [
      # pulsemixer
      # pavucontrol
      # cool pipewire tools
      easyeffects
      pwvucontrol # pavucontrol-ish gui specifically for pipewire
      coppwr # pipewire low level diagnostics gui
      # qpwgraph
      # helvum
      # sonusmix

      qjackctl # jack patchbay
    ];

    users.users.${user}.extraGroups = lib.singleton "audio";

    # wireplumber bluetooth codecs
    # services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
    #   "monitor.bluez.properties" = {
    #     "bluez5.enable-sbc-xq" = true;
    #     "bluez5.enable-msbc" = true;
    #     "bluez5.enable-hw-volume" = true;
    #     "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
    #   };
    # };
  };
}
