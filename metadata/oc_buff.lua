--[=====[
[[SND Metadata]]
author: Erisen
version: 1.0.0
description: apply oc buffs maybe

configs:
  AllowFreelancer:
    default: true
    description: Check freelancer level and apply all buffs at once if >15
[[End Metadata]]
--]=====]


require 'phantom_buffs'

apply_phantom_buffs(Config.Get("AllowFreelancer"))
