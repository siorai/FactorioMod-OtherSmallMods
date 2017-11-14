
require 'lib/utilities/math'
require 'lib/bugzilla/phase-cycler'
require 'lib/bugzilla/boss'


-- on load game for first time
script.on_init(function(_)
  Math:Init()
  PhaseCycler:Init()
  Boss:Init()
end)



-- on mod version different or if mod did not previously exist
script.on_configuration_changed(function(data)
  if data.mod_changes and data.mod_changes.BugZilla and data.mod_changes.BugZilla.old_version then
    Boss:OnConfigurationChanged(data)
  end
end)



-- called when a mod setting changed
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  PhaseCycler:OnSettingsChanged(event)
end)


-- called once per in-game tick
script.on_event(defines.events.on_tick, function(event)
  if game.tick % 60 == 0 then -- each second
    PhaseCycler:OnSecond()
    Boss:OnSecond()
  end
end)


-- called every time a chunk gets generated
script.on_event(defines.events.on_chunk_generated, function(event)
  PhaseCycler:OnChunkGenerated(event)
end)


-- called every time an entity die
script.on_event(defines.events.on_entity_died, function(event)
  Boss:OnEntityDied(event)
end)


-- called every time a player died
script.on_event(defines.events.on_player_died, function(event)
    local _,_ = pcall(function()
        local player = game.players[event.player_index]
        player.surface.create_entity({name = "deathscream", position = player.position})
    end)
end)
