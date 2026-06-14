{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./wifi.nix
      ./hass-secrets.nix
    ];

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Pinned to the release this system was effectively running before the
  # 24.11 -> 26.05 upgrade, to preserve stateful service defaults.
  system.stateVersion = "24.11";

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

  nix = {
    # package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.systemPackages = with pkgs; [ vim ];
  
  programs.firefox.enable = true;
  programs.tmux.enable = true;

  # services.matrix-conduit = {
  #   enable = true;
  #   settings.global.server_name = "test.server";
  # };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "yes";
      KbdInteractiveAuthentication = false;
      X11Forwarding = true;
    };
  };

  services.samba = {
    enable = true;
    nmbd.enable = false;
    winbindd.enable = false;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "nas";
        "disable netbios" = "yes";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "min protocol" = "SMB2";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
      };
      backup = {
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
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
  };

  services.plex = {
    enable = true;
    openFirewall = true;
  };
  # Let Plex reach the Pi's hardware video codecs (/dev/video*) and GPU (/dev/dri) for HW transcode.
  users.users.plex.extraGroups = [ "video" "render" ];

  # Disk hygiene — the 24.11->26.05 upgrade nearly filled the 30GB SD; keep it bounded.
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; };
  services.journald.extraConfig = "SystemMaxUse=200M";
  boot.loader.generic-extlinux-compatible.configurationLimit = 20;

  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.akhil = {
    isNormalUser = true;
    home = "/home/akhil";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICppuWEIAcBtHCFJf9v0GZGV3o/M3KK602p0FC2ApHLK akhilindurti@Akhils-MBP.localdomain"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxcVE5/g2+DF0L0ImkOvIwzwLd3UnhqugShvMWRjIcQ3chUHB/e4SlMiSkqbdgrj4U2GIdYj5lgqnuV2TQgkdiaZFoZN0C7YTTs8rNnUMlivkLdPr+Jh1htYAjZBMsnCrVKskLIrSjkeDYXFWocQsHzaUIS+FbQw0ikfox4mbj32/YassNkbTMtQ5EMJGBDny5iEuXIMM78plNgSMQVEEo5KPQw+J6EERdDCJlkDX7gQMTJ7Cm0UVM+qjo+OmQMtg/Wjv1LZhJvzqZVz1/nmebrYfPRwJclPNBCDx/Bb9GIkBc6nVbWf3XVhCd1LMNwcxQVvSIcKcorTYWx5TzbJEWMPIB3Ry7zjWvXiqYh3iYQCTHAa4x+Ul0/J5PffoUOCILG5XGNRhyXx/lg+4h3F22mRfYU1rV18MPuSuGHE4zoKixBq83GGembIslxepRu3qnkVUW8Ep8QTLtas3G16F3ek7kO9+fPvJnKnqla3gKcTty/yplnARvjRHydgnRF90= akhil@akhilframework"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  services.xserver.enable = false;

  services.pulseaudio.enable = true;

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    package = (pkgs.home-assistant.override {
      extraPackages = py: with py; [
        pyipp
        pychromecast
        aioshelly
        aiohttp-cors
        aiodiscover
        sqlalchemy
        plexapi
      ];
    }).overrideAttrs (_: {
      doInstallCheck = false;
    });
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "America/New_York";
        auth_providers = [
          { type = "trusted_networks";
            trusted_networks = ["0.0.0.0/0"];
            allow_bypass_login = true;
          }
          { type = "homeassistant"; }
        ];
      };
      default_config = {};
      met = {};
      http = {};
    };
    lovelaceConfig = {
      title = "Home";
      views = [
        {
          path = "default_view";
          title = "Home";
          cards = [
            {
              type = "light";
              entity = "light.shellydimmer2_e8db84d4833d";
              name = "Akhil's Bedroom Light";
            }
            {
              type = "sensor";
              entity = "sensor.shellydimmer2_e8db84d4833d_device_temperature";
              name = "Shelly Temperature";
              graph = "line";
            }
            {
              type = "weather-forecast";
              entity = "weather.home";
              show_forecast = true;
            }
          ];
        }
      ];
    };
  };
}
