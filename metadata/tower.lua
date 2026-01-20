--[=====[
[[SND Metadata]]
author: Erisen
version: 1.0.0
description: >-
  Jump up kugane tower
plugin_dependencies:
- vnavmesh
configs:
  LampJump:
    default: false
    description: Jump to the lamp
    type: bool

[[End Metadata]]
--]=====]


require 'utils'
require 'path_helpers'


if Player.Entity.Position.Y < 20 then
    WalkTo(-41.7, 14, -37.3)
    jump_to_point({ -40.9, 15.5, -35.2 })
    move_to_point({ -41.1, 15.4, -35.3 })
    jump_to_point({ -39.7, 17.2, -37.5 }, .2)
    jump_to_point({ -36.2, 17.4, -39.2 })
    move_to_point({ -36.6, 17.4, -39.3 })
    jump_to_point({ -34.5, 19.2, -39.0 })
    move_to_point({ -33.8, 19.2, -38.4 })
    jump_to_point({ -30.1, 20.9, -38.5 }, .3)
    jump_to_point({ -33.1, 24.0, -41.7 })
else
    log("Higher than start")
end


if Player.Entity.Position.Y < 30 then
    --first landing
    WalkTo(-41, 25.6, -78)
    jump_to_point({ -43.1, 26.6, -78.2 })
    jump_to_point({ -48.8, 26.6, -80.9 })
    jump_to_point({ -51.8, 27.7, -81.7 })
    move_to_point({ -48.6, 27.7, -81.7 })
    jump_to_point({ -52.3, 28.3, -81.7 })
    jump_to_point({ -53.7, 30.0, -81.0 })
    move_to_point({ -54.0, 30.0, -82.7 })
    jump_to_point({ -54.2, 32.7, -78.8 })
else
    log("Higher than first landing")
end


if Player.Entity.Position.Y < 48 then
    --second landing
    WalkTo(-46.1, 40.4, -70.7)
    jump_to_point({ -46.6, 42.1, -70.2 })
    jump_to_point({ -49.5, 43.8, -70.5 })
    jump_to_point({ -52.6, 45.3, -70.4 })
    jump_to_point({ -49.2, 47.1, -70.4 })
    move_to_point({ -49.0, 47.1, -70.9 })
    jump_to_point({ -46.5, 48.9, -70.9 })
    jump_to_point({ -46.6, 51.6, -69.5 }, nil, true)
else
    log("Higher than second landing")
end


if Player.Entity.Position.Y < 57 then
    --third landing
    WalkTo(-52.6, 52.0, -67.5)
    jump_to_point({ -54.3, 53.6, -66.6 })
    jump_to_point({ -57.0, 54.8, -63.2 })
    jump_to_point({ -56.0, 56.1, -58.9 })
    jump_to_point({ -54.7, 57.7, -58.8 })
else
    log("Higher than third landing")
end


if Player.Entity.Position.Y < 89 then
    --posts
    jump_to_point({ -54.9, 59.5, -55.5 })
    jump_to_point({ -54.5, 61.3, -58.0 })
    jump_to_point({ -54.5, 62.8, -56.8 })
    jump_to_point({ -54.9, 64.3, -59.5 })
    jump_to_point({ -55.5, 65.9, -62.0 })
    move_to_point({ -52.1, 67.1, -65.6 })
    --more posts
    jump_to_point({ -49.0, 68.4, -65.5 })
    jump_to_point({ -47.0, 70.2, -65.5 })
    jump_to_point({ -45.5, 72.0, -65.8 })
    jump_to_point({ -48.4, 73.5, -65.8 }, .2)
    jump_to_point({ -50.3, 75.1, -66.0 })
    jump_to_point({ -47.2, 76.4, -65.9 }, .2)
    jump_to_point({ -44.6, 77.3, -65.6 })
    jump_to_point({ -41.2, 79.0, -65.5 })
    move_to_point({ -41.4, 79.0, -65.9 })
    --corner
    jump_to_point({ -39.6, 80.9, -63.3 })
    jump_to_point({ -41.5, 82.2, -61.5 })
    jump_to_point({ -41.5, 82.2, -57.0 }, .4)

    jump_to_point({ -41.1, 83.7, -55.4 })
    move_to_point({ -40.0, 83.7, -55.1 })

    jump_to_point({ -38.9, 85.5, -51.9 }, .2)
    jump_to_point({ -39.8, 87.3, -54.3 })
    jump_to_point({ -40.4, 88.4, -54.4 })
    jump_to_point({ -39.9, 89.7, -52.1 })
    jump_to_point({ -42.2, 89.2, -52.8 }, nil, true)
else
    log("Higher than 4th landing")
end


if Player.Entity.Position.Y < 95 then
    --landing 4
    move_to_point({ -42.0, 89.2, -65.0 })
    jump_to_point({ -42.4, 90.9, -65.8 })
    move_to_point({ -43.4, 90.9, -66.5 })
    jump_to_point({ -40.0, 91.0, -68.7 })
    move_to_point({ -39.8, 91.0, -68.9 })
    jump_to_point({ -38.2, 92.8, -66.9 })
    move_to_point({ -36.6, 92.8, -67.1 })
    jump_to_point({ -37.5, 94.6, -65.5 })
    jump_to_point({ -39.5, 96.6, -65.8 }, nil, true)
else
    log("Higher than top")
end


if Config.Get("LampJump") then
    --the lamp
    move_to_point({ -40.3, 96.4, -64.3 })
    Actions.ExecuteGeneralAction(4)
    wait(1)
    jump_to_point({ -04.4, 05.0, -64.0 }, 1)
end
