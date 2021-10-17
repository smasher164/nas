{ config, pkgs, lib, ... }:

let in {
  imports =
[
  "${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz" }/raspberry-pi/4"
        ./hardware-configuration.nix
  ./wifi.nix
];

  boot.supportedFilesystems = [ "zfs" ];

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

  environment.systemPackages = with pkgs; [ vim ];

  services.openssh = {
    enable = true;
    openFirewall = false;
    permitRootLogin = "yes";
    challengeResponseAuthentication = false;
  };

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

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
  };

  services.plex = {
    enable = true;
    openFirewall = true;
  };
  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.akhil = {
    isNormalUser = true;
    home = "/home/akhil";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9RwUBWWGe67XSDenCkGBjO/GUSFNYgq1EMPAcoQkcf1Dl8Q5Mf84JBUwpbdIZdR1AayBg+Af5E7c+ywtxrq7tMaTQhomVSyMcJteWrTBUJTfm1wSh5yxSZaGv+uDHbuRmJ3CknCLD7A/CY+/hjO8wMU1Em4oG2phm4gSSV1GKifD/3ExrigJHBpArNwR27RBUGq49/1BQbi+1mgPAI4k7Cqvpz5+FMkHiPHfYI1nt1eSvVGJpIlhbec9WraAH5nu1kT+ZAOoQstEAfkA5j52o2/uls/yC5MrrWTVRzRjRL7w8aWcGkdSORaeTkvBMkM8BtTDQ2RgSbBkHt8NKYRwh akhil@Akhils-MacBook-Air.local" ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  services.xserver.enable = false;

  hardware.pulseaudio.enable = true;
}
