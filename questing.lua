require 'utils'
require 'path_helpers'
require 'inventory_buddy'


function PeluPelu(n)
    GetBeastTribeQuest("Yubli", "Viper",
        "H4sIAAAAAAAACu1SwW7aQBD9FTTnLbJpCfbeIkoiWkFJoCEQ5bDUE7ySd4d6Zxsh5H+v1hgIRcqpl0o97bzn9Zu3M28HY2UQJDxop7m18KtCt8bUGpG3DAJuS/IbkPDdrkOFGQi4IcpARgJGynpV1OVMlWvkW8U5lkNGU5Nztd2QtuxAPu1gQk6zJgtyB48ge724HXWTWMACZNxpJ5+uur2OgCXID51u2u59TOJKwJIsDj+DjOMkEXCvMu0dyDRN03ZwQL/QoOW63URx/qJtBvJFFQ4FDC1jqX7wXHP+LYhE51zzdDhn//AZhT6L5lzWZyXA5fR6+EmTdRc9a4FYwMAQ46E3o2nK6/pGA+48On5bT/HnfsC0augp06ZPNmucRQK+6qLo11sK6J484+k9/Vxxn4xRYRqBCH7nSvPJaEA3VJ6LBnKmDY7cGRzMLodRCRi6Sa4skzmKhhWAtL4oBIwRM7fP0eHzPh/armfbDYYtBo0xZXi8EcAXWoGMKvF3I9N5Jy9c+v9xoX87Ls/VbwBV+anMBAAA",
        false, n)
end

function MamoolJa(n)
    GetBeastTribeQuest("Kageel Ja", "Botanist",
        "H4sIAAAAAAAACu2V32/TMBDH/5Xqnk0U50cX+w2VbeqmlrIVyop48MitsZT4SuyApir/O3KabgsbvIKgT777xrk7331k72CuKgQJH7TVbnSpNojl6EKNZtQYBwzOa2q2IOG92XgLc2BwRpSDDBnMlGlU2ZlLVW/QnStXYD11WHXiSt1vSRtnQX7awYKsdpoMyB18BJlmWRBlIk0Z3IB8xZMoyAQfZwzWIE9iHvCTcdwyWJPB6RuQnGeCwZXKdWNBCiFE4Eugb1ihcV2+hXLFnTY5yDtVWmQwNQ5r9cWttCve+iDhUOsPD0P1p0JDn+emX9fd2jKwBX0//KTJ2Gc5uwCcwWlFDg+5HVa9+brb0TvvGrTuqX2NX/cdpttevna0nZDJ+8pCBpe6LCfdmLx3RY3Dx/NMCuUmVFXKd8MLvt6V0u6xUO+dUT0M6sWlrnBmB+7p8nkzWgZTuyiUcVQ9BPUjAGmasmQwR8ztHqTD5z0g2myW91v0U/Qx5pTjww7vXNAtyLBlLzCTBHwci+TATBIIHidRz0wcJFkm0l9Cw8MhMvwpMq5ujsT8RcTs5/FngYl+c8Ucefk3bxgRJFHy8qMUiSAep+KIi/w/cfnc/gA+PsqiMAkAAA==",
        true, n)
end

