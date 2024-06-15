{ pkgs, config, lib, ... }:

let
  cfg = config.languages.zig;
in
{
  options.languages.zig = {
    enable = lib.mkEnableOption "tools for Zig development";

    package = lib.mkOption {
      type = lib.types.package;
      description = "Which package of Zig to use.";
      default = pkgs.zig;
      defaultText = lib.literalExpression "pkgs.zig";
    };

    zls = {
      # package = lib.mkPackageOption pkgs "zls" "Which package of Zig Language Server to use.";
      package = lib.mkOption {
        type = lib.types.package;
        description = "Which package of zls to use.";
        default = pkgs.zls;
        defaultText = lib.literalExpression "pkgs.zls";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      cfg.package
      cfg.zls.package
    ];
  };
}
