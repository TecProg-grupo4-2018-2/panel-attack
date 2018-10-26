-- constants used in mainloop.lua
-- PLEASE READ: Constants previously defined there are being used by another files, so be careful

require("util")

CONFIG_TABLE = {character="lip", level=5, name="defaultname", master_volume=100, SFX_volume=100, music_volume=100, debug_mode=false, save_replays_publicly = "with my name", assets_dir=default_assets_dir}
X_STRING_CENTER = 300
Y_STRING_CENTER = 280

--- Up arrow key
MENU_KEY_UP = menu_key_func(
      {"up"},
      {"up"},
      true
    )

--- Down arrow key
MENU_KEY_DOWN = menu_key_func(
      {"down"},
      {"down"},
      true
    )

--- Left arrow key
MENU_KEY_LEFT = menu_key_func(
      {"left"},
      {"left"},
      true
    )

--- Right arrow key
MENU_KEY_RIGHT = menu_key_func(
      {"right"},
      {"right"},
      true
    )

--- Enter key
MENU_KEY_ENTER = menu_key_func(
      {
        "return",
        "kenter",
        "z"
      },
      {"swap1"},
      false
    )

--- Esc key
MENU_KEY_ESCAPE = menu_key_func(
      {
        "escape",
        "x"
      },
      {"swap2"},
      false
    )

MAP_1P_VS_YOURSELF = {
            {
                "level",
                "level",
                "level",
                "level",
                "level",
                "level",
                "ready"
            },
            {
                "random",
                "windy",
                "sherbet",
                "thiana",
                "ruby",
                "lip",
                "elias"
            },
            {
                "flare",
                "neris",
                "seren",
                "phoenix",
                "dragon",
                "thanatos",
                "cordelia"
            },
            {
                "lakitu",
                "bumpty",
                "poochy",
                "wiggler",
                "froggy",
                "blargg",
                "lungefish"
            },
            {
                "raphael",
                "yoshi",
                "hookbill",
                "navalpiranha",
                "kamek",
                "bowser",
                "leave"
            }
        }

MAP_RANKING =  {
            {
                "match type desired",-- this 4 lines are the only different thing in if else
                "match type desired",-- 2
                "match type desired",-- 3
                "match type desired",-- 4
                "level",
                "level",
                "ready"
            },
            {
                "random",
                "windy",
                "sherbet",
                "thiana",
                "ruby",
                "lip",
                "elias"
            },
            {
                "flare",
                "neris",
                "seren",
                "phoenix",
                "dragon",
                "thanatos",
                "cordelia"
            },
            {
                "lakitu",
                "bumpty",
                "poochy",
                "wiggler",
                "froggy",
                "blargg",
                "lungefish"
            },
            {
                "raphael",
                "yoshi",
                "hookbill",
                "navalpiranha",
                "kamek",
                "bowser",
                "leave"
            }
        }

MAP_DEFAULT = {
            {
                "level",
                "level",
                "level",
                "level", 
                "level",
                "level",
                "ready"
            },
            {
                "random",
                "windy",
                "sherbet",
                "thiana",
                "ruby",
                "lip",
                "elias"
            },
            {
                "flare",
                "neris",
                "seren",
                "phoenix",
                "dragon",
                "thanatos",
                "cordelia"
            },
            {
                "lakitu",
                "bumpty",
                "poochy",
                "wiggler",
                "froggy",
                "blargg",
                "lungefish"
            },
            {
                "raphael",
                "yoshi",
                "hookbill",
                "navalpiranha",
                "kamek",
                "bowser",
                "leave"
            }
        }