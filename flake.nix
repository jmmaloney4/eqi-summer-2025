{
  inputs = {
    ### Nixpkgs ###
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    ### Flake / Project Inputs ###
    flake-parts.url = "github:hercules-ci/flake-parts";

    flake-root.url = "github:srid/flake-root";

    mission-control.url = "github:Platonic-Systems/mission-control";

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
      # url = "/Users/jack/git/github.com/jmmaloney4/latex-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    flake-root,
    mission-control,
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
        mission-control.flakeModule
        pre-commit-hooks.flakeModule
        treefmt.flakeModule
        inputs.latex-utils.modules.latex-utils
      ];

      latex-utils.documents =
        [
          {
            name = "eqi-notes.pdf";
            src = ./.;
            inputFile = "main.tex";
          }
        ]
        ++ builtins.map (x: {
          name = "${nixpkgs.lib.removeSuffix ".tex" x}.pdf";
          src = ./.;
          inputFile = "./hw/${x}";
          extraTexPackages = [
            "metafont"
            "mfware"
          ];
        }) (builtins.filter (x: nixpkgs.lib.hasSuffix ".tex" x) (builtins.attrNames (builtins.readDir ./hw)));

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        lib,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          inputsFrom =
            [
              config.mission-control.devShell
              config.pre-commit.devShell
              config.treefmt.build.devShell
            ]
            ++ builtins.map (x: self'.packages.${x}) (builtins.attrNames self'.packages);
          buildInputs = with pkgs; [
            ltex-ls
          ];
        };

        mission-control.scripts = {
          fmt = {
            description = "Format the source tree";
            exec = config.treefmt.build.wrapper;
            category = "Dev Tools";
          };
        };

        pre-commit = {
          check.enable = true;
          settings.hooks.treefmt.enable = true;
          settings.settings.treefmt.package = config.treefmt.build.wrapper;
        };

        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          package = pkgs.treefmt;
          programs.alejandra.enable = true;
        };
        formatter = config.treefmt.build.wrapper;
      };
    });
}
