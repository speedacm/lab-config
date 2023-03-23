{ pkgs, config, ... }:
let
  keys = builtins.fetchurl {
    url = "https://github.com/LegitMagic.keys";
    sha256 = "0vlzvfif2ccqwjjz5sn70wbgj7i7vmc3ga62s2idlws0hha9j6rl";
  };
in
{
  sops.defaultSopsFile = ../../secrets/speedacm.yaml;
  sops.secrets.speedacm-hashed-password.neededForUsers = true;
  users.groups.speedacm.gid = 1000;
  users.users.speedacm = {
    uid = 1000;
    group = "speedacm";
    shell = pkgs.zsh;
    isNormalUser = true;
    passwordFile = config.sops.secrets.speedacm-hashed-password.path;
    openssh.authorizedKeys.keyFiles = [ keys ];
    extraGroups = [ "wheel" ];
  };
}
