{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-Samsung_SSD_990_1TB_S819NT0L900834E";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "zroot";
          };
        };
      };
    };
  };
  disko.devices.zpool.zroot = {
    type = "zpool";
    options = {
      ashift = "12";
      autotrim = "on";
    };
    rootFsOptions = {
      compression = "zstd";
      atime = "off";
      xattr = "sa";
      acltype = "posixacl";
      mountpoint = "none";
    };
    datasets = {
      "local" = {
        type = "zfs_fs";
        options.mountpoint = "none";
      };
      "local/root" = {
        type = "zfs_fs";
        mountpoint = "/";
        options.mountpoint = "legacy";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/local/root@blank$' || zfs snapshot zroot/local/root@blank";
      };
      "local/nix" = {
        type = "zfs_fs";
        mountpoint = "/nix";
        options.mountpoint = "legacy";
      };
      "safe" = {
        type = "zfs_fs";
        options.mountpoint = "none";
      };
      "safe/persist" = {
        type = "zfs_fs";
        mountpoint = "/persist";
        options.mountpoint = "legacy";
      };
      "reserved" = {
        type = "zfs_fs";
        options = {
          mountpoint = "none";
          canmount = "off";
          reservation = "20G";
        };
      };
    };
  };
}
