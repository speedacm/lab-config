{ config, lib, pkgs, inputs, ... }:

{
  # Imports
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
  ];

  # Boot
  boot = {
    # Kernel
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "mpt3sas" "usbhid" "sd_mod" "sr_mod" ];
    kernelParams = [ "panic=1" "boot.panic_on_fail" ];

    loader.efi.canTouchEfiVariables = true;
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 14;
    };
  };
  systemd.enableEmergencyMode = false;

  # Hardware
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = "performance";
  #services.fstrim.enable = true;

  # Networking
  time.timeZone = "America/Louisville";
  networking = {
    hostName = "WORKSTATION";
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
    useDHCP = false;
    interfaces.eno1.useDHCP = true;
    firewall.enable = true;
  };


  # Disks
  boot.cleanTmpDir = true;
  swapDevices = [{ device = "/swapfile"; size = 4096; }];

  # BTRFS Scrubbing
  services.btrfs.autoScrub = {
    fileSystems = [ "/nix" ]; # Crosses subpartition bounds
    enable = true;
    interval = "weekly";
  };

  # BTRFS De-duplicating
  services.beesd.filesystems = {
    system = {
      spec = "/nix";
      hashTableSizeMB = 1024;
      verbosity = "crit";
      extraOptions = [ "--loadavg-target" "10.0" ];
    };
  };

  # Partitioning
  disko.devices = import ./disko.nix;

  # Persistance
  users.mutableUsers = false;
  systemd.coredump.extraConfig = "Storage=none";
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log" # Keep system logs
      "/var/lib/docker" # Keep Docker junk
      "/var/lib/libvirt" # Keep KVM junk
      "/etc/nixos" # Not nuke my configuration
    ];
    files = [
      "/etc/machine-id" # Honestly no idea why we need this to be the same between boots
      "/etc/ssh/ssh_host_ed25519_key" # Not reset my host keys
      "/etc/ssh/ssh_host_ed25519_key.pub" # Not reset my host keys
      "/etc/ssh/ssh_host_rsa_key" # Not reset my host keys
      "/etc/ssh/ssh_host_rsa_key.pub" # Not reset my host keys
    ];
  };

  # Sops Key File Location
  sops.age.keyFile = "/persist/sops-key.txt";
}
