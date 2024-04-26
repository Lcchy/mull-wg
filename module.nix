{ config, lib, pkgs, ... }:

{
 options.services.mull-wg = {
    enable = lib.mkEnableOption "Enable Mull WG service";
 };

 config = lib.mkIf config.services.mull-wg.enable {

      systemd.user.services.mull-wg-serv = {
      description = "Mullvad server list update service";
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = [
          "mkdir -p /var/tmp/mull-wg/servers"
          "chown -R %u:users /var/tmp/mull-wg/servers"
        ];
        ExecStart = "${pkgs.mull-wg-fetch-servers}";
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

    systemd.services.mull-wg-ns = {
      description = "WireGuard namespace service";
      wantedBy = [ "multi-user.target" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStartPre = [
          "-${pkgs.iproute2}/bin/ip link delete mullwg-veth0"
          "-${pkgs.iproute2}/bin/ip netns delete mull-wg-ns"
        ];
        ExecStart = "${pkgs.mull-wg-start-ns}";
        ExecStop = [
          "-${pkgs.iproute2}/bin/ip link delete mullwg-veth0"
          "-${pkgs.iproute2}/bin/ip netns delete mull-wg-ns"
        ];
      };
    };

    systemd.paths.mull-wg-watcher = {
      description = "WireGuard location config watcher";
      pathConfig = {
        PathChanged = "/var//tmp/mull-wg/loc";
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
