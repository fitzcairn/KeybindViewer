--
-- Functions supporting the creation of a web URL from the user keybinds.
--


-- Upvalues
local I        = KV.IconMap;
local C        = KV.Constants;
local E        = KV.EncodedBoard;
local U        = FitzUtils;
local ENC      = FitzUtilsEncode;
local K        = KV.Keyboards;
local L        = KV.Text;
local KAE      = KV.ActionFilterEncodeList;


--
-- Locals
--

local _len     = string.len
local _sub     = string.sub
local _insert  = table.insert
local _concat  = table.concat
local _find    = string.find
local _gmatch  = string.gmatch


-- Helper function for strings
local function StartsWith(in_str, start)
   return _sub(in_str, 1, _len(start)) == start
end


-- Supported mouse buttons.
local MOUSE_BUTTONS = {
   "MOUSEWHEELUP",
   "MOUSEWHEELDOWN",
   "BUTTON1",
   "BUTTON2",
   "BUTTON3",
   "BUTTON4",
   "BUTTON5",
   "BUTTON6",
   "BUTTON7",
   "BUTTON8",
   "BUTTON9",
   "BUTTON10",
   "BUTTON11",
   "BUTTON12",
   "BUTTON13",
   "BUTTON14",
   "BUTTON15",
   "BUTTON16",
   "BUTTON17",
}


-- Assume following code points for language layouts:
-- 01 = Us-En
-- 02 = DE
-- ...
local LANG_CODES = {
   ["US-En"] = '01',
   ["DE"]    = '02',
}


-- Assume following codes for mod key combinations
-- 1: no mod keys
-- 2: ctrl
-- 3: alt
-- 4: shift
-- 5: ctrl + alt
-- 6: ctrl + shift
-- 7: ctrl + alt + shift 
-- 8: alt  + shift
local MOD_CODES = {
   [""]               = 1,
   ["CTRL"]           = 2,
   ['ALT']            = 3,
   ['SHIFT']          = 4,

   ["ALT-CTRL"]       = 5,
   ["CTRL-ALT"]       = 5,

   ["CTRL-SHIFT"]     = 6,
   ["SHIFT-CTRL"]     = 6,

   ["ALT-CTRL-SHIFT"] = 7,
   ["ALT-SHIFT-CTRL"] = 7,
   ["CTRL-ALT-SHIFT"] = 7,
   ["CTRL-SHIFT-ALT"] = 7,
   ["SHIFT-CTRL-ALT"] = 7,
   ["SHIFT-ALT-CTRL"] = 7,

   ["ALT-SHIFT"]      = 8,
   ["SHIFT-ALT"]      = 8,
}


-- Bind type codes
-- 1: [S]pell
-- 2: [I]tem
-- 3: [M]acro
-- 4: [E]quipmentset
-- ...?
local TYPE_CODES = {
   ["action"]       = 0,
   ["spell"]        = 1,
   ["item"]         = 2,
   ["macro"]        = 3,
   ["equipmentset"] = 4,
   ["companion"]    = 5,
}


-- Bind source codes
-- 1: [B]  (Blizzard)
-- 2: [D]  (Dominos)
-- 3: [BT] (Bartender)
-- 4: [BP] (BindPad)
-- 5: petbar
-- 6: stancebar
local SRC_CODES = {
   ["blizzard"]  = 1,
   ["dominos"]   = 2,
   ["bartender"] = 3,
   ["bindpad"]   = 4,
   ["pet"]       = 5,
   ["stance"]    = 6,
}


-- Mouse side
local SIDE_CODES = {
   ["Right"]  = 1,
   ["Left"]   = 0,
}


local _BASE_URL = "http://kbv.fitztools.com/v"


-- Iterate through the available keyboards, and save an
-- encoded version of each.  The resulting data structure
-- is saved in KV.EncodedBoard, and looks like:
--
--  {
--   lang: {
--           CODE: KEY_CMD
--           ...
--         }
-- }
--
function KV:CreateKeyEncoding()
   local i,cmd = 0,""
   wipe(E)
   
   for lang,board in pairs(K) do
      E[lang] = {}
      i = 0
      for _,row in ipairs(board['layout']) do
         for _,k in ipairs(row) do
            cmd = k[1]
            if cmd ~= nil and _len(cmd) > 0 and not StartsWith(cmd, "_") and not MOD_CODES[cmd] then
               E[lang][cmd] = i
               i = i + 1
            end
         end
      end
      -- Add in mouse buttons.
      for _,cmd in ipairs(MOUSE_BUTTONS) do
         E[lang][cmd] = i
         i = i + 1
      end
   end

   return E
end


