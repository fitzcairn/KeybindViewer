--
-- Define Global Tables
-- 
-- Lays out the namespace use for this addon.  Everything else is either in
-- one of these tables or local.
--

-- Turn on/off debug printouts
local DEBUG = false


--
-- Global Tables
--

-- Config values, saved per-user
KV_Vals = {

}

-- Namespace table
KV = {
   -- Constants
   Constants       = {
      MAX_SLOTS           = 120,
      MAX_BUTTONS         = 17,

      -- Widget config/callback prefixes
      LOAD                = "load",
      CLICK               = "click",
   },

   -- Encoded board structure for generating web links.
   -- Filled in WebLink.lua
   EncodedBoard    = {

   },

   -- UI table, filled in UI.lua
   UI              = {
      
   },

   -- Text table, filled in Text.lua
   Text            = {

   },

   -- Keyboard layout table, filled in Text.lua
   Keyboards       = {
      
   },

   -- Filter for actions to be shown in addition to binds.
   ActionFilter    = {

   },

   -- Title/version of this addon
   Title           = "KeybindViewer",
   Version         = "1.0",

   -- About and welcome strings, created at load time.
   About           = "",
   Welcome         = "",

   -- Are we init'd?
   init            = false,

   -- Maps for keybinds
   bind_map        = {},
   cmd_map         = {},

   -- Config default values
   config_defaults = {
      KV_ButtonsInput     = 5,
      KV_SelectLayout     = "US-En",
      KV_RightOrLeft      = "Right",
      KV_ShowMinimapIcon  = true,
      KV_Bartender        = false,
      KV_Dominos          = false,
      KV_BindPad          = true,
      KV_Bar1             = true,
      KV_Bar2             = true,
      KV_Bar3             = true,
      KV_Bar4             = true,
      KV_Bar5             = true,
      KV_Bar6             = true,
      KV_Bar7             = true,
      KV_Bar8             = true,
      KV_Bar9             = true,
      KV_Bar10            = true,
   }, 
}

