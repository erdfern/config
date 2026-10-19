let
  pins = import ./npins;

  nilla = import pins.nilla;

  me = import ./me.nix;
in
nilla.create ({ config }:
let
  inherit (config) lib;

  # One concrete (overlayed, unfree-enabled) nixpkgs used to build the helper
  # commands below. It is the same instance the NixOS generator uses, so the
  # commands' runtime deps are shared with the systems -- nothing is duplicated.
  pkgs = config.inputs.nixpkgs.result.x86_64-linux;

  nillaCli = config.inputs.nilla-cli.result.packages.default.result.x86_64-linux;
  nillaUtils = config.inputs.nilla-utils.result.packages.default.result.x86_64-linux;

  # `install`, `deploy`, `build-installer` -- bodies live in ./scripts/*.sh.
  # Defined once here and reused by both the dev shell and the installer ISO.
  mkCmd = name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ./scripts/${name}.sh;
    };

  commands = {
    install = mkCmd "install" (with pkgs; [
      nix
      git
      openssh
      coreutils
      nixos-anywhere
      nixos-install-tools
    ]);
    deploy = mkCmd "deploy" (with pkgs; [ nix git nillaCli nillaUtils ]);
    wake = mkCmd "wake" (with pkgs; [ nix git wakeonlan ]);
    build-installer = mkCmd "build-installer" (with pkgs; [ nix ]);
    update-vscode-insiders = mkCmd "update-vscode-insiders" (with pkgs; [ curl jq git coreutils ]);
  };

  # The whole Nilla config, importable into the store (minus VCS / scratch dirs).
  # Baked into the installer ISO at /etc/nconf so `install <host>` needs no clone.
  projectSrc = builtins.path {
    path = ./.;
    name = "nconf";
    filter = path: _type: !(builtins.elem (baseNameOf path) [ ".git" ".direnv" "result" ]);
  };
