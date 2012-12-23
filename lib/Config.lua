--
-- UI Config libary.
-- Implements the UI described in UI.lua
--

-- Upvalues
local C          = KV.Constants;
local UI         = KV.UI;
local U          = FitzUtils;


--
-- Internal Helpers
--

-- Run a callback for a widget, if it is defined in the UI layout.
local function RunCb(w, type) 
   local cb = UI[w:GetParent():GetName()][w:GetName()]
   if cb and cb[type] then return cb[type](w) end
end

-- Disable a widget.
function KV:DisableWidget(w, no_text)
   if w.SetFontObject  then
      w:SetFontObject("GameFontDisable")
   end
   if w.ClearFocus     then w:ClearFocus()                 end
   if w.Disable        then w:Disable()                    end
   if w.EnableKeyboard then w:EnableKeyboard(false)        end
   if w.EnableMouse    then w:EnableMouse(false)           end

   -- If there's a text label for this, disable unless forbidden
   if _G[w:GetName().."Text"] and not no_text then
      self:DisableWidget(_G[w:GetName().."Text"])
   end
end


--
-- General Config Functions
--

-- Put/Get a config value to the global config table.
function KV:SetVar(name, value)
   KV_Vals[name] = value
end
function KV:GetVar(...)
   local name    = select(1, ...)
   local allow_default = select(2, ...) or false
   if KV_Vals[name] ~= nil then return KV_Vals[name]
   elseif allow_default then return self.config_defaults[name] end
end


--
-- Block Config
--

-- Init a block of config widgets
function KV:LoadBlock(frame, label)
   -- Get text from UI layout.
   txt = UI[frame:GetName()]
   if not txt then return end

   -- Set the label.
   label:SetText(txt.label)
end


--
-- Widget: Tooltips
-- 

-- Show/Hide a tooltip for a widget at optional arg anchor.
-- If anchor isn't specific, anchor to widget.
local function ShowWidgetToolTip(block, widget, anchor)
   -- Get localized text, if there isn't any we're done.
   txt_table = UI[block:GetName()][widget:GetName()]
   if not (txt_table and txt_table.tt) then return end
   
   -- Pick anchor and set tooltip.
   if not anchor then anchor = widget end
   GameTooltip:SetOwner(anchor, "ANCHOR_TOPRIGHT");
   GameTooltip:SetText(txt_table.tt);
   GameTooltip:Show();
end

-- Helper to show/hide a tooltip for a slider button,
-- which is a grandchild of a block.
local function ShowDropDownButtonToolTip(button)
   local slider = button:GetParent()
   local block  = slider:GetParent()
   ShowWidgetToolTip(block, slider, button)
end


--
-- Widget: DropDown Menu
--

-- Initial load of a dropdown--called from XML OnLoad.
function KV:CreateDropDownMenu(block, frame, button, label)
   local fname = frame:GetName()

   -- Init menu with saved init function
   UIDropDownMenu_Initialize(frame, UI[block:GetName()][C.LOAD]);
   UIDropDownMenu_SetWidth(frame, 80);

   -- Set tooltip.  Note: keep the tooltip showing for both the button
   -- and the dropdown.
   button:SetScript("OnEnter", ShowDropDownButtonToolTip);
   button:SetScript("OnLeave", function() GameTooltip:Hide(); end);

   -- Get localized text and set label
   txt_table = UI[block:GetName()][fname]
   if not txt_table then return end
   label:SetText(txt_table.label)
end

-- Helper called for dropdown OnEnter to create tooltip
function KV:CreateDropDownToolTip(button)
   ShowDropDownButtonToolTip(button);
end

-- Callback for all Dropdown Menu options
function KV_OnOptionSelect(self, opt_id, menu)
   local menu_id = self:GetID()
   UIDropDownMenu_SetSelectedID(menu, menu_id)
   KV:SetVar(menu:GetName(), opt_id) 

   -- If an option callback saved, call it.
   RunCb(menu, C.CLICK)
end

-- Helper to add buttons to a dropdown.  Uses pre-created
-- tables in UIDropDownMenu.lua to save memory.
function KV:AddMenuButton(menu, id, is_title, txt_tbl)
   local info = UIDropDownMenu_CreateInfo()  
   if is_title then
      info.isTitle         = true
      info.checked         = nil
      info.notClickable    = true
      info.notCheckable    = true
      info.fontObject      = GameFontNormalSmallLeft
   else
      info.isTitle         = nil
      info.func            = KV_OnOptionSelect
      info.arg1            = id
      info.arg2            = menu
      info.tooltipOnButton = true
      info.value           = id
      local selected  = KV:GetVar(menu:GetName(), true)
      if selected and selected == id then info.checked = true
      else                                info.checked = nil end
   end
     
   -- Append any localized text and add button
   if txt_tbl then
      for k,v in pairs(txt_tbl) do 
         info[k] = v
      end
   end

   -- Save the option id for this menu item and add it
   KV:SetVar(menu:GetName()..id, menu._menu_id)
   UIDropDownMenu_AddButton(info)
   menu._menu_id = menu._menu_id + 1
