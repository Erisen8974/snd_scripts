--[=====[
[[SND Metadata]]
author: Erisen
version: 1.0.0
description: apply oc buffs maybe
configs:
  AllowFreelancer:
    default: true
    description: Check freelancer level and apply all buffs at once if >15
    type: bool
  WaitForBuff:
    default: true
    description: Wait for the buff to be applied/refreshed before continuing
    type: bool
  FreelancerBuff:
    default: RomeosBallad
    description: What buff to check if waiting with inquiring mind
    type: list
    choices:
    - RomeosBallad
    - Fleetfooted
    - EnduringFortitude
    - QuickerStep
    is_choice: true

[[End Metadata]]
--]=====]


require 'phantom_buffs'
require 'path_helpers'

land_and_dismount()
apply_phantom_buffs(Config.Get("AllowFreelancer"), Config.Get("WaitForBuff"), Config.Get("FreelancerBuff"))
