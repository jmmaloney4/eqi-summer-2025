{
  inputs = {
    ### Nixpkgs ###
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    ### Flake / Project Inputs ###
    flake-parts.url = "github:hercules-ci/flake-parts";

    flake-root.url = "github:srid/flake-root";

    just-flake.url = "github:juspay/just-flake";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.flake-utils.inputs.systems.follows = "systems";
    };

    systems.url = "github:nix-systems/default";

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    latex-utils = {
      url = "github:jmmaloney4/latex-utils";
      # url = "/home/jack/git/github.com/jmmaloney4/latex-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    flake-root,
    just-flake,
    pre-commit-hooks,
    systems,
    treefmt,
    latex-utils,
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      withSystem,
      inputs,
      ...
    }: {
      systems = import systems;
      imports = [
        flake-root.flakeModule
        just-flake.flakeModule
        pre-commit-hooks.flakeModule
        treefmt.flakeModule
        latex-utils.flakeModule
      ];

      latex-utils = {
        documents =
          [
            {
              name = "eqi-notes.pdf";
              src = ./.;
              inputFile = "main.tex";
            }
          ]
          ++ builtins.map (x: {
            name = "${inputs.nixpkgs.lib.removeSuffix ".tex" x}.pdf";
            src = ./.;
            inputFile = "./hw/${x}";
          }) (builtins.filter (x: inputs.nixpkgs.lib.hasSuffix ".tex" x) (builtins.attrNames (builtins.readDir ./hw)));

        extraTexPackages = ["braket"];
      };
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        lib,
        ...
      }: {
        # Compose our development shell with latex-utils integration
        devShells.default = pkgs.mkShell {
          inputsFrom = [
            config.latex-utils.vscodeShell
            config.just-flake.outputs.devShell
            config.pre-commit.devShell
            config.treefmt.build.devShell
          ];
          
          # Add comma alias for backwards compatibility
          shellHook = ''
            # Set up comma alias for just
            alias ','='just'
            echo ""
            echo "⚡ Alias ',' set to 'just' ✨"
            echo ""
          '';
        };

        just-flake.features = {
          treefmt.enable = true;  # Built-in formatting support
        };

        pre-commit = {
          check.enable = true;
          settings.hooks.treefmt.enable = true;
          settings.hooks.treefmt.package = config.treefmt.build.wrapper;
        };

        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          package = pkgs.treefmt;
          programs.alejandra.enable = true;
          programs.latexindent = {
            enable = true;
            package = self'.packages.latexindent;
          };
        };
        formatter = config.treefmt.build.wrapper;
      };
    });
}
