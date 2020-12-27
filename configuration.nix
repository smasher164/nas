# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

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
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9RwUBWWGe67XSDenCkGBjO/GUSFNYgq1EMPAcoQkcf1Dl8Q5Mf84JBUwpbdIZdR1AayBg+Af5E7c+ywtxrq7tMaTQhomVSyMcJteWrTBUJTfm1wSh5yxSZaGv+uDHbuRmJ3CknCLD7A/CY+/hjO8wMU1Em4oG2phm4gSSV1GKifD/3ExrigJHBpArNwR27RBUGq49/1BQbi+1mgPAI4k7Cqvpz5+FMkHiPHfYI1nt1eSvVGJpIlhbec9WraAH5nu1kT+ZAOoQstEAfkA5j52o2/uls/yC5MrrWTVRzRjRL7w8aWcGkdSORaeTkvBMkM8BtTDQ2RgSbBkHt8NKYRwh akhil@Akhils-MacBook-Air.local" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    raspberrypi-tools
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?
}