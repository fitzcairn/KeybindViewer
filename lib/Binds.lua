--
-- Module to handle working with binds/action bars/action mods
-- 
-- Offers a few useful functions for getting maps of binds -> cmds -> actions.
--


-- Upvalues
local C      = KV.Constants;
local L      = KV.Text;


-- For speed
local _insert = table.insert
local _format = string.format
local _find   = string.find
local _sub    = string.sub
local _len    = string.len


-- Get a map of all keybinds -> actions for all actions
-- belonging to the Blizzard UI.
-- Writes into bind_map reference, and also returns a ref.
function KV:GetBindMap(bind_map, filter)
   for i = 1, GetNumBindings(), 1 do
      local cmd     = select(1, GetBinding(i))
      bind_map[cmd] = { GetBindingKey(cmd) } 
   end
   return bind_map
end


-- Translate a slot to it's action command
function KV:TranslateSlotToBind(id)
   local b, bind, b_name, b_type
   local adj_id   = id

   if id <= 12 then
      b_type = 'ACTIONBUTTON' 
      b_name = 'ActionButton'
   elseif id <= 24 then -- Action bar page 2 or pet bar?
      adj_id = id - 12
      b_type  = 'ACTIONBUTTON'
      b_name = 'ActionButton'
   elseif id <= 36 then
      b_name = 'MultiBarRightButton'
      adj_id = id - 24
   elseif id <= 48 then
      b_name = 'MultiBarLeftButton'
      adj_id = id - 36
   elseif id <= 60 then
      b_name = 'MultiBarBottomRightButton'
      adj_id = id - 48

   elseif id <= 72 then
      b_name = 'MultiBarBottomLeftButton'
      adj_id = id - 60

   -- For most classes, new bars pop up that take the keybindings
   -- assigned to ACTIONBUTTON1-12.  This includes the possession bar.
   elseif id <= 120 then
      local base = 0
      if     id <= 84  then base = 72
      elseif id <= 96  then base = 84
      elseif id <= 108 then base = 96
      elseif id <= 120 then base = 108
      else                  base = 120 end
      b_type = 'ACTIONBUTTON' 
      b_name = 'BonusActionButton'
      adj_id = id - base
   end

   -- Grab button and bind.
   b = _G[b_name .. adj_id]
   if not b_type then b_type = b.buttonType end

   return b_type .. adj_id

end


-- Local helper to query the client to get information
-- on an action in a particular bar slot.
local function GetSlotAction(slot)
   local texture = GetActionTexture(slot);
   local name    = ""

   -- Better be a texture, otherwise empty slot.
   if not texture then return nil end

   -- Determine name, id, etc.
   -- [4.0.1] This now returns type, id, sub_type instead of 
   -- type, id, sub_type, spell_id
   local type, id, sub_type = GetActionInfo(slot)
   if type == "spell" then
      name = select(1, GetSpellInfo(id))
      id   = id
   elseif type == "item" then
      name = select(1, GetItemInfo(id))
      id   = id
   elseif type == "macro" then
      name = select(1, GetMacroInfo(id))
      id   = "macro"
   elseif type == "equipmentset" then
      name = id
      id   = "equipmentset"                     
   elseif type == "companion" then
      name = select(1, GetSpellInfo(id))
      id = "companion"
   else
      name,id = slot,slot -- Should never get here
   end
   
   -- Build and return action map
   return {
      id      = id,
      type    = type,
      name    = name,
      texture = texture,
      src     = slot,
   }
end

-- Local helper to query the client to get information
-- on an pet action in a particular pet bar slot.
local function GetPetAction(slot)
   local name, subtext, texture, is_tok, _, _, _ = GetPetActionInfo(slot)

   -- Didn't get anything? Done.
   if not name and texture then return nil end

   -- If is_tok is not nil, need to get the actual name and texture from
   -- global variables
   if is_tok then
      name    = _G[name]
      texture = _G[texture]
   end
   
   -- Build and return action map
   return {
      id      = name,
      type    = "spell",
      name    = name,
      texture = texture,
      src     = slot,
   }
end

-- Local helper to query the client to get information
-- on an a stance action
local function GetStanceAction(slot)
   local texture, name, _, _ = GetShapeshiftFormInfo(slot)

   -- Didn't get anything? Done.
   if not name and texture then return nil end

   -- Build and return action map
   return {
      id      = name,
      type    = "spell",
      name    = name,
      texture = texture,
      src     = slot,
   }
