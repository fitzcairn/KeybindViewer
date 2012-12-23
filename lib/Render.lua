--
-- Rendering 
-- 
-- File containing all rendering logic for displaying a keyboard/mouse
-- frame onscreen.
--


--
-- Upvalues
--

local KB = KV.Keyboards;
local KA = KV.ActionFilter;
local L  = KV.Text;
local I  = KV_IconMap;

--
-- Local Globals
--

-- For speed
local _insert = table.insert

-- Pad for the hover UI elements
local g_pad  = 4

-- Width of source col in hovers
local g_src_width = 120

-- Width/height for spell icons
local g_action_w_h = 10

-- Map of modifier commands
local g_mods = {
   ["CTRL"]  = 1,
   ["ALT"]   = 1,
   ["SHIFT"] = 1,
}

-- Reserved keyname for the number of mouse buttons to display
local BNUM   = "_b"

-- Reserved keyname for the bind map.
local B      = "_buttons" 

-- Reserved keynames for frames
local F      = "_frame"
local M      = "_mouse"
local MB     = "_mouse_body"
local K      = "_keyboard"
local H      = "_hover"

-- Predeclare object tables
local KeyPool    = {}
local StringPool = {}


--
-- Local helper functions
--

-- Control over frame size
local function GetFrameDims(w, h)
   h = 0.95 * h -- Pad the top
   w = 0.97 * w -- Pad the sides 
   return w,h
end

-- Control over the current proportion of keyboard to mouse
local function GetFrameWidths(w)
   -- Divide into space for the keyboard and space for the mouse
   local keyboard_w = 0.78 * w
   local mouse_w    = 0.20 * w
   return keyboard_w, mouse_w
end

-- Set anchros for keyboard and mouse frames
local function SetMouseKeyboardAnchors(frame, mouse_frame, keyboard_frame, m_side)
   local k_anchor, m_anchor

   -- Figure out where to place what
   if m_side == "Right" then
      k_anchor = "LEFT"
      m_anchor = "RIGHT"
   else
      k_anchor = "RIGHT"
      m_anchor = "LEFT"
   end      

   -- Set the anchors
   local off_y = - 0.02 * frame:GetHeight()
   mouse_frame:ClearAllPoints()
   mouse_frame:SetPoint(m_anchor, frame, m_anchor, 0, off_y)

   keyboard_frame:ClearAllPoints()
   keyboard_frame:SetPoint(k_anchor, frame, k_anchor, 0, off_y)
end

-- Init a keyboard data structure
local function InitKeysStructure(bnum)
   local k = {}
   k[BNUM] = bnum
   k[B]    = {}
   return k
end

-- Generate the name of the frames
local function GetFrameNames(name_override)
   local name  = "KV_Frame"..(name_override or "")
   local kname = name.."Keys"
   local mname = name.."Mouse"
   return name, kname, mname
end

-- Create a hover UI element
local function CreateHover(parent, name)
   local hover_frame = CreateFrame("Frame", name.."Hover", parent);
   hover_frame:SetWidth(200)
   hover_frame:SetHeight(200)
   hover_frame:SetBackdrop({
                              edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                              bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                              tile     = true,
                              tileSize = 8,
                              edgeSize = 8,
                              insets = {
                                 left   = 2,
                                 right  = 2,
                                 top    = 2,
                                 bottom = 2
                              }
                           })

   -- To ensure the hover frame goes over all other frames,
   -- put it in a higher strata.
   hover_frame:SetFrameStrata("DIALOG")
   hover_frame:Hide()

   -- Create and save a pool of keys/strings for display on the hover
   hover_frame._kp = KeyPool:New(hover_frame)
   hover_frame._sp = StringPool:New(hover_frame)

   -- Done
   return hover_frame
end