in
{
  includes = [
    ./inputs.nix
    ./lib

    "${pins.nilla-utils}/modules"
    ./modules/hive

    # TODO not ideal; should gather automatically if hosts have a default.nix
    ./hosts/kor-t14
  ];

  config = {

    ###########
    ## NixOS ##
    ###########
    # Export NixOS module
    # modules.nixos.default = ./modules/nixos;
    generators.nixosModules.folder = ./modules/nixos;

    # Generate nixos hosts from folders in ./hosts
    generators.nixos = {
      folder = ./hosts;
      # pkgs = config.inputs.nixpkgs;

      args = { inherit me; };

      modules = [
        config.modules.nixos.core
        config.inputs.catppuccin-nix.result.nixosModules.catppuccin
        "${config.inputs.disko.result}/module.nix"

        # TODO I'd prefer to use the nixos module instead of stand-alone home-manager
        # (import "${config.inputs.home-manager.result}/nixos")
        # ({ ... }: {
        #   users.users.rando.isNormalUser = true;
        #   home-manager.users.rando = {
        #     home.stateVersion = "24.11";
        #   };
        # })
      ];
    };

    ##################
    ## Home Manager ##
    ##################
    # modules.home.default = ./modules/home;
    #
    # Generates homeModules.{folder_name} for each subfolder of ./modules/home
    generators.homeModules.folder = ./modules/home;

    # Generate home-manager configurations from folders in ./hosts
    generators.home = {
      username = me.user;
      folder = ./hosts;

      args = { inherit me; };

      # TODO allow configuring home-manager input for all hosts.
      # Also, use flake-compat to set home-manager inputs nixpkgs?

      # args.nixOsConfig = config.systems.; # try to pass through osConfig to stand-alone for reading.
      # TODO could modify the generator to do that optionally, but at that point just use the nixosModule instead of stand-alone...

      modules = [
        config.modules.home.common
        config.inputs.catppuccin-nix.result.homeModules.catppuccin
        config.inputs.nix-index-database.result.homeModules.nix-index
        # config.inputs.nvim-conf.result.homeModules.default
        # ({}:{
        # })
      ];
    };

    ##############
    ## Overlays ##
    ##############
    # Generate `default` overlay from folders with `default.nix` in `./packages`
    generators.overlays.default.folder = ./packages;
    # and packages by themselves, useful for building them via just packages.<pname> or `nilla build <pname>`
    generators.packages.folder = ./packages;

    #######################
    ## Special overrides ##
    #######################
    # systems.nixos.kor.nixpkgs = config.inputs.nixpkgs;
    systems.home = {
      "${me.user}@kor" = {
        # pkgs = config.inputs.nixpkgs.result.x86_64-linux;
        args.nixOsConfig = config.systems.nixos.kor.result.config;
        # HACK
        args.osConfig = config.systems.nixos.kor.result.config;
      };
      "${me.user}@kor-t14" = {
        # HACK
        args.osConfig = config.systems.nixos.kor-t14.result.config;
      };
    };

    # systems.nixos.kor-t14.nixpkgs = config.inputs.nixpkgs;
    # systems.home."${user}@kor-t14".pkgs = config.inputs.nixpkgs.result.x86_64-linux;

    # Lix lix lix
    systems.nixos.kor = {
      # modules = [ config.modules.nixos.lix ];
      modules = [
        ({ pkgs, ... }: {
          # NOTE 16.10.25 the nixpkgs lix package does this (and more) by itself now!
          # nixpkgs.overlays = [
          #   (self: super: {
          #     inherit (super.lixPackageSets.git) nixpkgs-review nix-eval-jobs nix-fast-build colmena;
          #   })
          # ];
          # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/tools/package-management/lix/default.nix
          # stable, latest, git, lix_x_xx
          nix.package = pkgs.lixPackageSets.stable.lix;
        })
      ];
    };

    ###############
    ## Installer ##
    ###############
    # A lean live-ISO system. Declared manually (NOT under ./hosts) so it does not
    # inherit the desktop `core` defaults. Boot it on a fresh machine, then run
    # `install <host> root@<ip>` from another machine. Build via `build-installer`.
    systems.nixos.installer.modules = [
      "${pins.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      "${pins.nixpkgs}/nixos/modules/profiles/all-hardware.nix"
      ({ pkgs, lib, ... }: {
        networking.hostName = lib.mkForce "installer";

        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
        users.users.root.openssh.authorizedKeys.keys = me.ssh.pubKeys;
        users.users.nixos.openssh.authorizedKeys.keys = me.ssh.pubKeys;

        # Security-key support so the install/recovery flow can use sk-* SSH keys
        # and fido2/yubikey-backed sops age identities.
        hardware.nitrokey.enable = true;
        services.pcscd.enable = true;
        services.udev.packages = [ pkgs.yubikey-personalization ];

        nix.settings = {
          experimental-features = [ "nix-command" "flakes" ];
          trusted-users = [ "root" "nixos" ];
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://kor.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "kor.cachix.org-1:120l5rP3Npq4wDdbg8AkJ85J4zqilDXMGt2XQHWDHOM="
          ];
        };

        # Embed the whole config so `install <host>` resolves it with no clone.
        environment.etc.nconf.source = projectSrc;
        environment.variables.NCONF_PROJECT = "/etc/nconf";

        environment.systemPackages = (with pkgs; [
          # provisioning
          git
          disko
          npins
          nixos-facter
          nixos-anywhere
          nixos-install-tools
          util-linux
          jq
          helix
          # security keys
          pcsc-tools
          pynitrokey
          age-plugin-fido2-hmac
          yubikey-manager
          age-plugin-yubikey
        ]) ++ [
          commands.install
          commands.deploy
        ];

        # stateVersion is supplied by installation-cd-base.nix; don't override it.
      })
    ];

    shells.default = {
      systems = [ "x86_64-linux" ];

      # The sole `nixpkgs` pin already tracks nixos-unstable; there is no
      # separate `nixpkgs-unstable` input.
      settings.pkgs = config.inputs.nixpkgs.result;

      # `install` / `deploy` / `build-installer` plus the nilla CLIs for manual
      # `nilla os/home ...`. The commands are the same derivations baked into the
      # installer ISO (see `commands` in the top-level `let`).
      shell = { mkShell, ... }:
        mkShell {
          packages = [ nillaCli nillaUtils ] ++ builtins.attrValues commands;
        };
    };
  };
})
