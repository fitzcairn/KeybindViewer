--
-- String Localization
-- 
-- Eventually, this will be filled in....?
--


-- English (default)
-- No need to define translations, set __index to return index string.
-- Usage example: KV.L["This is some text"] returns "This is some text"
KV.Text = setmetatable({ }, { __index = function(loc_table, str) return str end })


-- German (example)
-- Usage example: KV.L["good"] returns "gut"
if (GetLocale() == "deDE") then 
   KV.Text = {
      -- Translations here.
      ["good"] = "gut",
   }
end