-- Create a key UI element
local function CreateKey(parent, key_name, txt)
   -- Create and set frame strata
   local frame = CreateFrame("Frame", key_name, parent,
                             "KV_ButtonTemplate")

   -- Crate callbacks to make it easy to manipulate text.
   frame.SetText = function(frame, txt)
                      _G[frame:GetName().."Text"]:SetText(txt)
                   end
   frame.GetText = function(frame)
                      return _G[frame:GetName().."Text"]:GetText()
                   end
   frame.GetTextObj = function(frame)
                         return _G[frame:GetName().."Text"]
                      end

   -- Set the text and text appearance
   frame:SetText(txt)
   frame:GetTextObj():SetFontObject("GameFontNormalSmall")

   -- Set text anchors so the text object expands/contracts
   -- with the key.
   frame:GetTextObj():ClearAllPoints()
   frame:GetTextObj():SetPoint("LEFT", frame, "LEFT")
   frame:GetTextObj():SetPoint("RIGHT", frame, "RIGHT")
   frame:GetTextObj():SetPoint("CENTER", frame, "CENTER")


   -- Add a texture to this frame, and some callbacks to manipulate it
   local tex = frame:CreateTexture(frame:GetName().."Texture")
   tex:SetAllPoints(frame)
   frame.SetTexture = function(frame, t)
                         _G[frame:GetName().."Texture"]:SetTexture(t)
                         _G[frame:GetName().."Texture"]:Show()
                      end
   frame.GetTexture = function(frame, t)
                         return _G[frame:GetName().."Texture"]
                      end

   -- Add a helper function to clear off a key
   frame.Clear = function(frame)
                    frame:ClearAllPoints()
                    frame:SetText("")
                    frame:GetTexture():Hide()
                    frame:GetTextObj():SetPoint("LEFT", frame, "LEFT")
                    frame:GetTextObj():SetPoint("RIGHT", frame, "RIGHT")
                    frame:GetTextObj():SetPoint("CENTER", frame, "CENTER")
                    frame:GetTextObj():SetFontObject("GameFontNormalSmall");
                    frame:Hide()
                 end
   return frame
end

-- Create or resize a key
local function CreateAndResizeKey(parent, key_name, txt, key_map, cmd, w, h)
   -- Index by bind, then keyname
   key_map[B][cmd] = key_map[B][cmd] or {}
   if not key_map[B][cmd][key_name] then
      key_map[B][cmd][key_name] = CreateKey(parent, key_name, txt)
   end
   
   -- Set dimensions
   key_map[B][cmd][key_name]:SetWidth(w)
   key_map[B][cmd][key_name]:SetHeight(h)
   --key_map[B][cmd][key_name]:SetFrameLevel(160)

   return key_map[B][cmd][key_name]
end 

-- Place and render an action on the hover.
-- Returns an updated off_x, off_y
local function RenderHoverAction(frame, off_x, off_y, src_txt, post_txt, action, pad)
   pad = pad or g_pad -- Default spacer

   -- Set up the appearance
   frame:SetWidth(g_action_w_h)
   frame:SetHeight(g_action_w_h)
   --frame:SetFrameLevel(255)

   -- If src_text, place that first.
   if src_txt then
      src_txt:SetPoint("LEFT", frame:GetParent(), "TOPLEFT", off_x,
                       off_y - (frame:GetHeight() / 2))
      src_txt:Show()
      off_x = off_x + src_txt:GetStringWidth() + pad
      --off_x = max(off_x, g_src_width)
   end

   -- Set the texture/name (for macro), and show
   frame:SetTexture(action.texture)
   if action.type == "macro" then
      frame:GetTextObj():SetWidth(g_action_w_h)
      frame:GetTextObj():SetFontObject("GameFontHighlightSmall");
      frame:SetText(action.name)
   end
   frame:SetPoint("TOPLEFT", frame:GetParent(), "TOPLEFT", off_x, off_y)
   frame:Show()

   -- Update x offset
   off_x = off_x + frame:GetWidth()  + pad

   -- If post_text, place that.
   if post_txt then
      post_txt:SetPoint("LEFT", frame:GetParent(), "TOPLEFT", off_x,
                       off_y - (frame:GetHeight() / 2))
      post_txt:Show()
      off_x = off_x + post_txt:GetStringWidth() + pad
   end

   -- Update y offsets
   off_y = off_y - frame:GetHeight() - pad
   
   return off_x, off_y
