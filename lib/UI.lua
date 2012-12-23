--
-- UI Widget Layout
-- 
-- Defines widget-specific text and callbacks for UI objects set up using
-- methods defined in lib/Config.lua
--

-- Upvalues
local L          = KV.Text;
local Layouts    = KV.Keyboards;
local C          = KV.Constants;


-- Layout and text for all UI widgets, organized by config
-- block/dialog box.  Uses localized strings.
KV.UI = {

   -- Icon button
   KV_MinimapIcon = {
      text   = L["KeybindViewer"],
      tt_off = L["Show KeybindViewer"],
      tt_on  = L["Hide KeybindViewer"],
   },

   -- Options menu items
   KV_OptionsMenu = {
      label = "",

      -- Input for # mouse buttons
      KV_ButtonsInput = {
         tt     = L["Number of mouse buttons to display, from 3 to "..C.MAX_BUTTONS],
         label  = L["Buttons:"],
      },

      -- Dropdown to select layout
      KV_SelectLayout = {
         tt       = L["Select which keyboard layout to use."],
         label    = L["Keyboard:"],
         help     = "",

         -- Menu options
         options  = {
            -- Automatically populated from the keyboard layout map.
         },
         
         -- Callbacks
         -- Setup function for the trial selection dropdown.
         [C.LOAD] = function (menu)
                       local menu_name = menu:GetName()
                       local cfg_block = menu:GetParent():GetName()
                       local id        = 1
                       menu._menu_id   = 1
                       
                       -- Add the options from the layout table
                       for layout,_ in pairs(Layouts) do
                          if layout == KV:GetVar(menu_name, true) then id = menu.menu_id end
                          KV:AddMenuButton(menu, layout, false, { ["text"] = layout })
                       end
                       
                       local sel = KV:GetVar(menu_name, true)
                       UIDropDownMenu_SetSelectedName(menu, sel, id)
                    end,

         -- On select, refresh the addon.
         [C.CLICK] = function ()
                        KV:Refresh()
                     end,
      },

      -- Dropdown to select right/left display
      KV_RightOrLeft = {
         tt      = L["Select which side to the mouse is displayed on."],
         label   = L["Mouse Side:"],
         help    = "",

         -- Menu options
         options = {
            Right = {
               text = L["Right"],
            },
            Left = {
               text = L["Left"],
            },
         },

         -- Callbacks
         [C.LOAD] = function (menu)
              local menu_name = menu:GetName()
              local cfg_block = menu:GetParent():GetName()
              local id        = 1
              menu._menu_id   = 1

              -- Get a ref to the localized menu options.
              local opt_table = KV.UI[cfg_block][menu_name].options
              if not opt_table then return end

              -- Add the options from the layout table
              for opt,t in pairs(opt_table) do
                 if opt == KV:GetVar(menu_name, true) then id = menu.menu_id end
                 KV:AddMenuButton(menu, opt, false, t)
              end

              local sel = KV:GetVar(menu_name, true)
              UIDropDownMenu_SetSelectedName(menu, sel, id)
           end,

         -- On select, refresh the addon.
         [C.CLICK] = function ()
                        KV:Refresh()
                     end,
      },

      -- Checkbox to turn on/off the minimap
      KV_ShowMinimapIcon = {
         tt        = L["Turn on/off the minimap icon."],
         label     = L["Minimap Icon:"],

         -- Callbacks
         [C.CLICK] =  function(cb)
                         if not KV.minimap_icon then return end
                         if KV:GetVar(cb:GetName()) then
                            KV.minimap_icon:Show("KV_MinimapIcon")
                         else
                            KV.minimap_icon:Hide("KV_MinimapIcon")
                         end
                      end
      },

      -- Input box for copy/paste URL
      KV_UrlBox = {
         tt     = L["Copy and paste this URL into any browser to view your binds online."],
         label  = L["Export to Web:"],
      },

      -- Button to select what keybinds to incude
      KV_SelectBars = {
         tt        = L["Select which bars/addons to show binds from."],
         label     = L["Filter Binds"],

         -- Callbacks
         [C.CLICK] =  function(b)
                         if _G["KV_BarsDialog"]:IsShown() then
                            KV:HideDialog(_G["KV_BarsDialog"]) 
                         else
                            KV:ShowDialog(_G["KV_BarsDialog"]) 
                         end
                      end
      },
   },

   -- Dialog to select the bars to use.      
   KV_BarsDialog = {
      title = L["Keybinds to Show"],

      -- Buttons
      KV_SelectAll = {
         tt     = L["Show all keybinds from all sources, included supported addons"],
         label  = L["Select All"],

         -- Callbacks
         [C.CLICK] =  function(b)
                         KV:CheckBox(_G["KV_Bartender"], true)
                         KV:CheckBox(_G["KV_Dominos"],   true)
                         KV:CheckBox(_G["KV_BindPad"],   true)
                         KV:CheckBox(_G["KV_PetBar"],    true)
                         KV:CheckBox(_G["KV_StanceBar"], true)
                         KV:CheckBox(_G["KV_Bar1"],      true)
                         KV:CheckBox(_G["KV_Bar2"],      true)
                         KV:CheckBox(_G["KV_Bar3"],      true)
                         KV:CheckBox(_G["KV_Bar4"],      true)
                         KV:CheckBox(_G["KV_Bar5"],      true)
                         KV:CheckBox(_G["KV_Bar6"],      true)
                         KV:CheckBox(_G["KV_Bar7"],      true)
                         KV:CheckBox(_G["KV_Bar8"],      true)
                         KV:CheckBox(_G["KV_Bar9"],      true)
                         KV:CheckBox(_G["KV_Bar10"],     true)
                      end
      },

      KV_SelectBlizz = {
         tt     = L["Show keybinds from all Blizzard action bars."],
         label  = L["Select All Bars"],

         -- Callbacks
         [C.CLICK] =  function(b)
                         KV:CheckBox(_G["KV_Bartender"], false)
                         KV:CheckBox(_G["KV_Dominos"],   false)
                         KV:CheckBox(_G["KV_BindPad"],   false)
                         KV:CheckBox(_G["KV_PetBar"],  true)
                         KV:CheckBox(_G["KV_StanceBar"], true)
                         KV:CheckBox(_G["KV_Bar1"],    true)
                         KV:CheckBox(_G["KV_Bar2"],    true)
                         KV:CheckBox(_G["KV_Bar3"],    true)
                         KV:CheckBox(_G["KV_Bar4"],    true)
                         KV:CheckBox(_G["KV_Bar5"],    true)
                         KV:CheckBox(_G["KV_Bar6"],    true)
                         KV:CheckBox(_G["KV_Bar7"],    true)
                         KV:CheckBox(_G["KV_Bar8"],    true)
                         KV:CheckBox(_G["KV_Bar9"],    true)
                         KV:CheckBox(_G["KV_Bar10"],   true)
                      end
      },

      KV_SelectVisible = {
         tt     = L["Show keybinds only from UI bars that are currently visible and mods that are in use."],
         label  = L["Select Visible"],

         -- Callbacks
         [C.CLICK] =  function(b)
                         -- Turn off everything, then select what to turn on.
                         KV:CheckBox(_G["KV_Bartender"], false)
                         KV:CheckBox(_G["KV_Dominos"], false)
                         KV:CheckBox(_G["KV_BindPad"], false)
                         KV:CheckBox(_G["KV_PetBar"],  false)
                         KV:CheckBox(_G["KV_StanceBar"], false)
                         KV:CheckBox(_G["KV_Bar1"],    false)
                         KV:CheckBox(_G["KV_Bar2"],    false)
                         KV:CheckBox(_G["KV_Bar3"],    false)
                         KV:CheckBox(_G["KV_Bar4"],    false)
                         KV:CheckBox(_G["KV_Bar5"],    false)
                         KV:CheckBox(_G["KV_Bar6"],    false)
                         KV:CheckBox(_G["KV_Bar7"],    false)
                         KV:CheckBox(_G["KV_Bar8"],    false)
                         KV:CheckBox(_G["KV_Bar9"],    false)
                         KV:CheckBox(_G["KV_Bar10"],   false)

                         -- If bindpad, select.
                         if BindPadCore then
                            KV:CheckBox(_G["KV_BindPad"], true)
                         end
                         -- If Dominos, select and done
                         if Dominos then
                            KV:CheckBox(_G["KV_Dominos"], true)
                         end
                         -- If Bartender, select and done.
                         if Bartender4 then
                            KV:CheckBox(_G["KV_Bartender"], true)
                         end    

                         -- Stance Bar?
                         local _, class = UnitClass("player")
                         if class == "DRUID" or class == "WARRIOR" or class == "ROGUE" or class == "PRIEST" then
                            KV:CheckBox(_G["KV_StanceBar"], true)
                         end

                         -- Pet bar?
                         local has_pet, _ = HasPetUI()
                         if has_pet then
                            KV:CheckBox(_G["KV_PetBar"],  true)
                         end

                         -- Decide what is shown as main actionbar.
                         if GetActionBarPage() == 2 then
                            KV:CheckBox(_G["KV_Bar2"],    true)
                         else
                            -- Because overlays are used and there is
                            -- a many-to-one relationship between
                            -- ActionSlots and actual buttons on the bar,
                            -- need to use BonusBarOffset to determine
                            -- what to show.
                            local bonus_offset = GetBonusBarOffset()
                            if bonus_offset == 0 then
                               KV:CheckBox(_G["KV_Bar1"],    true)
                            elseif bonus_offset == 1 then
                               KV:CheckBox(_G["KV_Bar7"],    true)
                            elseif bonus_offset == 2 then
                               KV:CheckBox(_G["KV_Bar8"],    true)
                            elseif bonus_offset == 3 then
                               KV:CheckBox(_G["KV_Bar9"],    true)
                            elseif bonus_offset == 4 then
                               KV:CheckBox(_G["KV_Bar10"],   true)
                            end
                         end

                         -- Action slots 25-72 are toggled visible/not
                         -- in the interface menu.
                         local BL,BR,RB,RB2 = GetActionBarToggles()
                         if RB  then KV:CheckBox(_G["KV_Bar3"],    true) end
                         if RB2 then KV:CheckBox(_G["KV_Bar4"],    true) end
                         if BR  then KV:CheckBox(_G["KV_Bar5"],    true) end
                         if BL  then KV:CheckBox(_G["KV_Bar6"],    true) end
                      end
      },

      KV_BarsOk = {
         tt     = "",
         label  = L["Ok"],

         -- Callbacks
         [C.LOAD] =  function(d)
                        -- Update the names of all the checkboxes, 
                        -- depending on class.
                        local _, class = UnitClass("player")
                        if     class == "DRUID"   then
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].tt     = L["Show binds from Car Form Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].label  = L["Cat Form Bar"]
                           KV.UI["KV_BarsDialog"]["KV_Bar8"].tt     = L["Show binds from Prowl Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar8"].label  = L["Prowl Bar"]
                           KV.UI["KV_BarsDialog"]["KV_Bar9"].tt     = L["Show binds from Bear Form Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar9"].label  = L["Bear Form Bar"]
                           KV.UI["KV_BarsDialog"]["KV_Bar10"].tt    = L["Show binds from Moonkin Form Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar10"].label = L["Moonkin Form Bar"]
                        elseif     class == "WARRIOR"  then
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].tt    = L["Show binds from Battle Stance Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].label = L["Battle Stance Bar"]
                           KV.UI["KV_BarsDialog"]["KV_Bar8"].tt    = L["Show binds from Defensive Stance Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar8"].label = L["Defensive Stance Bar"]
                           KV.UI["KV_BarsDialog"]["KV_Bar9"].tt    = L["Show binds from Berserker Stance Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar9"].label = L["Berserker Stance Bar"]
                        elseif     class == "ROGUE"  then
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].tt    = L["Show binds from Stealth Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].label = L["Stealth Bar"]
                        elseif     class == "PRIEST"  then
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].tt    = L["Show binds from Shadowform Bar."]
                           KV.UI["KV_BarsDialog"]["KV_Bar7"].label = L["Shadowform Bar"]
                        else
                           KV:CheckBox(_G["KV_StanceBar"], false)
                           KV:DisableWidget(_G["KV_StanceBar"])
                        end

                        -- Reload bars 7-10.
                        KV:LoadCheckBox(_G["KV_BarsDialog"], _G["KV_Bar7"])
                        KV:LoadCheckBox(_G["KV_BarsDialog"], _G["KV_Bar8"])
                        KV:LoadCheckBox(_G["KV_BarsDialog"], _G["KV_Bar9"])
                        KV:LoadCheckBox(_G["KV_BarsDialog"], _G["KV_Bar10"])
                        
                        -- If no bindpad, disable.
                        if not BindPadCore then
                           KV:CheckBox(_G["KV_BindPad"], false)
                           KV:DisableWidget(_G["KV_BindPad"])
                        end
                        -- If no Dominos, disable.
                        if not Dominos then
                           KV:CheckBox(_G["KV_Dominos"], false)
                           KV:DisableWidget(_G["KV_Dominos"])
                        end
                        -- If no Bartender, disable.
                        if not Bartender4 then
                           KV:CheckBox(_G["KV_Bartender"], false)
                           KV:DisableWidget(_G["KV_Bartender"])
                        end                                         
                     end,
         [C.CLICK] =  function(b)
                         KV:Refresh()
                         KV:HideDialog(_G["KV_BarsDialog"]) 
                      end
      },

      -- Checkboxes. 
      KV_PetBar = {
         tt        = L["Show binds from your Pet Bar."],
         label     = L["Pet Bar"],
      },
      KV_StanceBar = {
         tt        = L["Show binds on your Stance/Form/Stealth Buttons."],
         label     = L["Stance Bar"],
      },
      KV_Dominos = {
         tt        = L["Show binds set through Dominos.  Note: Dominos can set Dominos-only AND normal Blizzard keybinds.  Be sure to select all bars you wish to see binds for."],
         label     = L["Dominos"],
      },
      KV_Bartender = {
         tt        = L["Show binds set through Bartender.  Note: Bartender can set Bartender-only AND normal Blizzard keybinds.  Be sure to select all bars you wish to see binds for."],
         label     = L["Bartender"],
      },
      KV_BindPad = {
         tt        = L["Show binds from BindPad."],
         label     = L["BindPad"],
      },
      KV_Bar1  = {
         tt        = L["Show binds from Action Bar 1."],
         label     = L["Action Bar 1"],
      },
      KV_Bar2  = {
         tt        = L["Show binds from Action Bar 2."],
         label     = L["Action Bar 2"],
      },
      KV_Bar3  = {
         tt        = L["Show binds from Action Bar 3."],
         label     = L["Action Bar 3"],
      },
      KV_Bar4  = {
         tt        = L["Show binds from Action Bar 4."],
         label     = L["Action Bar 4"],
      },
      KV_Bar5  = {
         tt        = L["Show binds from Action Bar 5."],
         label     = L["Action Bar 5"],
      },
      KV_Bar6  = {
         tt        = L["Show binds from Action Bar 6."],
         label     = L["Action Bar 6"],
      },
      KV_Bar7  = {
         tt        = L["Show binds from Action Bar 7."],
         label     = L["Action Bar 7"],
      },
      KV_Bar8  = {
         tt        = L["Show binds from Action Bar 8."],
         label     = L["Action Bar 8"],
      },
      KV_Bar9  = {
         tt        = L["Show binds from Action Bar 9."],
         label     = L["Action Bar 9"],
      },
      KV_Bar10 = {
         tt        = L["Show binds from Action Bar 10."],
         label     = L["Action Bar 10"],
      },

   },
}