end

-- Local function to convert a slot into bar, slot (on [1,12])
local function GetBarAndSlot(s)
   local bar = ceil(s / 12)
   s = s - ((bar - 1) * 12)
   return bar, s
end


-- Build in-place table of all action slot commands to a list
-- describing the action.  Builds into cmd_map reference.
-- Returned: { [CMD] = {
--                     [slot] = {
--                               id      = 1234,
--                               type    = "",
--                               name    = "",
--                               texture = "",
--                              {,
--                     },
--           }
function KV:GetActionSlotInfo(cmd_map)
   local slot, bar, bar_slot = 1, 1, 1
   local cmd, action
   local slot_map = {}
   local _, class = UnitClass("player")
   
   -- For convienience
   local _insert_slot  = function(b, e)
                            for s = b, e do _insert(slot_map, s) end
                         end

   -- First, determine from UI what actions to show.
   if KV:GetVar("KV_Bar1")  then _insert_slot(1,   12)  end
   if KV:GetVar("KV_Bar2")  then _insert_slot(13,  24)  end
   if KV:GetVar("KV_Bar3")  then _insert_slot(25,  36)  end
   if KV:GetVar("KV_Bar4")  then _insert_slot(37,  48)  end
   if KV:GetVar("KV_Bar5")  then _insert_slot(49,  60)  end
   if KV:GetVar("KV_Bar6")  then _insert_slot(61,  72)  end
   if KV:GetVar("KV_Bar7")  then _insert_slot(73,  84)  end
   if KV:GetVar("KV_Bar8")  then _insert_slot(85,  96)  end
   if KV:GetVar("KV_Bar9")  then _insert_slot(96,  108) end
   if KV:GetVar("KV_Bar10") then _insert_slot(109, 120) end

   -- Iterate through slots and build map.
   for _, slot in ipairs(slot_map) do
      action = GetSlotAction(slot)
      cmd    = self:TranslateSlotToBind(slot)

      -- If there's an action in this slot, save to map
      if action then
         action.from = "blizzard"
         bar, bar_slot = GetBarAndSlot(slot)

         -- Set src value from class
         if     class == "DRUID"   and slot > 72 and slot <= 84 then
            action.src    = _format(L["Cat Bar, Slot %i"], bar_slot)     
         elseif class == "DRUID"   and slot > 84 and slot <= 96 then
            action.src    = _format(L["Prowl Bar, Slot %i"], bar_slot)     
         elseif class == "DRUID"   and slot > 96 and slot <= 108 then
            action.src    = _format(L["Bear Bar, Slot %i"], bar_slot)     
         elseif class == "DRUID"   and slot > 108 and slot <= 120 then
            action.src    = _format(L["Moonkin Bar, Slot %i"], bar_slot)   
  
         elseif class == "WARRIOR" and slot > 72 and slot <= 84 then
            action.src    = _format(L["Battle Stance Bar, Slot %i"], bar_slot)   
         elseif class == "WARRIOR" and slot > 84 and slot <= 96 then
            action.src    = _format(L["Defensive Stance Bar, Slot %i"], bar_slot)   
         elseif class == "WARRIOR" and slot > 96 and slot <= 108 then
            action.src    = _format(L["Berserker Stance Bar, Slot %i"], bar_slot)   

         elseif class == "ROGUE"   and slot > 72 and slot <= 84  then
            action.src    = _format(L["Stealth Bar, Slot %i"], bar_slot)   

         elseif class == "PRIEST"  and slot > 72 and slot <= 84  then
            action.src    = _format(L["Shadowform Bar, Slot %i"], bar_slot)   

         else -- other classes, bars
            action.src    = _format(L["Bar %i, Slot %i"], bar, bar_slot)               
         end

         -- Insert into map
         cmd_map[cmd]       = cmd_map[cmd] or {}
         cmd_map[cmd][slot] = action
      end
   end

   -- Iterate through the pet bar if required.
   if KV:GetVar("KV_PetBar") then
      for slot = 1, NUM_PET_ACTION_SLOTS,1 do
         cmd    = "BONUSACTIONBUTTON"..slot
         action = GetPetAction(slot)
         if action and action.texture then
            action.src  = _format(L["Pet Bar, Slot %i"], slot)
            action.from = "pet"
            
            -- Insert into map
            cmd_map[cmd]       = cmd_map[cmd] or {}
            cmd_map[cmd][slot] = action
         end
      end
   end

   -- Iterate through the stance bar if required
   if KV:GetVar("KV_StanceBar") then
      for slot = 1, GetNumShapeshiftForms(),1 do
         cmd    = "SHAPESHIFTBUTTON"..slot
         action = GetStanceAction(slot)
         if action and action.texture then
            action.src = _format(L["Stance Bar, Slot %i"], slot)
            action.from = "stance"
            
            -- Insert into map
            cmd_map[cmd]       = cmd_map[cmd] or {}
            cmd_map[cmd][slot] = action
         end
      end
   end


   return cmd_map
end

-- Get keybinds and actions associated with Bartender into the
-- bind_map and cmd_map sructures.  Structures are written by
-- reference.  See comments for KV:GetBoundActionInfo for 
-- more info on arg structure.
function KV:GetBartenderSlotInfo(cmd_map, bind_map)
   local bar, slot, action, cmd, binds, button

   -- Ok, this interface into Bartender is cheesy, but the most
   -- efficient way I could think of to hack this on short notice.
   -- Essentially, go through each of the 132 possible action slots,
   -- and check for actions and binds.
   
   -- Go through each of the 10 bars + stance and pet.
   -- There are less than 12 buttons for pet/stance--hack
   local bars = { 1,2,3,4,5,6,7,8,9,10,"Pet","Stance"}
   for _, bar in ipairs(bars) do
      for slot = 1,12,1 do

         -- Decode normal slots and pet/stance slots differently.
         if type(bar) == "number" then
            slot = ((bar - 1) * 12) + slot
            cmd  = "CLICK BT4Button"..slot..":LeftButton"
            action = GetSlotAction(slot)
            if action then
               action.src = _format(L["Bartender Bar %i, Slot %i"], GetBarAndSlot(slot))  
            end
         else
            cmd  = "CLICK BT4"..bar.."Button"..slot..":LeftButton"
            if bar == "Pet" then
               action = GetPetAction(slot)
            else
               action = GetStanceAction(slot)
            end
            if action then
               action.src = _format(L["Bartender "..bar.." Bar, Slot %i"], slot)
            end
         end

         -- Get the binds.
         binds = {  GetBindingKey(cmd) }

         -- If we have an action and binds, write out.
         if #binds > 0 and action and action.texture then
            action.from = "bartender"

            -- Insert into map
            cmd_map[cmd]       = cmd_map[cmd] or {}
            cmd_map[cmd][slot] = action

            for _,b in ipairs(binds) do
               bind_map[cmd] = bind_map[cmd] or {}
               if not tContains(bind_map[cmd], b) then
                  _insert(bind_map[cmd], b)
               end
            end
         end
      end
   end

   return cmd_map, bind_map
end


-- Get keybinds and actions associated with Dominos into the
-- bind_map and cmd_map sructures.  Structures are written by
-- reference.  See comments for KV:GetBoundActionInfo for 
-- more info on arg structure.
function KV:GetDominosSlotInfo(cmd_map, bind_map)
   local bar, slot, action, cmd, binds, locs, b_start, b_end, d_end, b

   -- For convienience
   local _process_bind = function(binds, b_start, b_end)
                            b = _sub(binds, b_start, b_end)
                            bind_map[cmd] = bind_map[cmd] or {}
                            if not tContains(bind_map[cmd], b) then
                               _insert(bind_map[cmd], b)
                            end
                         end


   -- Construct the map of bars we care about.
   local bars = {1,2,3,4,5,6,7,8,9,10,"pet","class"}

   -- Dominos is an actionbar replacement that allows for the
   -- re-arrangement of actionbars--including using ones that
   -- are sometimes made unavailable by the default blizz ui.
   --
   -- It creates buttons that inherit from the secure ActionButton
   -- template.  Therefore, iterate over all the buttons it creates,
   -- and ask the UI what action is taken on activation.
   --    
   -- NOTE: Dominos does not use the regular ui commands regular bars do.
   -- Instead, it binds keybinds to specific slots.
   --
   -- For this reason, we create a special "DOMINOS" UI command it use it to
   -- map between the keybinds and the actions.
   for _,i in ipairs(bars) do
      bar = Dominos.Frame:Get(i)
      if (bar) then
         for bname, button in pairs(bar.buttons) do
            if i == "pet" then 
               slot   = button:GetID()
               action = GetPetAction(slot)
            elseif i == "class" then
               slot   = button:GetID()
               action = GetStanceAction(slot)
            else
               slot   = _G[button:GetName()]:GetAttribute("action")
               action = GetSlotAction(slot)
            end

            -- Create the fake dominos command to map binds to actions
            cmd    = "DOMINOS_"..i.."_"..slot
            
            -- Get the binds from Dominos + blizzard
            binds = button:GetBindings()

            -- If we have an action, and there's a binding, continue
            if binds and action and action.texture then
               action.from = "dominos"

               if i == "pet" then
                  action.src = _format(L["Dominos Pet Bar, Slot %i"], slot)
               elseif i == "class" then
                  action.src = _format(L["Dominos Stance Bar, Slot %i"], slot)
               else
                  action.src = _format(L["Dominos Bar %i, Slot %i"], GetBarAndSlot(slot))
               end
               
               -- Insert into map
               cmd_map[cmd]       = cmd_map[cmd] or {}
               cmd_map[cmd][slot] = action

               -- Process the binds, adding the keys to the bind_map
               b_start = 1
               while(_find(binds, ", ", b_start, true)) do
                  b_end, d_end = _find(binds, ", ", b_start, true)
                  _process_bind(binds, b_start, b_end - 1)
                  b_start = d_end + 1
               end
               _process_bind(binds, b_start, _len(binds))

            end
         end
      end
   end

   return cmd_map, bind_map
end


-- Get keybinds and actions associated with BindPad into the
-- bind_map and cmd_map sructures.  Structures are written by
-- reference.  See comments for KV:GetBoundActionInfo for 
-- more info on arg structure.
function KV:GetBindPadSlotInfo(cmd_map, bind_map)
   local bindpad_slot = nil
   local action       = nil

   -- Iterate through the keys bound to this profile in BindPad, and
   -- get the associated cmd strings into the bind_map.
   for a,k in pairs(BindPadCore.GetProfileData().keys) do
      if a ~= nil then bind_map[a] = { k } end
   end   

   -- There are currently (as of 2.3.7) 168 BindPad slots avaialable.
   -- Iterate through each one and grab the padslot.  From each slot,
   -- build out the cmd_map 
   for id = 1, 168, 1 do
      bindpad_slot = BindPadCore.GetAllSlotInfo(id)
      if bindpad_slot and bindpad_slot.action ~= nil then
         action = {
            type    = bindpad_slot.type,
            name    = bindpad_slot.name,
            texture = bindpad_slot.texture,
            src     = _format(L["BindPad Slot %i"], id),
            from    = "bindpad",
         }
         cmd_map[bindpad_slot.action] = cmd_map[bindpad_slot.action] or {}
         _insert(cmd_map[bindpad_slot.action], action)
      end
   end

   return cmd_map, bind_map
end


-- Entry point to get information on all keybinds.
-- Build table of all action slot commands to a list
-- describing the action.  Builds into cmd_map reference.
-- 
-- Args (all optional):
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
--                              {,
--                     },
--           }
function KV:GetBoundActionInfo(bind_map, cmd_map)
   cmd_map = cmd_map or {}
   wipe(cmd_map)
   bind_map = bind_map or {}
   wipe(bind_map)

   -- Fill bind_map.
   self:GetBindMap(bind_map)

   -- Get all the bind info for actionbar slots.
   self:GetActionSlotInfo(cmd_map)

   -- Unless ignored or not present, get all the info for BindPad slots.
   if KV:GetVar("KV_BindPad", true) and BindPadCore then
      self:GetBindPadSlotInfo(cmd_map, bind_map)
   end

   -- Unless ignored or not present, get all the info for Dominos slots
   if KV:GetVar("KV_Dominos", true) and Dominos then
      self:GetDominosSlotInfo(cmd_map, bind_map)
   end

   -- Unless ignored or not present, get all the info for Dominos slots
   if KV:GetVar("KV_Bartender", true) and Bartender4 then
      self:GetBartenderSlotInfo(cmd_map, bind_map)
   end

   -- Unless ignored, get all the information for Clique slots.
   -- TODO

   -- Done
   return bind_map, cmd_map
end