end

-- Place and render a key on the hover.
-- Returns an updated off_x, off_y
local function RenderHoverKey(key, otherkey, off_x, off_y, pre_txt, post_txt, pad)
   pad = pad or g_pad -- Default spacer

   -- Set up the appearance
   key:SetWidth(otherkey:GetWidth())
   key:SetHeight(otherkey:GetHeight())
   key:SetText(otherkey:GetText())
   --key:SetFrameLevel(255)

   -- If pre_text, place that first.
   if pre_txt then
      pre_txt:SetPoint("LEFT", key:GetParent(), "TOPLEFT", off_x,
                       off_y - (key:GetHeight() / 2))
      pre_txt:Show()
      off_x = off_x + pre_txt:GetStringWidth() + pad
   end

   -- Set location and show
   key:SetPoint("TOPLEFT", key:GetParent(), "TOPLEFT", off_x, off_y)
   key:Show()

   -- Update offsets
   off_x = off_x + key:GetWidth()  + pad

   -- If post_text, place that.
   if post_txt then
      post_txt:SetPoint("LEFT", key:GetParent(), "TOPLEFT", off_x,
                       off_y - (key:GetHeight() / 2))
      post_txt:Show()
      off_x = off_x + post_txt:GetStringWidth() + pad
   end

   -- Update offsets
   off_y = off_y - key:GetHeight() - pad
   
   return off_x, off_y
end


--
-- Object definitions
--

-- Define a reusable pool of keys for use in the UI hover.
KeyPool.mt    = {}
KeyPool.mt.__index = function(kp, i)
                        if not kp.k[i] then
                           kp.k[i] = CreateKey(kp.f, "KP"..i, "")
                        end
                        kp.k[i]:Clear()
                        return kp.k[i]
                     end
function KeyPool:New(frame)
   local o = { f = frame, k = {} }
   setmetatable(o, self.mt)
   return o
end

-- Define a reusable pool of strings for use in the UI hover.
StringPool.mt    = {}
StringPool.mt.__index = function(sp, i)
                        if not sp.s[i] then
                           sp.s[i] = sp.f:CreateFontString("SP"..i)
                           sp.s[i]:SetFontObject("GameFontHighlight");
                        end
                        sp.s[i]:ClearAllPoints()
                        return sp.s[i]
                     end
function StringPool:New(frame)
   local o = { f = frame, s = {} }
   setmetatable(o, self.mt)
   return o
end


--
-- Keyboard Button Rendering
--

-- Render the key
local function KV_ButtonOnLoad(b)
   -- Differentiate buttons bound to action slots with actions in them.
   if b._hover then
      if b._is_action then
         b:SetBackdropColor(1.0, 0.0, 0.0, 1)
      else
         b:SetBackdropColor(0.5, 0.0, 0.0, 1)
      end
   else
      b:SetBackdropColor(0.75, 0.75, 0.75, 1)
   end
end

