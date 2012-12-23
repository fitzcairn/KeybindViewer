-- Name: KeybindViewer
-- Revision: $Rev$
-- Author(s): Fitzcairn (fitz.wowaddon@gmail.com)
-- Description: View your keybind layout on-screen and on the web.
-- Dependencies: LibStub, LibDataBroker-1.1, LibDBIcon-1.0, CallbackHandler-1.0, UTF8, json4lua, FitzUtils
-- License: GPL v2 or later.
--
--
-- Copyright (C) 2010-2011 Fitzcairn of Cenarion Circle US  
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

-- Upvalues
local KB       = KV.Keyboards;
local L        = KV.Text;
local UI       = KV.UI;
local C        = KV.Constants;
local U        = FitzUtils;

-- Locals
local _format   = string.format


--
-- Turn on/off debugging output
--

U:Debug(true)


--
-- Minimap Icon + Context Menu
--

-- Use LibDBIcon from Ace3 to create a minimap show/hide button.
local g_minimap_icon = LibStub("LibDataBroker-1.1"):NewDataObject("KV_MinimapIcon",
 {
	type = "data source",
	text = UI["KV_MinimapIcon"].text,
	icon = "Interface\\Addons\\KeybindViewer\\img\\icon",
    OnTooltipShow = function(tt)
                       if _G["KV_Frame"]:IsShown() then
                          tt:SetText(UI["KV_MinimapIcon"].tt_on)
                       else
                          tt:SetText(UI["KV_MinimapIcon"].tt_off)
                       end
                    end,
	OnClick       = function(frame, button)
                       if _G["KV_Frame"]:IsShown() then
                          _G["KV_Frame"]:Hide() 
                       else
                          _G["KV_Frame"]:ClearAllPoints()
                          _G["KV_Frame"]:SetPoint("CENTER")
                          _G["KV_Frame"]:Show()
                       end
                    end
})
local icon = LibStub("LibDBIcon-1.0")


--
-- Slash Commands
--

-- Slash commands and localized help messages.
local Cmd = {
   CMD1        = L["/keybindviewer"],
   CMD2        = L["/kbv"],
   
   SHOW        = L["show"],
   SHOW_HELP   = L["Show the KeybindViewer window."],
   
   HIDE        = L["hide"],
   HIDE_HELP   = L["Hide the KeybindViewer window."],
}


-- Helper to color help text
local function ColorCmdTxt(txt)
   return "|cFF0099FF"..txt.."|r"
end


-- Helper to create help output from the command table.
local function HelpCmdHelper(cmd_tbl, s, prefix) 
   prefix = prefix or ""
   for cmd,v in pairs(cmd_tbl) do
      if v.help then
         print(U:Join("\n", s..ColorCmdTxt(prefix..cmd),
                       s.." "..v.help))
      else
         print(HelpCmdHelper(v, s, cmd.." "))
      end
   end
end


-- Handlers for all slash command functionality.
Handlers = {
   [Cmd.SHOW] = {
      help = Cmd.SHOW_HELP,
      run  = function()
                _G["KV_Frame"]:ClearAllPoints()
                _G["KV_Frame"]:SetPoint("CENTER")
                _G["KV_Frame"]:Show()
             end,
   },
   [Cmd.HIDE] = {
      help = Cmd.HIDE_HELP,
      run  = function() _G["KV_Frame"]:Hide() end,
   },
}


-- Dispatch, based off of ideas in "World of Warcraft Programmng 2nd Ed"
local function HandleSlashCmd(msg, tbl)
   local cmd, param = string.match(msg, "^(%w+)%s*(.*)$")
   cmd = cmd or ""
   local e = tbl[cmd:lower()]
   if not e then
      -- Not recognized, output slash command help
      print(ColorCmdTxt(Cmd.CMD1))
      print(ColorCmdTxt(Cmd.CMD2))
      HelpCmdHelper(Handlers, "      ")
   elseif e.run then e.run(param)
   else              HandleSlashCmd(param or "", e) end
end
   

-- Register commands.
SLASH_KEYBINDVIEWER1 = Cmd.CMD1
SLASH_KEYBINDVIEWER2 = Cmd.CMD2
SlashCmdList["KEYBINDVIEWER"] = function (msg)
                                   HandleSlashCmd(msg, Handlers)
                                end


--
-- Handlers
--

-- [4.0.1] Updated to reflect new arg format
function KV_OnEvent(self, event, arg1, name)
   -- This happens after ADDON_LOADED, so can look for saved vars here.
   if event == "PLAYER_ENTERING_WORLD" then
      KV:Init(self)
   end
   -- When a binding, actionbar assignment, or macro changes
   if event == "UPDATE_BINDINGS"        or 
      event == "UPDATE_MACROS"          or 
      event == "ACTIONBAR_SLOT_CHANGED" then 
      U:Print("  --> FIRED: "..event)
      KV:UpdateBinds(self)
   end
end

-- On construction of UI elements...
function KV:OnShow(frame)

end


-- Handle resizing
function KV:OnResize(new_w, new_h)
   if not self.init then return end -- Only handle this if ready.

   -- Get the configured layout
   local layout = KB[KV:GetVar("KV_SelectLayout", true)]
   local num_b  = tonumber(KV:GetVar("KV_ButtonsInput", true))
   local m_side = KV:GetVar("KV_RightOrLeft", true)

   if KV.key_map then
      -- Render the display
      KV:ResizeKeyboardAndMouseFrame(KV.key_map, layout, num_b, m_side, new_w, new_h)
   end
