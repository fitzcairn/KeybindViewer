KeybindViewer
=============

Source for the KeybindViewer WoW addon (http://www.curse.com/addons/wow/keybindviewer). Please see Curse for a more complete description of the addon; the below has been copied from there.

---

What is KeybindViewer?

Ever need to bind a spell or ability, but had no idea where to put it?

Wondering why your keys feel awkward, but having trouble visualizing your layout?

KeybindViewer was created to solve these problems. This addon shows you an interactive display of your keybinds across both keyboard and mouse, both for your action bars and for a select subset of other actions (like movement). Hovering over a key shows you a popup with what actions are bound to it, along with any required modifiers. Keys colored bright red are for action bars, dull red are for non-bar actions, and light blue shows you what modifiers can be used with a given key.

The on-screen keyboard can be dragged and resized, and is highly configurable. Users can change which side the mouse appears on, select different key layouts (Us-En by default), change the number of buttons on your mouse, and select what bars/addons are included in the display.

KeybindViewer is usable anywhere and anytime, in or out of combat. Type /kbv to see options.

Web Integration

KeybindViewer will eventually do more than simply show you your binds-it will also give you a link you can use to view your binds online anywhere. The service powering this is still under construction; this functionality will be completed in the addon as soon as it is up and scaled for traffic.

Addon Compatibility

KeybindViewer is compatible with the following bind management addons:

BindPad
Dominos
Bartender
Support is still in the works for these addons:

Vuhdo
Clique
CT_BarMod
If you have other requests, please post them below.

Localization

KeybindViewer is currently localized in English; I'd love to get some help translating if others find this useful.

Likewise, I've included support for only one keyboard: the standard US 104-key. However, it is easy to add additional key layouts-see KeyLayouts.lua in the localization directory to see how the default keyboard is described. If you'd like support for a keyboard from your locale, please contact me; I'd be happy to accept your help.

Suggesting Improvements

If you have a an idea for extending KeyboardTrainer that you'd like to share, please comment! Comments have been left open and will be checked by the author. All feedback is welcome.

How to report a bug in KeybindViewer

Important: before reporting a bug, please:

Double-check that you have the latest version of KeybindViewer.
Disable all other addons and see if the problem still happens.
Enable "Display Lua Errors" under Interface Options > Help, or install an error handling addon like BugSack.
Then, submit a bug report in the ticket tracker. Be sure to include as much of the information requested in the ticket template as you can.

Finally, remember to check on your ticket after a few days. If a ticket is waiting on a response from you for more than a week, I'll assume you've solved the issue on your own.

