#  https://github.com/llakala/nixos/blob/3ae839c3b3d5fd4db2b78fa2dbb5ea1080a903cd/apps/programs/firefox/extensions.nix
{ pkgs, ... }:
let
  # Search extension names with below command:
  # nix flake show --json "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons" --all-systems | jq -r '.packages."x86_64-linux" | keys[]' | rg QUERY
  # ryceeAddons = with inputs.firefox-addons.result.packages.${pkgs.stdenv.hostPlatform.system};
  # ryceeAddons = with inputs.firefox-addons.result; # only x86_64 for now
  # ryceeAddons = with (inputs.rycee-nur-expressions.result { pkgs = pkgs; }).firefox-addons; [
  ryceeAddons = with pkgs.nur.repos.rycee.firefox-addons; [
    ublock-origin
    # TODO declare settings
    consent-o-matic
    auto-tab-discard
    clearurls
    link-cleaner

    # redirector # For nixos wiki
    # darkreader

    multi-account-containers
    proton-pass
    # refined-github
    indie-wiki-buddy
    # tab-stash
    # tree-style-tab

    # TODO use import/export feature for settings
    sponsorblock
    return-youtube-dislikes
    youtube-nonstop
  ];

  customAddons = [
  ];
in
{
  imports = [ ./theme.nix ./tridactyl.ext.nix ];

  programs.firefox.profiles.default.extensions.packages = ryceeAddons ++ customAddons;

  programs.firefox.policies."3rdparty".extensions = {
    "uBlock0@raymondhill.net" =
      {
        permissions = [ "internal:privateBrowsingAllowed" ];
        origins = [ ];
      };

    # for "Run on sites with restrictions" I'd have to somehow:
    # default/prefs.js: user_pref("extensions.quarantineIgnoredByUser.gdpr@cavi.au.dk", true);
    "gdpr@cavi.au.dk" =
      {
        "permissions" = [ "<all_urls>" ];
        "origins" = [ "<all_urls>" ];
      };
  };
}