-- Build mouseover callback.
local function KV_ButtonOnMouseEnter(self)
   local hover    = self._hover
   local kp       = self._hover._kp
   local sp       = self._hover._sp

   -- Turn on bind
   self:SetBackdropColor(0.0, 1.0, 0.0, 1)

   -- Sort the binds table in order of actions followed by 
   -- least -> most mods required.
   table.sort(self._binds, function(a, b) 
                           if a[3] and not b[3] then return true end
                           if b[3] and not a[3] then return false end
                           return #a[1] < #b[1]
                        end)

   -- Iterate through binds table, populating UI hover and
   -- highlighting the mod keys that can be used with this key.
   -- t = { mods, cmd, action }
   local mods, cmd, action, i, j, ms       = nil, nil, nil, 1, 1, 1
   local off_y, off_x, max_x, tmp_y, min_y = -g_pad, 0, 0, 0, 0
   local ui_key, m_bs, desc, render_obj, is_action
   local render_q = {}

   -- Local helpers to reduce repeated code

   -- Advance to the next button in the button pool, and 
   -- update the current x/maxx/maxy offsets.
   local _adv_key   = function(x,y)
                         off_x = x
                         min_y = min(min_y, y) -- We're building down, y is neg.
                         max_x = max(max_x, x) -- We're building right, x is pos.
                         i = i + 1  
                      end

   -- Render a text label
   local _txt       = function(txt)
                         local t = sp[j]
                         j = j + 1 
                         t:SetText(txt)
                         return t
                      end

   -- Render a key, and advance the counters
   local _hk_render = function(btn, pre_txt, post_txt)
                         _adv_key(RenderHoverKey(kp[i], btn,
                                                 off_x, off_y,
                                                 pre_txt, post_txt))
                      end

   -- Render an action texture for a keybind, and advance the counters
   local _ha_render = function(btn, action, post_txt)
                         _adv_key(RenderHoverAction(kp[i],
                                                    off_x, off_y,
                                                    _txt("("..action.src..")"),
                                                    post_txt,
                                                    action))
                      end

   for _,t in ipairs(self._binds) do
      mods, cmd, action = unpack(t)
      min_y             = -g_pad
      wipe(render_q)

      -- Set up a queue of things to render.
      -- If this bind is for one or more actions, first render the icon[s], then the key[s]
      if action then
         for _,a in pairs(action) do
            _insert(render_q, {a, true})
         end
      else
         _insert(render_q, {_txt(KA[cmd]..": "), false})
      end

      -- Process the render queue for this hover.
      for _,job in ipairs(render_q) do
         off_x = g_pad
         render_obj, is_action = unpack(job)
 
         -- Render the action or command.
         if is_action then
            if #mods == 0 then
               _ha_render(self, render_obj, _txt(" "))
            else
               _ha_render(self, render_obj, _txt(" "..L["with"].." "))
            end
         else
            _hk_render(self, render_obj, _txt(" "))
         end

         -- Render in over + highlight the mod keys on the keyboard
         -- that are used with this key.
         for _,mod_tuple in ipairs(mods) do
            ui_key, m_bs = unpack(mod_tuple)
            
            -- Only one key for this mod?  Render.
            if #m_bs == 1 then
               _hk_render(m_bs[1])

               -- If more than one keys in mod, render bracket before
               -- first one. and after last one
            else
               _hk_render(m_bs[1], _txt("["), _txt("or"))

               -- Render all the keys that give the same mod cmd.
               for n = 2,#m_bs-1, 1 do
                  _hk_render(m_bs[n], nil, _txt("or"))
               end

               -- Render last + bracket
               _hk_render(m_bs[#m_bs], nil, _txt("]"))
            end

            -- Highlight all mod keys
            for _,m in ipairs(m_bs) do
               m:SetBackdropColor(0.0, 1.0, 1.0, 1)
            end

            -- Space the mod key groups by extra pads
            off_x = off_x + (2 * g_pad)

         end -- Mod handler loop

         -- Update row y-spacing
         off_y = min_y

      end  -- Render queue loop

   end

   -- Resize and show the newly constructed hover.
   hover:ClearAllPoints()
   hover:SetHeight(- off_y)
   hover:SetWidth(max_x)

   -- Position hover
   local h_x_offset   = 0
   local h_y_offset   = -g_pad
   local hp_anchor    = "BOTTOM"
   local h_anchor     = "TOP"
   local screen_w     = _G["UIParent"]:GetWidth()
   local pos_x, pos_y = self:GetCenter()

   -- Ensure our width is less than the screen--otherwise, can't do anything.
   if max_x < screen_w then

      -- Handle left side.
      if (max_x / 2) > pos_x then
         h_x_offset = (max_x / 2) - pos_x
      end
      -- Handle right side.
      if pos_x + (max_x / 2) > screen_w then
         h_x_offset = screen_w - (pos_x + (max_x / 2))
      end
   end

   -- Handle bottom
   if pos_y + off_y < 80 then -- account for action bar height
      hp_anchor  = "TOP"
      h_anchor   = "BOTTOM"
      h_y_offset = g_pad
   end

   -- Position and show
   hover:SetPoint(h_anchor, self, hp_anchor, h_x_offset, h_y_offset)
   hover:Show()
end

-- Mouseout callback
local function KV_ButtonOnMouseOut(self)
   local hover = self._hover
   local kp    = self._hover._kp
   local sp    = self._hover._sp
   local ui_key, m_bs

   -- Hide the hover.
   self._hover:Hide()

   -- Hide the keys/strings.
   -- We do this in addition to hiding the parent so the next
   -- hover render can select what to show.
   for i = 1, #kp.k, 1 do kp[i]:Clear() end
   for i = 1, #sp.s, 1 do sp[i]:Hide() end

   -- Turn off bind
   KV_ButtonOnLoad(self)
   
   -- Iterate through associated mods and turn off
   -- t = { mods, cmd, action }
   for _,t in ipairs(self._binds) do
      for _,mod_tuple in ipairs(t[1]) do
         ui_key, m_bs = unpack(mod_tuple)
         for _,m in ipairs(m_bs) do
            m:SetBackdropColor(0.75, 0.75, 0.75, 1)
         end
      end
   end
end



--
-- API
--

-- Create a keyboard within the frame.
-- References to key frames are stored in the keys argument, passed
-- by reference.
function KV:CreateOrResizeKeyboard(keyboard_frame, board, name, key_map, w_override, h_override)
   -- W/H
   local w      = w_override or keyboard_frame:GetWidth()
   local h      = h_override or keyboard_frame:GetHeight()

   -- Board is layed out in percentages of input absolute dimensions.
   -- Calculate the number of pixels in one percent w/h.
   local _get_px = function(tab, k, val, dim)
                      if not val then val = (tab[k] or tab["_default"]) end
                      return (val * (dim / 100))
                   end
   local _get_w  = function(k, kw) return _get_px(board.default_widths, k, kw, w) end
   local _get_h  = function(k, kh) return _get_px(board.default_heights, k, kh, h)         end

   -- Create locals for efficiency
   local i       = 0
   local pad_w   = _get_w("_")
   local pad_h   = _get_h("_")
   local key_w   = 0
   local key_h   = 0
   local row_h   = _get_h("_default")
   local curr_x  = 0
   local curr_y  = 0 -- - pad_h
   local cmd,key,key_name,key_tuple, button

   -- Loop through the board layout and construct the keys.
   for _,row in ipairs(board.layout) do
      -- Update width for new row.
      curr_x  = pad_w

      for _, key_tuple in ipairs(row) do
         cmd, key, key_w, key_h = unpack(key_tuple)

         -- Covert dims to px
         key_w = _get_w(cmd, key_w)
         key_h = _get_h(cmd, key_h)

         -- If there is no key, don't create a button, but still add space.
         if key then
            key_name = name.."_"..i

            -- Create, size, and position the key
            CreateAndResizeKey(keyboard_frame, key_name, key, key_map, cmd,
                               key_w, key_h)
            key_map[B][cmd][key_name]:SetPoint("TOPLEFT", keyboard_frame, "TOPLEFT",
                                         curr_x, curr_y)
            i = i + 1
         end
         curr_x = curr_x + key_w + pad_w
      end
      
      -- Update height for new row, accounting for empty rows.
      if #row > 0 then  curr_y = curr_y - row_h - pad_h
      else              curr_y = curr_y - pad_h end
   end

   -- Update the width/height for spell icons
   g_action_w_h = row_h
end


-- Create a mouse within the frame.
-- References to key frames are stored in the keys argument, passed
-- by reference.
function KV:CreateOrResizeMouse(mouse_frame, name, key_map, w_override, h_override)
   -- Default to 3-button mouse unless specified
   if not key_map[BNUM] or key_map[BNUM] < 3 then key_map[BNUM] = 3 end

   -- Set the name for the body frame
   local b_name = name.."Body"

   -- W/H
   local w      = w_override or mouse_frame:GetWidth()
   local h      = h_override or mouse_frame:GetHeight()

   -- Create the mouse picture from Frame primitives.  Ugly, but oh well.
   local m_w, m_h, b_w, b_h, m_s = w, h, 0, 0, 0
   local m_b_h = 0.50 -- Proportion of mouse body button consumes
   local off_y = 0


   -- Make the mouse, and room for extra buttons on the side
   m_w = w * 0.60
   m_h = 0.60 * h
   m_s = 0.01 * w   -- spacer for display elements
   b_w = w - m_w - m_s
   b_h = (h + off_y - (key_map[BNUM] - 3 - 1) * m_s) / (key_map[BNUM] - 3)
   if b_h > (0.4 * b_w) then b_h = (0.4 * b_w) end

   -- Mouse body frame
   if not key_map[MB] then key_map[MB] = CreateFrame("Frame", b_name, mouse_frame) end
   local mouse = key_map[MB]
   mouse:SetPoint("TOPLEFT", mouse_frame, "TOPLEFT", 0, off_y)
   --mouse:SetFrameLevel(150)
   mouse:SetWidth(m_w)
   mouse:SetHeight(m_h)
   mouse:Show()
   mouse:SetBackdrop({
                        edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
                        edgeSize = 8,
                     })



   -- Create a table of buttons.
   -- { CMD, txt shown, width_override, height_override }
   local button_table = {
      { "BUTTON1",        "1", m_w * 0.45,  m_h * m_b_h },
      { "BUTTON2",        "2", m_w * 0.45,  m_h * m_b_h },
      { "MOUSEWHEELUP",   "U", m_w * 0.10, (m_h * m_b_h)  / 3 },
      { "BUTTON3",        "3", m_w * 0.10, (m_h * m_b_h)  / 3 },
      { "MOUSEWHEELDOWN", "D", m_w * 0.10, (m_h * m_b_h)  / 3 },
   }
   local cmd,key_name,key_tuple,button
   local tmp_b = {}

   -- Create all the buttons
   for _,key_tuple in ipairs(button_table) do
      cmd, button, key_w, key_h = unpack(key_tuple)
      key_name = b_name.."_"..button
      -- Create and size the key, saving by button
      tmp_b[cmd] = CreateAndResizeKey(mouse, key_name, button, key_map,
                                      cmd, key_w, key_h)
   end

   -- Position the buttons.
   tmp_b["BUTTON1"]:SetPoint("TOPLEFT", mouse, "TOPLEFT", 0, 0, "1")
   tmp_b["BUTTON2"]:SetPoint("TOPRIGHT", mouse, "TOPRIGHT", 0, 0, "2")
   tmp_b["MOUSEWHEELUP"]:SetPoint("TOP", mouse, "TOP", 0, 0)
   tmp_b["BUTTON3"]:SetPoint("TOP", tmp_b["MOUSEWHEELUP"], "BOTTOM", 0, 0)
   tmp_b["MOUSEWHEELDOWN"]:SetPoint("TOP", tmp_b["BUTTON3"], "BOTTOM", 0, 0)

   -- Need more buttons?
   if key_map[BNUM] > 3 then
      local i, b = 4, nil
      while i <= key_map[BNUM] do
         b = CreateAndResizeKey(mouse_frame, name.."_"..i, "Button "..i, key_map,
                                "BUTTON"..i, b_w, b_h)
         b:SetPoint("TOPRIGHT", mouse_frame, "TOPRIGHT", 0, off_y)

         i = i + 1
         off_y = off_y - b_h - m_s
      end
   end

end


-- Resize a keyboard and mouse frame.
function KV:ResizeKeyboardAndMouseFrame(key_map, board, num_b, m_side, new_w, new_h, name_override)
   -- Set the number of mouse buttons.  Hide all buttons outside of what we need.
   -- No sense deleting in case we need to use them again.
   local _button = function (i, show) 
                      if key_map[B]["BUTTON"..i] then
                         for _,b in pairs(key_map[B]["BUTTON"..i]) do
                            if show then b:Show()
                            else         b:Hide() end
                         end
                      end
                   end
   for i = 1, key_map[BNUM], 1 do _button(i, false)  end
   for i = 1, num_b, 1         do _button(i, true) end

   -- Reset the number of buttons
   key_map[BNUM] = num_b

   -- Get frame names
   local name, kname, mname = GetFrameNames(name_override)

   -- Get references to mouse and keyboard frame
   local frame, mouse_frame, keyboard_frame = key_map[F], key_map[M], key_map[K]

   -- Get the adjusted widths
   local w, h = GetFrameDims(new_w, new_h)

   -- Resize the parent frame.
   frame:SetWidth(w)
   frame:SetHeight(h)

   -- Set the new widths for each frame
   local keyboard_w, mouse_w = GetFrameWidths(w)
   mouse_frame:SetWidth(mouse_w)
   mouse_frame:SetHeight(h)
   keyboard_frame:SetWidth(keyboard_w)
   keyboard_frame:SetHeight(h)

   -- Anchor frames
   SetMouseKeyboardAnchors(frame, mouse_frame, keyboard_frame, m_side)

   -- Call out to resize the display elements
   KV:CreateOrResizeMouse(mouse_frame, mname, key_map, mouse_w, h)
   KV:CreateOrResizeKeyboard(keyboard_frame, board, kname, key_map, keyboard_w, h)
end


-- Create a frame as a child of the frame passed in, and populate it with
-- a keyboard layout made of buttons.
-- Returns a ref to the frame, and table of keyname -> key button
function KV:CreateKeyboardAndMouseFrame(parent, board, num_b, m_side, anchor, offx, offy, w_override, h_override, name_override)
   -- Create the data structure to store all the display buttons
   local key_map = InitKeysStructure(num_b)

   -- Construct board name
   local name, kname, mname = GetFrameNames(name_override)

   -- If no parent frame, use the UIParent
   parent       = parent or UIParent

   -- Display characteristics
   anchor       = anchor     or "CENTER"
   offx         = offx       or 0
   offy         = offy       or 0
   local w      = w_override or parent:GetWidth()
   local h      = h_override or parent:GetHeight()
   
   -- Create board frame
   local frame  = CreateFrame("Frame", name, parent);
   frame:SetPoint(anchor, offx, offy)
   frame:SetWidth(w)
   frame:SetHeight(h)
   --frame:SetFrameLevel(130)
   key_map[F] = frame

   --frame:SetBackdrop(backdrop)

   -- Divide into space for the keyboard and space for the mouse
   local keyboard_w, mouse_w = GetFrameWidths(w)

   -- Create mouse frame
   local mouse_frame = CreateFrame("Frame", mname, frame);
   mouse_frame:SetWidth(mouse_w)
   mouse_frame:SetHeight(h)
   --mouse_frame:SetFrameLevel(140)
   key_map[M] = mouse_frame

   -- Create keyboard frame
   local keyboard_frame = CreateFrame("Frame", kname, frame);
   keyboard_frame:SetWidth(keyboard_w)
   keyboard_frame:SetHeight(h)
   --keyboard_frame:SetFrameLevel(140)
   key_map[K] = keyboard_frame

   -- Create the hover frame to show binds.
   key_map[H] = CreateHover(frame, name)

   -- Anchor frames
   SetMouseKeyboardAnchors(frame, mouse_frame, keyboard_frame, m_side)

   -- Call out to create the display elements
   KV:CreateOrResizeMouse(mouse_frame, mname, key_map, mouse_w, h)
   KV:CreateOrResizeKeyboard(keyboard_frame, board, kname, key_map, keyboard_w, h)

   return frame, key_map
end


-- Given a keyboard and bind map, create callbacks and 
-- highlight all keys with binds. Details on input args:
--
-- key_map: keys to actual frames.  Example:
--   key_map[_B] = { key = { name1 = <frame1>, name2 = <frame2>...}}
--
-- bind_map: ui commnads to keys.  Example:
--   bind_map    = { "ACTIONBAR1" = { "ALT-1", "Z" } } 
--
-- cmd_map: ui commands to action info.  Example:
--   cmd_map     = { "ACTIONBAR1" = { id = xxx, type = xxx, name = xxx, texture...}}
--
function KV:HighlightBinds(key_map, bind_map, cmd_map)
   local mods = {}
   local btns = {}
   local keys = {}
   local bind = nil
   local actn = nil

   -- Clear all existing binds being displayed.
   for _,btns in pairs(key_map[B]) do
      for k,b in pairs(btns) do
         -- Ensure list of binds for this key exists.
         b._binds = b._binds or {}
         wipe(b._binds)

         -- Clear refs
         b._is_action = false
         b._hover     = nil

         -- Clear scripts
         b:SetScript("OnEnter", nil)
         b:SetScript("OnLeave", nil)

         -- Render bind key
         KV_ButtonOnLoad(b)
      end
   end

   -- Iterate over binds -> cmd map to create callbacks
   local _find   = string.find
   local _gmatch = string.gmatch
   for cmd,keys in pairs(bind_map) do
      for _,key in ipairs(keys) do
         bind = nil
         mods = {}

         -- Handle special cases involving the "-" key, which
         -- the split barfs on.
         if _find(key, "-$") then
            bind = key_map[B]["-"] or nil
         end

         -- Split up compound binds with mods
         for k in _gmatch(key, "[^-]+") do
            if not g_mods[k] then
               -- Non-mod keybind key.
               -- Save the list of buttons that issue that keystroke to the
               bind = key_map[B][k] or nil
            else
               -- Handle mod keys.
               -- Save the list of buttons that can issue this mod cmd to
               -- the UI.
               btns = {}
               for n,m in pairs(key_map[B][k]) do
                  _insert(btns, m) 
               end
               _insert(mods, { k, btns })
            end
         end

         -- Add a callback to the bind key that highlights the bind
         -- and all mods on mouseover.
         if bind then
            -- If this bind issues an action slot command to the UI
            -- and there is something assigned to that slot, save
            -- the action info block.
            actn = cmd_map[cmd] or nil

            -- Note that we only care about an extreme subset of poss.
            -- keyboard binds--the whole damn board would be lit up like
            -- a christmas tree otherwise.  Filter through the localized
            -- CMD -> description map, and don't highlight/display binds
            -- for any CMD we don't have a description for.
            if actn or KA[cmd] then
               for _,b in pairs(bind) do
                  -- Does this bind power an action?
                  b._is_action = b._is_action or (actn ~= nil)
                  
                  -- Insert an entry of { mods, cmd, actn } into the binds list.
                  _insert(b._binds, { mods, cmd, actn } )
                  
                  -- Save a ref to the hover frame
                  b._hover  = key_map[H]

                  -- Render bind key
                  KV_ButtonOnLoad(b)
                  
                  -- Assign callbacks
                  b:SetScript("OnEnter", KV_ButtonOnMouseEnter)
                  b:SetScript("OnLeave", KV_ButtonOnMouseOut)
               end
            end
         end
      end
   end

end
