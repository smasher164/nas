{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./wifi.nix
    ];

  boot = {
    loader.grub.enable = false;
    loader.raspberryPi.enable = true;
    loader.raspberryPi.version = 4;
    loader.raspberryPi.firmwareConfig = ''
      dtparam=audio=on
      gpu_mem=192
    '';
    kernelPackages = pkgs.linuxPackages_rpi4;
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
      "console=ttyAMA0,115200"
      "console=tty1"
    ];
  };

  # Enable additional firmware (such as Wi-Fi drivers).
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "nixos";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    firewall = {
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ 41641 ];
      interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
  };

  time.timeZone = "America/New_York"; # Eastern Time

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable GPU.
  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    package = pkgs.mesa_drivers;
  };
  hardware.deviceTree = {
    kernelPackage = pkgs.linux_rpi4;
    overlays = [ "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d.dtbo" ];
  };
  services.xserver = {
    enable = false;
    videoDrivers = [ "modesetting" ];
  };

  # Define a user account.
  users.users.akhil = {
    isNormalUser = true;
    home = "/home/akhil";
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
  };

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # Permit empty password for sshd
  security.pam.services = {
    "sshd" = {
      allowNullPassword = true;
    };
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    vim
    raspberrypi-tools
    tailscale
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = false;
    permitRootLogin = "yes";
    challengeResponseAuthentication = false;
    extraConfig = ''
      PermitEmptyPasswords yes
    '';
  };

  # Enable Tailscale
  services.tailscale.enable = true;

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?
}