-- RECEIVER
-- by maaark
-- a companion mod for BROADCAST by infinitedigits
-- receive norns broadcasts from broadcast.norns.online
-- !! Requires MPV installed, run 'sudo apt-get install mpv' once, might require 'sudo apt-get update' before !!


-- require the `mods` module to gain access to hooks, menu, and other utility
-- functions.
--

local mod=require 'core/mods'

--
-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in mainden) before
-- the callback function is called.
--
-- here we have dummy functionality to help confirm things are getting called
-- and test out access to mod level state via mod supplied fuctions.
--

mod.hook.register("system_post_startup","my startup hacks",function()
  state.system_post_startup=true
end)

mod.hook.register("script_pre_init","my init hacks",function()
  
    liveStreamsURL = {'off'}
   archivedStreamsURL = {}
   liveStreamsName = {'off'}
   archivedStreamsName = {}
   names = {}
   stations = {}
  print("RECEIVER mod up and running")
   getStreams = io.popen([[wget -q -O - https://broadcast.norns.online --no-check-certificate | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '.mp3$']])
   result = getStreams:read("*a")
   streamURL = mysplit(result, sep)
   getStreams:close()
  
  for k,v in pairs(streamURL) do
    -- first make list of all archived recordings
     pattern = "^/archived/"
     isArchive = streamURL[k]:find(pattern) ~= nil
    if isArchive == true then
       month = v:sub(15, 16)
       day = v:sub(17, 18)
       ndate = month.. "-" ..day
       name = ndate.. " " ..v:sub(24, -5)
      table.insert(archivedStreamsName, name)
       url = 'https://broadcast.norns.online' ..v
      table.insert(archivedStreamsURL, url)
    else
      -- now make list of the live streams check this though, not tested
       name = v:sub(2, -5)
      table.insert(liveStreamsName, name)
       url = 'https://broadcast.norns.online' ..v.. " (live)"
      table.insert(liveStreamsURL, url)
    end
    
  end
  
  -- add both live and archived together, in that order
   names = cleanNils({table.unpack(liveStreamsName), table.unpack(archivedStreamsName)})
   stations = cleanNils({table.unpack(liveStreamsURL), table.unpack(archivedStreamsURL)})
  
  -- make menu
  -- first for the radio stations, then for broadcast
   debounce=2

  params:add_option("STATIONS","RECEIVER",names,1)
  params:set_action("STATIONS",function(x) debounce=2 end)
  
  clock.run(function()
    while true do
      clock.sleep(0.5)
      if debounce>0 then
        debounce=debounce-1
        if debounce==0 then
          print("debounced")
          if params:get("STATIONS")==1 then
            os.execute([[killall -15 mpv]])
          else
            url=stations[params:get("STATIONS")]
            print("loading station "..url)
            os.execute([[killall -15 mpv]])
            io.popen('mpv --no-video --no-terminal --jack-port="crone:input_(1|2)" '..url..' &')
          end
        end
      end
    end
  end)

end)

function mysplit (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

function cleanNils(t)
  local ans = {}
  for _,v in pairs(t) do
    ans[ #ans+1 ] = v
  end
  return ans
end


--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local m={}

m.key=function(n,z)
  if n==2 and z==1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc=function(n,d)
  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

m.redraw=function()
  screen.clear()
--  screen.move(64,40)
--  screen.text_center("radio aporee  "..state.x)
  screen.update()
end

m.init=function()

end -- on menu entry, ie, if you wanted to start timers

m.deinit=function() end -- on menu exit

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name,m)


--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--
local api={}

api.get_state=function()
  return state
end

return api