end
   

--
-- Widget: Check Boxes
--

-- Check a check box.
function KV:CheckBox(cb, enable)
   if not cb:IsEnabled() then return end
   cb:SetChecked(enable)
   self:OnCheck(cb)
end

-- Init a check box
function KV:LoadCheckBox(block, cb)
   -- Get text from UI layout.
   txt_table = UI[block:GetName()][cb:GetName()]
   if not txt_table then return end

   -- Set tool tip (TODO: make more complete)
   cb.tooltipText = txt_table.tt

   -- Set the label
   local label = _G[cb:GetName() .. "Text"]
   label:SetText(txt_table.label)

   -- Check default, and save initial state.
   if self:GetVar(cb:GetName(), true) then cb:SetChecked(true) end
   self:OnCheck(cb)
end

-- Handle a config option click.
function KV:OnCheck(cb)
   if cb:GetChecked() then
      U:Print(cb:GetName().." is CHECKED!")
      self:SetVar(cb:GetName(), true)
   else
      self:SetVar(cb:GetName(), false)
   end
   RunCb(cb, C.CLICK)
end


--
-- Widget: Buttons
--

-- Init a Button
function KV:LoadButton(block, button)
   -- Get text from UI layout.
   txt_table = UI[block:GetName()][button:GetName()]
   if not txt_table then return end

   -- Set tool tip (TODO: make more complete)
   button.tooltipText = txt_table.tt

   -- Set the text.
   button:SetText(txt_table.label)
   button:SetDisabledFontObject("GameFontDisable")

   -- If there's a load callback, run it.
   RunCb(button, C.LOAD)
end

-- Handle a config button click.
function KV:OnClick(b)
   RunCb(b, C.CLICK)
end

-- Helper called for button OnEnter
function KV:CreateButtonToolTip(b)
   ShowWidgetToolTip(b:GetParent(), b, nil);
end


--
-- Widget: Edit Box (+ label)
--

-- Set a value for the edit box
function KV:SetEditBoxInput(editbox, val)
   self:SetVar(editbox:GetName(), val)
   editbox:SetCursorPosition(0)
   if type(val) == number then val = tostring(val) end
   editbox:SetText(val)
end

-- Set default value for edit box
function KV:SetEditBoxDefInput(editbox)
   local def = self:GetVar(editbox:GetName(), true)
   if def == nil then return end
   self:SetEditBoxInput(editbox, def)
end

-- Load an edit box.
function KV:LoadEditBox(block, editbox, label)
   -- Set tt and label
   txt_table = UI[block:GetName()][editbox:GetName()]
   editbox.tooltipText = txt_table.tt
   label:SetFontObject("GameFontNormal");
   label:SetText(txt_table.label);

   -- Set any default values.
   self:SetEditBoxDefInput(editbox)
end

-- Helper called for EditBox OnEnter
function KV:CreateEditBoxToolTip(editbox)
   ShowWidgetToolTip(editbox:GetParent(), editbox);
end

-- Helper called to clean input, set the default, and
-- save values for INT input.  Used we lose keyboard focus.
-- Limit is the lowest possible integer value.
function KV:SaveEditBoxIntValue(editbox, llimit, ulimit)
   local t = editbox:GetText()

   -- Remove any bad characters.
   t, _ = t:gsub("[^%d]", "")
   -- Remove any leading zeros
   t, _ = t:gsub("^0*", "")
 
   -- If we didn't get anything, save the default
   if t:len() == 0 then 
      self:SetEditBoxDefInput(editbox)
   else
      if tonumber(t) < llimit then t = tostring(llimit) end
      if tonumber(t) > ulimit then t = tostring(ulimit) end
      editbox:SetText(t)
      self:SetVar(editbox:GetName(), tonumber(t))
   end
end


--
-- Widget: Dialog Popup
--

-- Load a dialog box.
function KV:LoadDialog(frame, title)
   -- Get text from localization.
   txt = UI[frame:GetName()]
   if not txt then return end
   if title and txt.title then title:SetText(txt.title) end
end

-- Show dialog box.
function KV:ShowDialog(frame)
   -- Show dialog box in center of screen by default.
   frame:ClearAllPoints()
   frame:SetPoint("CENTER", frame:GetParent(), "CENTER", 0, 0)
   frame:Show()
end

-- Hide dialog box.
function KV:HideDialog(frame)
   -- Hide the dialog box
   frame:Hide()
end

