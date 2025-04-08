{ config }:
let
  inherit (config) lib;
in
{
  config = {
    colmena.nodes.dedi = {
      deployment = {
        targetUser = "lk";
        privilegeEscalationCommand = [ "sudo" ];

        tags = [ "server" "testing" ];
        allowLocalDeployment = true;
      };
    };

    systems.nixos.dedi = {
      pkgs = config.inputs.nixpkgs.result.x86_64-linux;
      args = {
        project = config;
        host = "dedi";
      };
      modules = [
        ./configuration.nix
        ../modules
        config.inputs.home-manager.result.nixosModules.home-manager
      ];
    };
  };
}