-- Given the key_map and the bind map, create an encoded string
-- representing the state of user keybinds.
--
-- Args:
--   bind_map: table to fill as follows:
--         { [CMD] = { key1, key2...} }
--   cmd_map: table to fill as follows:
--         { [CMD] = {
--                     [slot] = {
--                               id      = 1234,
--                               type    = "",
--                               name    = "",
--                               texture = "",
--                               src     = "BindPad" or "Clique" or "Bar 1 Slot 3"...,
--                               from    = "blizzard", "bindpad"... for encoding
--                              {,
--                     },
--           }
--   key_map: keys to actual frames as follows:
--         key_map[_B] = { key = { name1 = <frame1>, name2 = <frame2>...}}
--
-- Returns:
--   String via the following grammar (EBNF): [] = repeated, ? optional, etc
-- 
-- input              = side num_mouse_buttons lang keys
-- side               = digit
-- num_mouse_buttons  = digit digit
-- lang               = digit digit
-- keys               = [key_code num_mod_blocks encoded_mod_vector]
-- 
-- key_code           = digit digit digit
-- num_mod_blocks     = digit
-- 
-- encoded_mod_vector = [ length encoded_mod_block ] # len = num_mod_blocks
-- 
-- encoded_mod_block  = encode(source mod_keys type id)
-- source             = digit     # From the source map
-- mod_keys           = digit     # From the mod combination map, 1-7
-- type               = digit     # From the spell map
-- id                 = [ digit ] # can be 1-5 digis long
-- 
--
-- length             = digit
-- digit              = 0-9
--
function KV:CreateWebLink(key_map, bind_map, cmd_map)
   local m_side  = KV:GetVar("KV_RightOrLeft", true)
   local num_b   = tonumber(KV:GetVar("KV_ButtonsInput", true))
   local lang    = KV:GetVar("KV_SelectLayout", true)
   local enc_str = ""

   -- Make sure we've got a populated encoding map.
   if not E[lang] then return L["Error generating link!"] end

   -- Some local helpers
   local _add = function(in_str)
                   enc_str = enc_str..in_str
                end
   local _pad = function(s, size)
                   local out = ""..s
                   for i = 1, size - _len(s) do out = "0"..out end
                   return out
                end
             
   -- Side
   _add(SIDE_CODES[m_side])

   -- Buttons
   _add(_pad(num_b, 2))

   -- Lang code
   _add(LANG_CODES[lang])

   -- Go through the bind map and accumulate the binds for encoding.
   -- To do this, we'll build a temporary data structure like this: 
   --
   -- {
   --    KEY_CODE = {
   --                 { MOD_CODE, SRC_CODE, TYPE, ID },
   --                 ...
   --               }
   --   ...
   -- }
   --
   local enc_bind_map = {}
   local bind, mods, actn, cmd, key, k, enc_key_code, enc_type, enc_id, enc_src, enc_mods, tex

   for cmd,keys in pairs(bind_map) do
      for _,key in ipairs(keys) do
         bind = nil
         mods = {}

         -- Handle special cases involving the "-" key, which
         -- the split barfs on.
         if _find(key, "-$") then bind = "-" end

         -- Split up compound binds with mods
         for k in _gmatch(key, "[^-]+") do
            if not MOD_CODES[k] then 
               -- Non-mod keybind key.
               bind = k
            else
               _insert(mods, k)
            end
         end

         -- Add a callback to the bind key that highlights the bind
         -- and all mods on mouseover.
         if bind and E[lang][bind] then
            -- Get encoded key
            enc_key_code = _pad(E[lang][bind], 3)

            -- Get encoded mods
            enc_mods = MOD_CODES[_concat(mods, "-")] 

            -- If this bind issues an action slot command to the UI
            -- and there is something assigned to that slot, save
            -- the action info block.
            actn = cmd_map[cmd] or nil

            -- If this bind is for an action, save.
            if actn then
               for _,slot in pairs(actn) do

                  -- Get the source
                  enc_src  = SRC_CODES[slot.from]

                  if enc_src == 3 then
                     U:Dump(actn)
                  end

                  -- Get the type, defaulting to spell on flyout (pet), etc
                  -- NOTE NOTE NOTE: Passing on flyout actions right now; we look silly
                  -- otherwise. :(
                  enc_type = TYPE_CODES[slot.type]
                  if enc_type ~= nil then
                     -- For types other than items, actions, and spells, get an id
                     -- by mapping the icon to a spell that has that icon.  This is just
                     -- for display.
                     if type(slot.id) == "string" then
                        -- Default to unknown spell if we don't find this.
                        enc_id = KV.IconMap[slot.texture] or 75001
                     else
                        enc_id = slot.id
                     end
                     -- Insert
                     enc_bind_map[enc_key_code] = enc_bind_map[enc_key_code] or {}
                     _insert(enc_bind_map[enc_key_code], { enc_src, enc_mods, enc_type, enc_id })
                  end
               end
            -- Handle binds for non-action commands we wish to display.
            elseif KAE[cmd] ~= nil then
               -- Source is blizzard, type is action
               enc_src  = SRC_CODES["blizzard"]
               enc_type = TYPE_CODES["action"]

               -- Id is from the map
               enc_id   = KAE[cmd]

               -- Insert
               enc_bind_map[enc_key_code] = enc_bind_map[enc_key_code] or {}
               _insert(enc_bind_map[enc_key_code], { enc_src, enc_mods, enc_type, enc_id })
            end
         end
      end
   end

   --U:Dump(enc_bind_map)

   -- Now use the data structure to write out the rest of the string.
   local enc_key_block, enc_mod_vector, enc_mod_block
   for enc_key_code, mod_block in pairs(enc_bind_map) do
      -- Construct the key block, add to output string.
      _add(enc_key_code..#mod_block)
      
      -- Construct the encoded vector of binds one block at a time.
      enc_mod_vector = ""
      for _, block in ipairs(mod_block) do
         enc_mod_block = ENC:Encode(_concat(block))
         enc_mod_vector = enc_mod_vector.._len(enc_mod_block)..enc_mod_block
      end
      
      -- Add finished vector to the output string.
      _add(enc_mod_vector)
   end

   return _BASE_URL..enc_str
   
end
