{ lib, config, pkgs, project, host, ... }:
let
  cfg = config.plusultra.services.openssh;

  user = config.users.users.${config.plusultra.user.name};
  user-id = builtins.toString user.uid;

  # TODO: This is a hold-over from an earlier Snowfall Lib version which used
  # the specialArg `name` to provide the host name.
  name = host;

  default-key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCfVh3cSJcpVIF9CMEp0Nd5AB2oM/EB8T1dZqpr4bzXLBRWO7wiAsAnBXP6nDNFrqHu4zmCnXWfe6ZdmEhFaKlOQ/wVQAgDKhoA7sF+uS0okWpUcuDgNV5EI2ARA7zdQE2ZN373V/ojZg3VCedYMv3xYRDFfGmBrhhg0EjBPOqvzpQQO5LA2VYFlyRNU8d3xaox6gxw73jcNQXED/w6cZfSfoXpJCBG8p6YwOeNNnYIBum3Ph7p7Y2gjjUz0XT8jtKuT7f18ImeTe76iOTmYkgr7KRkamOFhxFm5jtIejfEg/6IMT2REH0o+zXJvAvxLpZhqZxbyyCqzYVf/NemBsUCXUOPlhE+GPhbZwatS3IKPDbrfJuNzkbEOVkmyVPeFeKHERpUBsrHz0HuX8HGXwjPoyTh6xPmC5L6Wn9rMGhRKIWxITQ3nW6j8nBP7YOYLlSgZAXdEIeNM0oxBY9QErtRvFrRXSyiDY3bxNBg+ncGPZr0Yf0WqFJj3dLTWGGmEGYa2UUCZvYKdHmc0EOy6El7vabi1JRzykY+8M1OA/t52Ixo91+TGfNnj7p7pO1gPV6QehFQy3nOnfwzLZKPcDM2z27XI1VT6OsqFK3IvoT1t2F1AVft54yghlt0TdjFPg/e5eRtZFcI1m1zFh0XK+bUICAtBq8vzpUynOtCVjXVEQ== lk@kor-t14";

  other-hosts = lib.filterAttrs
    (
      key: host: key != name && (host.result.config.plusultra.user.name or null) != null
    )
    ((project.systems.nixos or { }) // (project.systems.macos or { }));

  other-hosts-config = lib.concatMapStringsSep "\n"
    (
      name:
      let
        remote = other-hosts.${name}.result;
        remote-user-name = remote.config.plusultra.user.name;
        remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;

        forward-gpg =
          lib.optionalString (config.programs.gnupg.agent.enable && remote.config.programs.gnupg.agent.enable)
            ''
              RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra
              RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh
            '';
      in
      ''
        Host ${name}
          User ${remote-user-name}
          ForwardAgent yes
          Port ${builtins.toString cfg.port}
          ${forward-gpg}
      ''
    )
    (builtins.attrNames other-hosts);
in
{
  options.plusultra.services.openssh = {
    enable = lib.mkEnableOption "OpenSSH";

    authorizedKeys = lib.mkOption {
      description = "The public keys to allow.";
      type = lib.types.listOf lib.types.str;
      default = [ default-key ];
    };

    port = lib.mkOption {
      description = "The port to listen on (in addition to 22).";
      type = lib.types.port;
      default = 2222;
    };

    manage-other-hosts = lib.mkOption {
      description = "Whether or not to add other host configurations to SSH config.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };

      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      ports = [
        22
        cfg.port
      ];
    };

    programs.ssh.extraConfig = ''
      Host *
        HostKeyAlgorithms +ssh-rsa

      ${lib.optionalString cfg.manage-other-hosts other-hosts-config}
    '';

    plusultra.user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    plusultra.home.extraOptions = {
      programs.zsh.shellAliases = lib.foldl
        (
          aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
        )
        { }
        (builtins.attrNames other-hosts);
    };
  };
}
