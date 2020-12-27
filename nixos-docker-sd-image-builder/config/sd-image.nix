{ lib, ... }: {
  imports = [
    ## Uncomment at most one of the following to select the target system:
    # ./generic-aarch64 # (note: this is the same as 'rpi3')
    ./rpi4
    # ./rpi3
  ];

  # The installer starts with a "nixos" user to allow installation, so add the SSH key to
  # that user. Note that the key is, at the time of writing, put in `/etc/ssh/authorized_keys.d`
  users.extraUsers.nixos.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9RwUBWWGe67XSDenCkGBjO/GUSFNYgq1EMPAcoQkcf1Dl8Q5Mf84JBUwpbdIZdR1AayBg+Af5E7c+ywtxrq7tMaTQhomVSyMcJteWrTBUJTfm1wSh5yxSZaGv+uDHbuRmJ3CknCLD7A/CY+/hjO8wMU1Em4oG2phm4gSSV1GKifD/3ExrigJHBpArNwR27RBUGq49/1BQbi+1mgPAI4k7Cqvpz5+FMkHiPHfYI1nt1eSvVGJpIlhbec9WraAH5nu1kT+ZAOoQstEAfkA5j52o2/uls/yC5MrrWTVRzRjRL7w8aWcGkdSORaeTkvBMkM8BtTDQ2RgSbBkHt8NKYRwh akhil@Akhils-MacBook-Air.local"
  ];

  # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low
  # on space.
  sdImage.compressImage = false;

  # OpenSSH is forced to have an empty `wantedBy` on the installer system[1], this won't allow it
  # to be automatically started. Override it with the normal value.
  # [1] https://github.com/NixOS/nixpkgs/blob/9e5aa25/nixos/modules/profiles/installation-device.nix#L76
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # Wireless networking (1). You might want to enable this if your Pi is not attached via Ethernet.
  #networking.wireless = {
  #  enable = true;
  #  interfaces = [ "wlan0" ];
  #  networks = {
  #    "SSID" = {
  #      psk = "password";
  #    };
  #  };
  #};

  # Wireless networking (2). Enables `wpa_supplicant` on boot.
  #systemd.services.wpa_supplicant.wantedBy = lib.mkOverride 10 [ "default.target" ];

  # NTP time sync.
  #services.timesyncd.enable = true;
}
