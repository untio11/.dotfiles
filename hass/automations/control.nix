let
  # Helper voor het koppelen van een Aqara H1 Double Rocker (in decoupled + multi-click mode)
  # aan een Qazqa Joly plafondventilator met lamp.
  mkFanLightSwitchAutomation =
    {
      id,
      alias,
      switchFriendlyName,
      lightEntity,
      fanEntity,
      colorTempSelectEntity,
    }:
    {
      inherit id alias;
      mode = "queued";
      max = 5;
      triggers = [
        {
          trigger = "mqtt";
          topic = "zigbee2mqtt/${switchFriendlyName}/action";
        }
      ];
      actions = [
        {
          choose = [
            # 1x rechts: Toggle lamp
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.payload == 'single_right' }}";
                }
              ];
              sequence = [
                {
                  action = "light.toggle";
                  target.entity_id = lightEntity;
                }
              ];
            }

            # 1x links: Toggle ventilator
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.payload == 'single_left' }}";
                }
              ];
              sequence = [
                {
                  action = "fan.toggle";
                  target.entity_id = fanEntity;
                }
              ];
            }

            # 2x rechts: Volgende kleurtemperatuur (Warm -> Neutraal -> Koud -> Warm)
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.payload == 'double_right' }}";
                }
              ];
              sequence = [
                {
                  action = "select.select_next";
                  target.entity_id = colorTempSelectEntity;
                  data.cycle = true;
                }
              ];
            }

            # 2x links: Draairichting ventilator omdraaien (forward <-> reverse)
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.payload == 'double_left' }}";
                }
              ];
              sequence = [
                {
                  action = "fan.set_direction";
                  target.entity_id = fanEntity;
                  data.direction = "{{ 'forward' if state_attr('${fanEntity}', 'direction') == 'reverse' else 'reverse' }}";
                }
              ];
            }

            # 1x beide knoppen tegelijk: Toggle zowel lamp als ventilator
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.payload == 'single_both' }}";
                }
              ];
              sequence = [
                {
                  action = "light.toggle";
                  target.entity_id = lightEntity;
                }
                {
                  action = "fan.toggle";
                  target.entity_id = fanEntity;
                }
              ];
            }
          ];
        }
      ];
    };
in
[
  (mkFanLightSwitchAutomation {
    id = "lounge_switch_ceiling_fan";
    alias = "Lounge Switch - Ceiling Fan & Light";
    # Friendly name van de Aqara H1 schakelaar in Zigbee2MQTT:
    switchFriendlyName = "Lounge Ceiling Fan Switch";
    lightEntity = "light.lounge_ceiling_fan";
    fanEntity = "fan.lounge_ceiling_fan";
    colorTempSelectEntity = "select.lounge_ceiling_fan_color_temperature";
  })
]
