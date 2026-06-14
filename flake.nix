{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
  };
  outputs = inputs@{ self, nixpkgs, nixos-hardware }: {
    nixosConfigurations.nas = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        nixos-hardware.nixosModules.raspberry-pi-4
      ];
      specialArgs.inputs = inputs;
    };
  };
}
