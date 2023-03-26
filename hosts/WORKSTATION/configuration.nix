{ pkgs, config, ... }:
{
  # Cloudflared
  sops.secrets.cloudflared-creds.owner = "cloudflared";
  sops.secrets.cloudflared-creds.group = "cloudflared";
  services.cloudflared = {
    enable = true;
    tunnels = {
      "cd216931-03fb-4406-9bc6-51fa9aa4afd9" = {
        credentialsFile = "${config.sops.secrets.cloudflared-creds.path}";
        ingress = {
          "snipe.speedacm.org" = "http://10.172.192.2:80";
        };
        default = "http_status:404";
      };
    };
  };

  # Snipe-IT
  sops.secrets.snipe-appkey.mode = "700"; # Secret needs to be referenced to exist
  systemd.tmpfiles.rules = [ # Just to create the directories
    "d /ACM/snipeit/snipeit 700 root root -"
    "d /ACM/snipeit/mysql 700 root root -"
  ];
  containers.snipe-it = {
    ephemeral = true;
    autoStart = true;
    privateNetwork = true;
    timeoutStartSec = "infinity"; # First startup takes a long time
    hostAddress = "10.172.192.1"; # Random Goofy IP
    localAddress = "10.172.192.2";
    bindMounts = {
      "/var/lib/snipe-it" = {
        hostPath = "/ACM/snipeit/snipeit";
        isReadOnly = false;
      };
      "/var/lib/mysql" = {
        hostPath = "/ACM/snipeit/mysql";
        isReadOnly = false;
      };
      "/snipe-appkey" = {
        hostPath = "/run/secrets/snipe-appkey";
        isReadOnly = false;
      };
    };
    config = { pkgs, config, ...}: {
      systemd.tmpfiles.rules = [
        "d /var/lib/snipe-it 700 snipeit snipeit -"
        "d /var/lib/mysql 700 mysql mysql -"
        "f /snipe-appkey 700 snipeit snipeit -"
      ];
      services.snipe-it = {
        enable = true;
        database.createLocally = true;
        hostName = "snipe.speedacm.org";
        appKeyFile = "/snipe-appkey";
      };
      networking.firewall.allowedTCPPorts = [ 80 ];
    };
  };

  # State
  system.stateVersion = "23.05";
}
