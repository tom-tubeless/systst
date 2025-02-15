{ config, pkgs, ... }:

{

  imports = [
    ./services/nixos-auto-update.nix
  ];

  fileSystems."/" = { options = [ "noatime" "nodiratime" ]; };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        version = 2;
        efiSupport = true;
        enableCryptodisk = true;
        device = "nodev";
      };
    };
    initrd.luks.devices = {
      crypt = {
        device = "/dev/sda2";
        preLVM = true;
      };
    };
  };

  networking = {
    useDHCP = false;
    interfaces.enp0s3.useDHCP = true; # Add correct network interface name to find out run "ip a"
    hostName = "nixtst"; # Define your hostname.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 2022 ];
      allowedUDPPorts = [ 53 ];
      allowPing = true;
    };
  };

  time.timeZone = "Europe/Berlin";

  i18n = {
    defaultLocale = "de_DE.UTF-8";
    supportedLocales = [ "de_DE.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      powerline-fonts
      nerdfonts
    ];
  };

  services = {
    nixos-auto-update.enable = true;
    logrotate = {
      enable = true;
      extraConfig = ''
        compress
        create
        daily
        dateext
        delaycompress
        missingok
        notifempty
        rotate 31
      '';
    };
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      forwardX11 = true;
      ports = [ 2022 ];
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };

  users = {
    mutableUsers = false;
    users.nixu = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
      # mkpasswd -m sha-512 password
      hashedPassword = "$6$mUf6Czttpe9LEwhV$Q8KYWiWyjdKVh4msFQWifpAWltINjkPPOmTn9Q6RbZBEc4OEfQ07LDThm4Ov5Lieikl0eXi3KY8jEX1Jpt.oH0";
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEibeHYufNMwEcpXtSHXTbEvmW8Mla1v1W8YS/gacfbA tom1@xps-15" ];
      packages = with pkgs; [
        python39Full
      ];
    };
  };

  programs = {
    ssh.startAgent = false;
    vim.defaultEditor = true;
    fish.enable = true;
    nano.nanorc = ''
      unset backup
      set nonewlines
      set nowrap
      set tabstospaces
      set tabsize 4
      set constantshow
    '';
  };

  environment = {
    systemPackages = with pkgs; [
      git
      gh
      inotify-tools
      nodejs
      binutils
      gnutls
      wget
      curl
      bind
      mkpasswd
      cachix
    ];

    shellAliases = {
      cp = "cp -i";
      diff = "diff --color=auto";
      dmesg = "dmesg --color=always | lless";
      egrep = "egrep --color=auto";
      fgrep = "fgrep --color=auto";
      grep = "grep --color=auto";
      mv = "mv -i";
      ping = "ping -c3";
      ps = "ps -ef";
      sudo = "sudo -i";
      vdir = "vdir --color=auto";
    };
  };

  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnfree = true;
    };
  };

  nix = {
    package = pkgs.nixFlakes;
    useSandbox = true;
    autoOptimiseStore = true;
    readOnlyStore = false;
    allowedUsers = [ "@wheel" ];
    trustedUsers = [ "@wheel" ];
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d --max-freed $((64 * 1024**3))";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
    /*    binaryCaches = [
      "https://matrix.cachix.org"
      ];
      binaryCachePublicKeys = [
      "matrix.cachix.org-1:h2ZM1LtvJBQhCb7a2Z/UpO8PKKIUlIvifvrFKfnHkro="
      ];*/
  };
  system = {
    stateVersion = "21.05"; # Did you read the comment?
    autoUpgrade = {
      enable = true;
      allowReboot = true;
      flake = "github:mudrii/systst";
      flags = [
        "--recreate-lock-file"
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      dates = "daily";
    };
  };
}
