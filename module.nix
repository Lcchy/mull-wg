{ config, lib, pkgs, ... }:

{
 options.services.mull-wg = {
    enable = lib.mkEnableOption "Enable Mull WG service";
 };

 config = lib.mkIf config.services.mull-wg.enable {
    systemd.services.mull-wg-ns = {
      description = "WireGuard namespace service";
      wantedBy = [ "multi-user.target" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStartPre = [
          "-ip link delete mullwg-veth0"
          "-ip netns delete mull-wg-ns"
        ];
        ExecStart = "bash %h/.config/mull-wg/scripts/start_mull_ns.sh";
        ExecStop = [
          "-ip link delete mullwg-veth0"
          "-ip netns delete mull-wg-ns"
        ];
      };
    };

    systemd.user.services.mull-wg-serv = {
      description = "Mullvad server list update service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "python3 %h/.config/mull-wg/scripts/fetch_servers.py";
      };
    };
    systemd.user.timers.mull-wg-serv = {
      description = "Mullvad server list update service";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "mull-wg-serv.service";
      };
    };

    systemd.paths.mull-wg-watcher = {
      description = "WireGuard location config watcher";
      pathConfig = {
        PathChanged = "%h/.config/mull-wg/loc";
      };
      wantedBy = [ "multi-user.target" "network-online.target" ];
    };
    systemd.services.mull-wg-watcher = {
      description = "WireGuard location config watcher";
      wantedBy = [ "multi-user.target" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "systemctl restart mull-wg-ns.service";
      };
    };
 };
}
