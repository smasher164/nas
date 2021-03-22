{ config, lib, ... }:

let
  # Last known working commit where everything works.
  pkgs = import
    (builtins.fetchTarball {
      name = "nixos-last-working";
      url = "https://github.com/NixOS/nixpkgs/archive/2f47650c2f28d87f86ab807b8a339c684d91ec56.tar.gz";
      sha256 = "17akl75x28rzq97gaad32flswdsp150nfsg7h909kda721zql71a";
    })
    { };

  # Latest commit on nixos-unstable.
  latest = import
    (builtins.fetchTarball {
      name = "nixos-latest";
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      sha256 = "1fmwkb2wjfrpx8fis4x457vslam0x8vqlpfwqii6p9vm33dyxhzk";
    })
    { };
in
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
    supportedFilesystems = [ "zfs" ];
  };

  # Enable additional firmware (such as Wi-Fi drivers).
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostId = "6459f901"; # Hex form of tailscale IP
    hostName = "nas";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    firewall = {
      interfaces.tailscale0.allowedTCPPorts = [ 22 80 443 445 ];
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

  # List packages installed in system profile.
  environment.systemPackages = [
    latest.vim
    latest.libraspberrypi
    latest.tailscale
    latest.openssl
    latest.usbutils
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

  # Enable Samba.
  services.samba = {
    enable = true;
    enableNmbd = false;
    enableWinbindd = false;
    extraConfig = ''
      workgroup = WORKGROUP
      server string = nas
      disable netbios = yes
      guest account = nobody
      map to guest = bad user
      min protocol = SMB2
      vfs objects = catia fruit streams_xattr
      fruit:metadata = stream
    '';
    shares.backup = {
      path = "/nas/backup";
      browseable = "yes";
      "writeable" = "yes";
      "guest ok" = "yes";
      "guest only" = "yes";
      "force user" = "akhil";
      "vfs objects" = "catia fruit streams_xattr";
      "fruit:time machine" = "yes";
    };
  };

  # Enable Tailscale
  services.tailscale.enable = true;

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  # ZFS
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?
}