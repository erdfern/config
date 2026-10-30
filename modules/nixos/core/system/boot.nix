{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.kor.system.boot;
in
{
  options.kor.system.boot = with lib; {
    enable = mkEnableOption "system bootloader";
    plymouth = {
      enable = mkEnableOption "use plymouth";
      catppuccinTheme = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the catppuccin theme for plymouth.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    catppuccin.plymouth.enable = cfg.plymouth.catppuccinTheme;

    # TODO move to separate systemd config
    services.journald.settings.Journal = {
      SystemMaxUse = "500M";
      MaxRetentionSec = "1month";
    };

    boot = {
      plymouth = lib.mkIf cfg.plymouth.enable {
        enable = true;
        # theme = 
      };
      initrd.systemd.enable = lib.mkIf cfg.plymouth.enable true; # systemd-stage-1 

      # more silent boot
      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];

      # stop low level messages (acpi errors and such) flooding the console after boot
      # kernel.sysctl = { "kernel.printk" = "3 4 1 3"; };

      loader = {
        timeout = if cfg.plymouth.enable then 0 else 3; # if 0, press any key to show OS selection
        systemd-boot = {
          enable = true;
          editor = false;
          consoleMode = "auto";
        };
        efi.canTouchEfiVariables = true;
      };
    };
  };
}
