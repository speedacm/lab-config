{ ... }:
{
  disk = {
    main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "ESP";
            type = "partition";
            start = "1MiB";
            end = "1GiB";
            fs-type = "fat32";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "Linux";
            type = "partition";
            start = "1GiB";
            end = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              subvolumes = {
                "/nix" = {
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/persist" = {
                  mountOptions = [ "compress=zstd" ];
                };
                "/ACM" = {
                  mountOptions = [ "compress=zstd" ];
                };
                "/tmp" = {
                  # /tmp gets cleared on boot
                  mountOptions = [ "noatime" ];
                };
              };
            };
          }
        ];
      };
    };
  };
  nodev = {
    "/" = {
      # May need to replace with btrfs snapshots if I use more than 8G?
      fsType = "tmpfs";
      mountOptions = [ "defaults" "size=4G" "mode=755" ];
    };
  };
}
