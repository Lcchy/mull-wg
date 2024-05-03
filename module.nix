{ config, lib, pkgs, ... }:
let 
  mull-wg = pkgs.callPackage ./default.nix {};
in 
{
 options.services.mull-wg = {
    enable = lib.mkEnableOption "Enable Mull WG service";
 };

 config = lib.mkIf config.services.mull-wg.enable {

      systemd.user.services.mull-wg-serv = {
      description = "Mullvad server list update service";
      wantedBy = [ "multi-user.target" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /var/tmp/mull-wg/servers"
          "${pkgs.coreutils}/bin/chown -R %u:users /var/tmp/mull-wg/servers"
        ];
        ExecStart = "${mull-wg}/bin/mull-wg-fetch-servers";
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
      wants = [ "mull-wg-connect.service" ];
      path = [ pkgs.gawk pkgs.iproute2 pkgs.wireguard-tools pkgs.iptables ];
      after = [ "mull-wg-serv.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStartPre = [
          "-${pkgs.iproute2}/bin/ip link delete mullwg-veth0"
          "-${pkgs.iproute2}/bin/ip netns delete mull-wg-ns"
        ];
        ExecStart = "${mull-wg}/bin/mull-wg-start-ns";
        ExecStop = [
          "-${pkgs.iproute2}/bin/ip link delete mullwg-veth0"
          "-${pkgs.iproute2}/bin/ip netns delete mull-wg-ns"
        ];
      };
    };

    systemd.services.mull-wg-connect = {
      description = "Setup WireGuard connection in netns";
      wantedBy = [ "multi-user.target" "network-online.target" ];
      after = [ "mull-wg-ns.service" ];
      requires = [ "mull-wg-ns.service" ];
      path = [ pkgs.gawk pkgs.iproute2 pkgs.wireguard-tools ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = "${mull-wg}/bin/mull-wg-connect";
      };
    };

    systemd.paths.mull-wg-watcher = {
      description = "WireGuard location config watcher";
      pathConfig = {
        PathChanged = "/var/tmp/mull-wg/loc";
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.mull-wg-watcher = {
      description = "WireGuard location config watcher";
      requires = [ "mull-wg-watcher.path" ];
      after = [ "mull-wg-watcher.path" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "systemctl restart mull-wg-connect.service";
      };
    };
 };
}
