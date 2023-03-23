{
  description = "SpeedACM Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, impermanence, sops-nix, disko, deploy-rs, ... }@inputs: {

    nixosConfigurations = {
      WORKSTATION = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Global Config + Modules
          ./config
          ./config/linux.nix
          ./modules
          ./hosts/WORKSTATION/configuration.nix

          # Specialized Hardware Configuration
          ./hosts/WORKSTATION/hardware-configuration.nix

          {
            modules = {
              ssh.enable = true;
              harden.enable = true;
              virtualisation.docker = true;
              zsh.enable = true;
            };
          }

          # User
          ./users
          ./users/speedacm
        ];
      };
    };

    deploy = {
      user = "root";
      remoteBuild = true;

      # deploy-rs#78
      magicRollback = false;
      sshOpts = [ "-t" ];
    
      nodes = {
        WORKSTATION = {
          hostname = "WORKSTATION";
          profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.WORKSTATION;
        };
      };
    };
  };
}
