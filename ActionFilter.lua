--
-- Action Filter
--
-- This file lists the Blizzard UI command strings for the actions
-- that are shown on KeybindViewer along with actionbar binds.  The
-- localized descriptions are what is shown in the hover.
--

-- Upvalues
local L          = KV.Text;


-- Actions shown in the addon UI
KV.ActionFilter = {
   ["TARGETPET"] = L["Target Pet"],
   ["TARGETTALKER"] = L["Target Talker"],
   ["TARGETFOCUS"] = L["Target Focus"],
   ["STRAFERIGHT"] = L["Strafe Right"],
   ["TOGGLEGAMEMENU"] = L["Game Menu"],
   ["TARGETPARTYPET2"] = L["Target Party Pet 2"],
   ["ASSISTTARGET"] = L["Assist Target"],
   ["TOGGLERUN"] = L["Run"],
   ["TARGETPARTYPET1"] = L["Target Party Pet 1"],
   ["TARGETLASTHOSTILE"] = L["Target Last Hostile"],
   ["TARGETPARTYMEMBER2"] = L["Target Party Member 2"],
   ["TARGETPARTYPET3"] = L["Target Party Pet 3"],
   ["TOGGLEAUTORUN"] = L["Auto Run"],
   ["TURNRIGHT"] = L["Turn Right"],
   ["STOPATTACK"] = L["Stop Attack"],
   ["TARGETPARTYMEMBER1"] = L["Target Party Member 1"],
   ["TARGETNEARESTFRIENDPLAYER"] = L["Target Nearest Friendly Player"],
   ["STRAFELEFT"] = L["Strafe Left"],
   ["TARGETPARTYMEMBER3"] = L["Target Party Member 3"],
   ["TARGETPREVIOUSFRIENDPLAYER"] = L["Target Previous Friendly Player"],
   ["MOVEFORWARD"] = L["Forward"],
   ["DISMOUNT"] = L["Dismount"],
   ["SITORSTAND"] = L["Sit/Stand"],
   ["STARTATTACK"] = L["Start Attack"],
   ["TARGETSELF"] = L["Target Self"],
   ["TURNLEFT"] = L["Turn Left"],
   ["FOCUSTARGET"] = L["Set Focus Target"],
   ["SCREENSHOT"] = L["Screenshot"],
   ["MOVEBACKWARD"] = L["Backpedal"],
   ["TARGETMOUSEOVER"] = L["Target Mouseover"],
   ["STOPCASTING"] = L["Stop Casting"],
   ["JUMP"] = L["Jump"],
   ["TARGETNEARESTENEMY"] = L["Target Nearest Enemy"],
   ["TARGETPREVIOUSFRIEND"] = L["Target Previous Friend"],
   ["ATTACKTARGET"] = L["Attack Target"],
   ["TARGETLASTTARGET"] = L["Target Last Target"],
}


-- Lookup table for actions shown in the web tool.
KV.ActionFilterEncodeList = {
   ["TARGETPET"]                  = 0,
   ["TARGETTALKER"]               = 1,
   ["TARGETFOCUS"]                = 2,
   ["STRAFERIGHT"]                = 3,
   ["TOGGLEGAMEMENU"]             = 4,
   ["TARGETPARTYPET2"]            = 5,
   ["ASSISTTARGET"]               = 6,
   ["TOGGLERUN"]                  = 7,
   ["TARGETPARTYPET1"]            = 8,
   ["TARGETLASTHOSTILE"]          = 9,
   ["TARGETPARTYMEMBER2"]         = 10,
   ["TARGETPARTYPET3"]            = 11,
   ["TOGGLEAUTORUN"]              = 12,
   ["TURNRIGHT"]                  = 13,
   ["STOPATTACK"]                 = 14,
   ["TARGETPARTYMEMBER1"]         = 15,
   ["TARGETNEARESTFRIENDPLAYER"]  = 16,
   ["STRAFELEFT"]                 = 17,
   ["TARGETPARTYMEMBER3"]         = 18,
   ["TARGETPREVIOUSFRIENDPLAYER"] = 19,
   ["MOVEFORWARD"]                = 20,
   ["DISMOUNT"]                   = 21,
   ["SITORSTAND"]                 = 22,
   ["STARTATTACK"]                = 23,
   ["TARGETSELF"]                 = 24,
   ["TURNLEFT"]                   = 25,
   ["FOCUSTARGET"]                = 26,
   ["SCREENSHOT"]                 = 27,
   ["MOVEBACKWARD"]               = 28,
   ["TARGETMOUSEOVER"]            = 29,
   ["STOPCASTING"]                = 30,
   ["JUMP"]                       = 31,
   ["TARGETNEARESTENEMY"]         = 32,
   ["TARGETPREVIOUSFRIEND"]       = 33,
   ["ATTACKTARGET"]               = 34,
   ["TARGETLASTTARGET"]           = 35,
}
