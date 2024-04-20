{ config, lib, pkgs, ... }:


let
mullWgPythonEnv = pkgs.python3.withPackages (ps: with ps; [
  requests
]); in
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
        Environment = "PATH=/run/current-system/sw/bin/";
        ExecStartPre = [
          "-${pkgs.iproute2}/bin/ip link delete mullwg-veth0"
          "-${pkgs.iproute2}/bin/ip netns delete mull-wg-ns"
        ];
        ExecStart = "${pkgs.bash}/bin/bash /var/mull-wg/scripts/start_mull_ns.sh";
        ExecStop = [
          "-${pkgs.iproute2}/bin/ip link delete mullwg-veth0"
          "-${pkgs.iproute2}/bin/ip netns delete mull-wg-ns"
        ];
      };
    };

    systemd.user.services.mull-wg-serv = {
      description = "Mullvad server list update service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${mullWgPythonEnv}/bin/python3 /var/mull-wg/scripts/fetch_servers.py";
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
        PathChanged = "/var/mull-wg/loc";
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
