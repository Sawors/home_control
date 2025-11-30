## Adapter Communication Protocol

All adapters must follow the following structure :


```
adapter-executable... <action> [data]
```

and be able to handle these actions :
- `toggle`
  - toggle the light
- `on`
  - turn the light on
- `off`
  - turn the light off
- `set-state <LightState json>`
  - set up the light in a specific LightState
- `get-state`
  - print the current light state

All actions must print only a json containing the following response :
```json
{
  "state": {...updated LightState json},
  "error": false if it has succeeded or true if it has failed
}
```

For the `set-state` action, the adapter should implement the `"used-fields"`
field in the LightState json given in order to update the light only on its necessary
attributes.