end


-- Handle config changes; refresh the display
function KV:Refresh()
   if not self.init then return end -- Only handle this if ready.
   local frame = KV.parent_frame

   -- Redraw with the currrent width/height
   self:OnResize(frame:GetWidth(), frame:GetHeight())

   -- Update the binds in case we added mouse buttons
   self:UpdateBinds()
end


--
-- Helpers
-- 

-- Update the binds in the addon
function KV:UpdateBinds()
   if not self.init then return end -- Only handle this if ready.

   -- Get a map of bindings and corresponding action info.
   KV:GetBoundActionInfo(KV.bind_map, KV.cmd_map)

   if KV.key_map then
      KV:HighlightBinds(KV.key_map, KV.bind_map, KV.cmd_map)

      -- Update web link
      KV.Link = self:CreateWebLink(KV.key_map, KV.bind_map, KV.cmd_map)
      KV:SetEditBoxInput(_G["KV_UrlBox"], KV.Link)
   end
end


-- Update UI from saved variables.
function KV:UpdateConfig()
   -- Show or hide minimap icon?
   KV:CheckBox(_G["KV_ShowMinimapIcon"],
               KV:GetVar("KV_ShowMinimapIcon", true))

   -- Number of buttons.
   KV:SetEditBoxInput(_G["KV_ButtonsInput"],
                      KV:GetVar("KV_ButtonsInput", true))

   -- Update dropdowns
   UIDropDownMenu_Initialize(_G["KV_RightOrLeft"],
                             UI["KV_OptionsMenu"]["KV_RightOrLeft"][C.LOAD]);
   UIDropDownMenu_Initialize(_G["KV_SelectLayout"],
                             UI["KV_OptionsMenu"]["KV_SelectLayout"][C.LOAD]);

   -- Update binds filter
   KV:CheckBox(_G["KV_Bartender"], KV:GetVar("KV_Bartender", true))
   KV:CheckBox(_G["KV_Dominos"], KV:GetVar("KV_Dominos", true))
   KV:CheckBox(_G["KV_BindPad"], KV:GetVar("KV_BindPad", true))
   KV:CheckBox(_G["KV_PetBar"],  KV:GetVar("KV_PetBar",  true))
   KV:CheckBox(_G["KV_StanceBar"],  KV:GetVar("KV_StanceBar",  true))
   KV:CheckBox(_G["KV_Bar1"],    KV:GetVar("KV_Bar1",    true))
   KV:CheckBox(_G["KV_Bar2"],    KV:GetVar("KV_Bar2",    true))
   KV:CheckBox(_G["KV_Bar3"],    KV:GetVar("KV_Bar3",    true))
   KV:CheckBox(_G["KV_Bar4"],    KV:GetVar("KV_Bar4",    true))
   KV:CheckBox(_G["KV_Bar5"],    KV:GetVar("KV_Bar5",    true))
   KV:CheckBox(_G["KV_Bar6"],    KV:GetVar("KV_Bar6",    true))
   KV:CheckBox(_G["KV_Bar7"],    KV:GetVar("KV_Bar7",    true))
   KV:CheckBox(_G["KV_Bar8"],    KV:GetVar("KV_Bar8",    true))
   KV:CheckBox(_G["KV_Bar9"],    KV:GetVar("KV_Bar9",    true))
   KV:CheckBox(_G["KV_Bar10"],   KV:GetVar("KV_Bar10",   true))
end


-- Run AFTER saved variables have been loaded.
function KV:Init(frame)
   -- Load up the minimap icon
   if not icon:IsRegistered() then
      icon:Register("KV_MinimapIcon", g_minimap_icon, KV_Vals)
      KV.minimap_icon = icon
   end
   if not KV:GetVar("KV_ShowMinimapIcon", true) then
      icon:Hide("KV_MinimapIcon")
   end

   -- Save the parent frame.
   KV.parent_frame = frame

   -- Set the title
   _G["KV_Title"]:SetText(KV.Title)

   -- Set the about string
   KV.About   = KV.Title.." v"..KV.Version..", by Fitzcairn of Cenarion Circle US"
   _G["KV_About"]:SetText(KV.About)

   -- Create and display welcome string.
   KV.Welcome = L["Welcome to "]..KV.About.."!  "..L["Type /kbv for options."]
   print(ColorCmdTxt(KV.Welcome))

   -- Get the configured layout
   local layout = KB[KV:GetVar("KV_SelectLayout", true)]
   local num_b  = KV:GetVar("KV_ButtonsInput", true)
   local m_side = KV:GetVar("KV_RightOrLeft", true)

   -- Create and display the keyboard frame
   KV.frame, KV.key_map = KV:CreateKeyboardAndMouseFrame(frame, layout, num_b, m_side)
   KV:ResizeKeyboardAndMouseFrame(KV.key_map, layout, num_b, m_side, KV.frame:GetWidth(), KV.frame:GetHeight())

   -- Refresh the UI from saved variables.
   self:UpdateConfig()
   
   -- Generate the encoding map for keys
   self:CreateKeyEncoding()

   -- Ready for action!
   KV.init = true

   -- Update the bindings.
   self:UpdateBinds()
end
