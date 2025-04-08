{ lib }:
{
  options.colmena.nodes = lib.options.create {
    description = "Colmena configuration for deployment targets.";
    default.value = { };
    type = lib.types.attrs.of (lib.types.submodule {
      options = {
        deployment = lib.options.create {
          description = "Deployment configuration for the node.";
          default.value = { };
          type = lib.types.submodule {
            options = {
              targetUser = lib.options.create {
                description = "The user to deploy as.";
                default.value = "lk";
                type = lib.types.string;
              };

              allowLocalDeployment = lib.options.create {
                description = "Whether local deployment is allowed or not.";
                default.value = false;
                type = lib.types.bool;
              };

              privilegeEscalationCommand = lib.options.create {
                description = "The command to use for privilege escalation.";
                default.value = [ "doas" ];
                type = lib.types.list.of lib.types.string;
              };

              tags = lib.options.create {
                description = "The tags for the deployment target.";
                default.value = [ ];
                type = lib.types.list.of lib.types.string;
                apply = lib.lists.unique;
              };
            };
          };
        };
      };
    });
  };
}
