# Simple Parser Example

A simple parser example reading an (logitech mouse) profile as kdl and
creating struct in odin

## Mouse Profile

The parser reads a kdl file with a mouse profile and writes a simple struct.
Thats all it does!

## Background

I wanted to learn odin and search for a simple project and had interrest in learning KDL. After
finding the CKDL wrapper on github, I search for a small project.

I used ratbagctl to configure my mouse with a profile. The GTK-UI Piper did not work for me, but
ratbagctl did work very well. So i wrote a simple fish shell script reading a simple json file
containing profiles.

```json
[
  {
    "name": "Dota",
    "profileNumber": 1,
    "settings": [
      [ "rate", "set", "1000" ],
      [ "button", "3", "action", "set", "key", "KEY_GRAVE" ],
      [ "button", "4", "action", "set", "button", "3" ],
      [ "button", "5", "action", "set", "key", "KEY_1" ],
      [ "button", "9", "action", "set", "macro", "KEY_A" ],
      [ "button", "10", "action", "set", "macro", "KEY_M" ],
      [ "resolution", "0", "disabled", "set" ],
      [ "resolution", "1", "disabled", "set" ],
      [ "resolution", "default", "set", "3" ],
      [ "resolution", "active", "set", "3" ]
    ]
  }
]
```

From this simple structure holding only parameters for `ratbagctl` it evolved to an
simple kdl file describing a mouse profile:

```kdl
// First KDL version of a profile
Profile 1  active=#true {
   Name "Dota2"
   Rate 1000
   Button 3 {
     Key "Key_Grave"
   }
   Button 4 {
     Button 3
   }
   Button 5 {
     Key "Key_1"
   }
   Button 9 {
     Macro "KEY_A"
   }
   Button 10 {
     Macro "KEY_M"
   }
   Led 1 {
     Mode "on"
     Color 0x16FFFFFF
     Duration 10
     Brightness 10
   }
   Resolution 3 enable=#true active=#true {
     DPI 10
   }
   Resolution 0 enable=#false
   Resolution 1 enable=#false
}
```
