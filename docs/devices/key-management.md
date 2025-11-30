## Key Management

### Key Storage

Keys are managed **per house**, whereas users stay the same between houses on the same instance of a server.
Keys are registered in a `<house>/keys.json` file that follows this general format :
```json
[
    {
      "key": "<key-hash>",
      "name": "Primary Key",
      "access-scope": [
        "<scope-identifier-1>",
        "<scope-identifier-2"
      ]
    }
  ]
```
The `key` field contains the sha256 hash of the actual key, so the true key is never stored in plain text on the server. Please note
that by consequence no recover process is possible server-side if a key is lost.


Each key has a list of scopes that are attached to it. These scopes define what a user is allowed
to do on the server. For instance the key :
```json
[
  {
    "key": "936a185caaa266bb9cbe981e9e05cb78cd732b0b3280eb944412bb6f8f8f07af",
    "name": "Light Control",
    "access-scope": [
      "home-control-devices"
    ]
  }
]
```
would allow the user sending it to control and read the status of all the devices in a house.

### Scopes
Scopes are a way to finely distribute permissions for keys. They can be arbitrary (like the `master-control-devices` scope for instance)
or dynamically generated.
Dynamic scopes are used to grant access to specific devices or rooms and follow a general format.

All permissions are ***umbrellas***, which means that permission at the scale of the house override those defined by a room or a device.
So the order of impact is : **Home** > **Room** > **Device**.

#### General Home Permissions
| Permission String      | Allows the user to :                                                                |
|------------------------|-------------------------------------------------------------------------------------|
| `home-query`           | query general information about the house                                           |
| `home-deep-query`      | query all the information inside a house (general, room, devices)                   |
| `home-control`         | query and edit general information about the house                                  |
| `home-query-rooms`     | list the rooms and their attributes in a house                                      |
| `home-control-rooms`   | edit the rooms and their attributes in a house                                      |
| `home-query-devices`   | query the state of all devices of a house                                           |
| `home-control-devices` | control and query every device of a house                                           |
| `home-manage`          | grant all the previous permissions, functionally makes them an "admin" of the house |

#### Room Access
| Permission String                | Allows the user to :                                 |
|----------------------------------|------------------------------------------------------|
| `room-thumbnail:<room-id>`       | only see that the room exists, but not what's inside |
| `room-query:<room-id>`           | see a room and query its content                     |
| `room-manage:<room-id>`          | edit a room                                          |
| `room-control-devices:<room-id>` | use all the devices of a room                        |
| `room-query-devices:<room-id>`   | query the devices of a room                          |

#### Device Control
| Permission String                   | Allows the user to :                                                    |
|-------------------------------------|-------------------------------------------------------------------------|
| `device-type-control:<device-type>` | control the state of all devices of a specific **type (and sub-types)** |
| `device-type-query:<device-type>`   | query the state of all devices of a specific **type (and sub-types)**   |
| `device-thumbnail:<device-id>`      | only see that the device exists, but not its state                      |
| `device-control:<device-id>`        | control the state of a device                                           |
| `device-query:<device-id>`          | query the state of a device                                             |
