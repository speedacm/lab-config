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
          "snipe.speedacm.org" = "http://localhost:80";
        };
        default = "http_status:404";
      };
    };
  };

  # Snipe-IT
  sops.secrets.snipe-appkey.owner = "snipeit";
  sops.secrets.snipe-appkey.group = "snipeit";
  services.snipe-it = {
    enable = true;
    database.createLocally = true;
    hostName = "snipe.speedacm.org";
    appKeyFile = "${config.sops.secrets.snipe-appkey.path}";
  };

  # State
  system.stateVersion = "22.11";
}
