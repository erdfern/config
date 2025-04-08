# let
#   sources = import ./npins;
#   disko = import sources.disko {};
# in
# {
#   imports = [ "${disko}/module.nix" ];
#   …
# }

{ lib, config, pkgs, project, ... }:
{
  imports = [
    ./hardware.nix
    # project.inputs.disko.result.packages.${pkgs.system}.icehouse
    "${project.inputs.disko.result}/module.nix"
  ];

  config = {

    boot.loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    plusultra = {
      nix.enable = true;

      cli-apps = {
        neovim.enable = true;
        tmux.enable = true;
      };

      tools = {
        git.enable = true;
        misc.enable = true;
        # comma.enable = true;
        bottom.enable = true;
        # icehouse.enable = true;
      };

      hardware = {
        networking.enable = true;
      };

      services = {
        openssh.enable = true;
        # tailscale.enable = true;
      };

      security = {
        # doas.enable = true;
      };

      system = {
        # boot.enable = true;
        fonts.enable = true;
        locale.enable = true;
        time.enable = true;
        xkb.enable = true;
      };
    };

    system.stateVersion = "24.11";
  };
}
