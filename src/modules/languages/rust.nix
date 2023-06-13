{ pkgs, config, lib, inputs, ... }:

let
  inherit (lib.attrsets) attrValues genAttrs getAttrs;

  cfg = config.languages.rust;
  setup = ''
    inputs:
      fenix:
        url: github:nix-community/fenix
        inputs:
          nixpkgs:
            follows: nixpkgs
  '';
in
{
  options.languages.rust = {
    enable = lib.mkEnableOption "tools for Rust development";

    components = lib.mkOption {
      # TODO: better typing here?
      type = lib.types.listOf lib.types.str;
      defaultText = lib.literalExpression ''[ "rustc" "cargo" "rustfmt" "clippy" "rust-analyzer" "rust-src" ]'';
      default = [ "rustc" "cargo" "rustfmt" "clippy" "rust-analyzer" "rust-src" ];
      description = "List of rustup components to install.";
    };

    packages = lib.mkOption {
      type = lib.types.submodule ({
        options = {
          rust-src = lib.mkOption {
            type = lib.types.either lib.types.package lib.types.str;
            default = pkgs.rustPlatform.rustLibSrc;
            defaultText = lib.literalExpression "pkgs.rustPlatform.rustLibSrc";
            description = "rust-src package";
          };
        }
        // genAttrs cfg.components (name: lib.mkOption {
          type = lib.types.package;
          default = pkgs.${name};
          defaultText = lib.literalExpression "pkgs.${name}";
          description = "${name} package";
        });
      });
      defaultText = lib.literalExpression "pkgs";
      default = { };
      description = "Attribute set of packages including rustc and Cargo.";
    };

    # package = lib.mkOption {
    #   type = lib.types.nullOr lib.types.package;
    #   default = null;
    #   description = "Package containing the Rust toolchain to use.";
    # };

    toolchain = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.attrs (lib.types.enum [ "stable" "beta" "nightly" ]));
      default = null;
      description = "Fenix toolchain to use.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      packages = attrValues cfg.packages ++ lib.optional pkgs.stdenv.isDarwin pkgs.libiconv;

      # enable compiler tooling by default to expose things like cc
      languages.c.enable = lib.mkDefault true;

      env.RUST_SRC_PATH = cfg.packages.rust-src;

      pre-commit.tools.cargo = lib.mkForce cfg.packages.cargo;
      pre-commit.tools.rustfmt = lib.mkForce cfg.packages.rustfmt;
      pre-commit.tools.clippy = lib.mkForce cfg.packages.clippy;
    })
    (lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      env.RUSTFLAGS = [ "-L framework=${config.env.DEVENV_PROFILE}/Library/Frameworks" ];
      env.RUSTDOCFLAGS = [ "-L framework=${config.env.DEVENV_PROFILE}/Library/Frameworks" ];
      env.CFLAGS = [ "-iframework ${config.env.DEVENV_PROFILE}/Library/Frameworks" ];
    })
    (lib.mkIf (lib.isAttrs cfg.toolchain) {
      languages.rust.packages = cfg.toolchain.withComponents cfg.components;
    })
    (lib.mkIf (lib.isString cfg.toolchain) (
      let
        fenix = inputs.fenix or (throw "To use languages.rust.version, you need to add the following to your devenv.yaml:\n\n${setup}");
        toolchain = fenix.packages.${pkgs.stdenv.system}.${cfg.toolchain} or (throw "languages.rust.version is set to ${cfg.version}, but should be one of: stable, beta or latest.");
      in
      {
        languages.rust.packages = [
          (toolchain.withComponents cfg.components)
        ];
      }
    ))
  ];
}
