from yeelight import Bulb
from os import system
import json
import sys

if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) < 2:
        print("Please provide an action and an item")
        exit

    action = sys.argv[1]
    ip = sys.argv[2]
    bulb = Bulb(ip)
    try:
        match action:
            case "toggle":
                bulb.toggle()
            case "on":
                bulb.turn_on()
            case "off":
                bulb.turn_off()
            case "set-state":
                state:dict = json.loads(" ".join(args[3:]))
                fields = state["used-fields"]
                if fields is None or len(fields) == 0:
                    fields = state.keys()
                if "brightness" in fields:
                    bulb.set_brightness(state["brightness"])
                if "color" in fields:
                    color = state["color"]
                    r = int(color["r"]*255)
                    g = int(color["g"]*255)
                    b = int(color["b"]*255)
                    bulb.set_rgb(r,g,b)
                if "enabled" in fields:
                    if fields["enabled"]:
                        bulb.turn_on()
                    else:
                        bulb.turn_off()
            case "get-state":
                pass
        state = bulb.get_properties()
        print(json.dumps({"state":{
            "enabled": True if state["power"] == "on" else False,
            "brightness": int(state["bright"]),
            "color": state["rgb"],
            "is-error": False
        },"error": False}))
    except:
        print(json.dumps({"error": True}))
