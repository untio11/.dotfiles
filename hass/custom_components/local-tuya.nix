{
  pkgs,
}:
# For local Tuya control. Add custom device config for my ceiling fan (Qazqa Joly).
(pkgs.home-assistant-custom-components.tuya_local.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    # Patch: 
    # Bewaar verstuurde DP-waardes direct in _cached_state zodat write-only DPs
    # (zoals DP 23 op de Qazqa Joly) na 5 seconden (_FAKE_IT_TIMEOUT) niet terugspringen:
    substituteInPlace $out/custom_components/tuya_local/device.py \
      --replace-fail \
        'pending_updates[key]["sent"] = True' \
        'pending_updates[key]["sent"] = True; self._cached_state[key] = properties[key]; [e.schedule_update_ha_state() for e in self._children]'
    cp ${pkgs.writeText "qazqa_joly_fanlight.yaml" ''
      name: Ceiling fan with light
      products:
        - id: agjbamgmrbcbazp7
          manufacturer: Qazqa
          model: Joly
      entities:
        - entity: fan
          dps:
            - id: 60
              type: boolean
              name: switch
            - id: 62
              type: integer
              name: speed
              range:
                min: 1
                max: 9
            - id: 63
              type: string
              name: direction
        - entity: light
          dps:
            - id: 20
              type: boolean
              name: switch
            - id: 22
              name: brightness
              type: integer
              range:
                min: 1
                max: 9
            - id: 23
              name: effect
              type: integer
              mapping:
                - dps_val: 2
                  value: "Warm white (2700K)"
                - dps_val: 0
                  value: "Neutral white (4500K)"
                - dps_val: 1
                  value: "Cool white (6500K)"
        - entity: select
          name: Color temperature
          icon: "mdi:theme-light-dark"
          dps:
            - id: 23
              type: integer
              name: option
              mapping:
                - dps_val: 2
                  value: "Warm white (2700K)"
                - dps_val: 0
                  value: "Neutral white (4500K)"
                - dps_val: 1
                  value: "Cool white (6500K)"
    ''} $out/custom_components/tuya_local/devices/qazqa_joly_fanlight.yaml
  '';
}))
