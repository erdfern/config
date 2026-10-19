{ me
, pkgs
, inputs
, config
, ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    # ./f2fs.nix
    ./graphics.nix
    # ./wifihotspot.nix
    "${inputs.facter.result}/modules/nixos/facter.nix"
    inputs.probe-rs-rules.result.nixosModules.x86_64-linux.default
  ];
  hardware.probe-rs.enable = true;

  facter.reportPath = ./facter.json;

  # boot.extraModulePackages = [ config.boot.kernelPackages.r8125 ];
  # boot.blacklistedKernelModules = [ "r8169" ];
  networking.networkmanager.ensureProfiles.profiles = {
    "wired-enp9s0" = {
      connection = {
        id = "wired-enp9s0";
        type = "ethernet";
        interface-name = "enp9s0";
        autoconnect = true;
      };
      ipv4.method = "auto";
      ipv6 = {
        method = "auto";
        addr-gen-mode = "stable-privacy";
      };
    };
  };

  kor.profiles.desktop.enable = true;
  kor.profiles.development.enable = true;

  kor.gaming.enable = true;
  kor.flatpak.enable = true;
  # OrcaSlicer's nixpkgs build has a blank 3D viewport on this host: a GL
  # regression in the mesa-26.1.2 driver vs its wxWidgets-3.1.7 GLX context
  # (libgbm/mesa version skew is intentional in nixpkgs and unrelated). The
  # Flatpak runs against the Freedesktop runtime's mesa and renders correctly.
  # kor.flatpak.packages = [ "com.orcaslicer.OrcaSlicer" ];

  kor.hardware.sk.yubikey.enable = true;
  # kor.hardware.sk.nitrokey.enable = true;
  kor.hardware.sk.piv.enable = true;

  # kor.virtualisation.qemu.enable = true;
  kor.virtualisation.containers.enable = true;
  kor.virtualisation.waydroid.enable = true;


  services.deluge = {
    enable = true;
    web.enable = false;
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.systemPackages = [
    # pkgs.arduino-ide
    pkgs.arduino-cli
    # orca-slicer is installed via Flatpak (see kor.flatpak.packages above);
    # the nixpkgs build's 3D viewport is broken by a mesa-26.1 GL regression.
  ];
  # environment.systemPackages = [
  # pkgs.inkscape
  # (pkgs.inkscape-with-extensions.override {
  #   inkscapeExtensions = with pkgs.inkscape-extensions; [];
  # })
  # ];
  # environment.systemPackages = [ pkgs.zoom-us ];
  # programs.obs-studio = {
  #   enable = true;
  #   enableVirtualCamera = true;
  #   plugins = with pkgs.obs-studio-plugins; [
  #     droidcam-obs
  #   ];
  # };
  # programs.adb.enable = true;
  # # users.users.j.extraGroups = [ "adbusers" ];
  # services.udev.packages = [ pkgs.android-udev-rules ];

  # networking.firewall.enable = false;

  # networking.hostId = "7c238412";

  # Wake-on-LAN on the onboard Realtek RTL8125 (2.5GbE, enp9s0). This emits a
  # `40-enp9s0.link` that systemd-udev applies via ethtool at device probe, so
  # Firmware side (GIGABYTE B650 GAMING X AX): BIOS > Settings > Platform Power:
  # set "ErP" to Disabled (so S5 keeps the NIC powered) and enable
  # "Power On By PCIE/PCI" (aka Wake on LAN).
  networking.interfaces.enp9s0.wakeOnLan = {
    enable = true;
    policy = [ "magic" ];
  };

  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  # boot.kernelPackages = pkgs.linuxKernel.kernels.linux_zen;
  # boot.kernelPackages = pkgs.linuxPackages_zen;

  services.openssh = {
    enable = true;
  };

  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$F2VMMSRv8pG5wHRw$HVtjknqzelzHPaIM6a4gmeQpYT4CHlhClVkfjU5hjItM41LOIwzy7M9iOMgWdeTOCB8ccIWiRY/v0.1MexDQu.";
  users.users.${me.user} = {
    initialHashedPassword = "$6$F2VMMSRv8pG5wHRw$HVtjknqzelzHPaIM6a4gmeQpYT4CHlhClVkfjU5hjItM41LOIwzy7M9iOMgWdeTOCB8ccIWiRY/v0.1MexDQu.";
    # TEMP
    extraGroups = [
      "adbusers"
      "dialout" # arduino-ide dfu-util etc
      "plugdev" # embassy/probe-rs
    ];
  };

  # fix permission issue with dfu-util when flashing stm32
  services.udev.extraRules = ''
    # STM32 DFU-Bootloader (Upload)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", MODE="0666", TAG+="uaccess"
    # STM32 USB-CDC (Serial nach dem Flashen)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", MODE="0666", TAG+="uaccess"
  '';

  system.stateVersion = "26.11";
}