function Ananta(n)
    GetBeastTribeQuest("Eshana", "Viper",
        "H4sIAAAAAAAACu2S32/TMBDH/xV0zyZynDRN/TaVbSqopbSVyop48JbbYinxlfgCqqr+78hpOlZ+SCDxANKefPe1fff1+bOHmakRNFw449i8WOAWBFw31G6DWFUWiyXdWeQdCLgiKkBLAVPjWlN14co0D8jXhktsJox1J67NbkvWsQf9YQ9z8pYtOdB7eA/6pYqjOMmyWAm4AT3MojRJlBKwAa1UHKWpzNODgA05nLwC3R1cmMK2HrSKQnv6jDU6Bh0LmBsu760rQHPTooCJY2zMHa8tl2/DfXmu9Q9GXxpn4HzvO6cyNLvp1023HgT4kr6cLllyHvS9qfyTzl2BWMBlTYwnB4x1H150J/rkXYuen8ZL/HQcMd328pJpOyZX9M6kgDe2qsbUhgFIAQtqGftXgYBxaXhMdW3CSIIQ/K6N5W9GQ3ZFzXnRIK5sjVN/ll6ufhzGQcDEz0vjmOrHouEfQLu2qgTMEAs/PTo8/soREOseVrstgh6NQokZFfh4PySv6Ra0PIifMDOM4iyRMu08DLIojgejbHiEJkmiQa5k/itokr8FzTMu/wsuWTRI1UDlJ1xkPhzlWY+LikaJksPfxEU+4zL7Z3Hpt/+Il4+Hr7kva+v3BgAA",
        false, n)
end

function Namazu(n)
    GetBeastTribeQuest("Seigetsu the Enlightened", "Culinarian",
        "H4sIAAAAAAAACmVSwW7bMAz9leGdtcBNljrRrcjaIhuSZUmArBl2UGu2FmCJnkVtyAL/eyHH7ZrtRPKJ5HskdcTSOIJOxvyJ79ZUQ+G24VhD46qqLBUbfrAkByjcMBfQmcLC+Giqzt2a5onk1khJzVzIdeDOHGq2XgL09yNWHKxY9tBHfIN+n+f5YPxhPB4p3EFfDPPBJJtkucIeejoZTEejy1Zhz57mH6Evh0OFtSlsDNCjQWLnX+TIS0e1MlI+Wl9ASxNJYe6FGvMgOyvll1SfnWP9vDhH/5GYJZq73u472yqEkn+/FFn2AfrRVOENZ9fgQuHasdALt5Dr3asuow++Rgry1t/Qz9Nu+b6HN8L1jH3RK8sUPtuqmnHsR19zFPo7z6w0MmPnTFpGApLenbHpCr3QFN1wc940gVvraBHOwuvt/8toFeZhVRov7F6bpgtA+1hVCkuiIixOCvvn09ew/ml7qAl6Ok09llzQa0YKPvE9dNb+aJ8BmufVw5ICAAA=",
        false, n)
end

function GetBeastTribeQuest(npc, class, path, one_per, n)
    n = default(n, 3)
    one_per = default(one_per, false)
    yield("/gbr auto off")
    yield("/at y")
    equip_gearset(class)

    for i = 1, n do
        if not IsNearThing(npc, 4) then
            RunVislandRoute(path, "Going to " .. npc)
        end
        AcceptQuest(npc)
        if one_per or i == n then
            RunQuesty()
        end
    end
end

function RunQuesty(max_time)
    max_time = default(max_time, 10 * 60)
    local ti = ResetTimeout()
    repeat
        CheckTimeout(10, ti, CallerName(false), "Starting questy")
        yield("/qst start")
        wait(2)
    until IPC.Questionable.IsRunning()
    repeat
        CheckTimeout(max_time, ti, CallerName(false), "Running questy")
        wait(.1)
    until not IPC.Questionable.IsRunning()
end

function AcceptQuest(who, which, qlist)
    qlist = default(qlist, "SelectIconString")
    which = default(which, 0)

    local ti = ResetTimeout()
    repeat
        local entity = get_closest_entity(who)
        entity:SetAsTarget()
        entity:Interact()
        wait(.1)
        CheckTimeout(2, ti, "AcceptQuest", "Talking to", who, "didnt open", qlist)
        wait(.1)
    until IsAddonReady(qlist)
    SafeCallback(qlist, true, which)
    repeat
        CheckTimeout(10, ti, "AcceptQuest", "Waiting for quest accept dialog (Is text advance on?)")
        wait(.1)
    until not Player.IsBusy
    wait(.1)
end
