print("hello world")
print("test\n")


GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })


--获取容器模块
local containers = require("containers")
local params = containers.params


--给容器对象添加容器
params.deal_container = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 0,
        buttoninfo =
        {
            text = "交易",
            position = Vector3(0, -140, 0),
        }
    },
    type = "deal_container",
    itemtestfn = function(container, item, slot)
        
        return true
    end
}


--添加格子
for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(params.deal_container.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end
-- --检查交易是否能进行
local function check(inst, giver, item)
    if not item.components.tradable then
        giver.components.talker:Say("该物品不可交易")
        return false
    end
    if inst.prefab == "birdcage" then
        if not inst.components.occupiable:IsOccupied() then
            giver.components.talker:Say("无稽之谈")
        return false
        end
    end
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        giver.components.talker:Say("晚安")
        return false
    end
    local AcceptTest = inst.components.trader.test --获得交易目标的判断交易函数
    if inst.prefab =="monkeyisland_portal" then
        AcceptTest = inst.components.trader.abletoaccepttest
    end
    if AcceptTest then
        if not AcceptTest(inst, item, giver) then
            giver.components.talker:Say("不接受该物品")
            return false
        end
    end
    return true
end


-- function StateGraphInstance:HasState(statename)
--     return self.sg.states[statename] ~= nil
-- end

-- 修改月亮女王的交易函数运行方式（官方的方式是在sg结束后运行）
local function Monkeyqueen_deal(inst, giver, item)
    local takemonkeycurse = false
    inst.sg.statemem.giver = giver
    if inst.sg.statemem.giver then
        if inst.sg.statemem.giver.components.cursable and (inst.sg.statemem.giver.components.cursable.curses.MONKEY or 0) > 0 then
            takemonkeycurse = true
        elseif inst.sg.statemem.giver:HasTag("wonkey") then -- NOTES(JBK): This only is true if the player gets into an invalid state, saves and reloads the save.
            takemonkeycurse = true
        end
    end
    if takemonkeycurse then
        print("takemonkeycurse----")
        local data = {giver = giver}
        inst.sg.sg.states["removecurse"].onenter(inst, data)
        inst.sg.sg.states["removecurse"].events["animover"].fn(inst)
        -- for _, v in ipairs(inst.sg.sg.states["removecurse"].events) do
        --     print(v.name)
        --     if v.name == "animover" then
        --         v.fn(inst)
        --     end    
        -- end
    else
        print("not takemonkeycurse----")
        local data = {item = item,giver = giver}
        inst.sg.sg.states["getitem"].onenter(inst, data)
        inst.sg.sg.states["getitem"].events["animover"].fn(inst)
        -- for _, v in ipairs(inst.sg.sg.states["getitem"].events) do
        --     print(v.name)
        --     if v.name == "animover" then
        --         v.fn(inst)
        --     end    
        -- end
    end
        
end
--非自然传送门交易

--交易函数
local function deal(giver, inst)
    for i = 1, 9 do
        local item = inst.components.container:GetItemInSlot(i)                                  --获得箱子第i格的东西
        if item ~= nil then                                                                      --如果这一格为空就跳过
            local num = item.components.stackable and item.components.stackable:StackSize() or 1 --获得其数量
            local OnGetItemFromPlayer = inst.components.trader.onaccept
            for i = 1, num do
                if check(inst, giver, item) then           --判断是否可以交易，鱼人王会有吃饱的情况，所以反复判断，减少食物浪费
                    if inst.prefab =="monkeyqueen" then
                        Monkeyqueen_deal(inst, giver, item)
                    elseif inst.prefab == "monkeyisland_portal" then
                        inst:PushEvent("timerdone",{name = "fireportalevent"})
                    else
                        OnGetItemFromPlayer(inst, giver, item) --进行交易
                    end
                    if inst.prefab == "antlion" then       --特判蚁狮，蚁狮的给物品方式不同
                        inst.GiveReward(inst)
                    end
                    if inst.prefab == "mermking" and inst.itemtotrade ~= nil then --特判鱼人王，鱼人王交易和吃东西在不同的函数里,本行为交易
                        inst.TradeItem(inst)
                        inst.sg:GoToState("idle")
                    end
                    if inst.prefab ~= "mermking" then
                        inst.components.container:ConsumeByName(item.prefab, 1) --消耗掉箱子里的物品
                    end
                    if inst.prefab =="monkeyisland_portal" then
                        TUNING.MONKEYISLAND_PORTAL_ENABLED = true
                    end
                end
                --giver.components.talker:Say("交易成功！")
                
            end
        end
    end
end


function params.deal_container.widget.buttoninfo.fn(inst, doer)
    if TheWorld.ismastersim then
        deal(doer, inst)
    else
        SendModRPCToServer(MOD_RPC["Quick_deal"]["pigking"], inst)
    end
end

AddModRPCHandler("Quick_deal", "pigking", deal)



local function add_deal_container(inst)
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("deal_container")
            if inst.replica.inventory~=nil then
                inst.replica.inventory.GetOverflowContainer = function(self)
                    return self.inst.replica.container
                end
            end
        end
        return inst
    end
    if not inst.components.container then
        inst:AddComponent("container")
        if inst.components.inventory~=nil then
            inst.components.inventory.GetOverflowContainer = function(self)
                return self.inst.components.container
            end
        end
        inst.components.container:WidgetSetup("deal_container")
        inst:ListenForEvent("death", function(inst)
            if inst.components.container then
                inst.components.container:DropEverything()
            end
        end)
        inst:ListenForEvent("onremove", function(inst)
            if inst.components.container then
                inst.components.container:DropEverything()
            end
        end)
    end
    print("add container success!")
end

local Quick_deal_actions_give = deepcopy(ACTIONS.GIVE)
Quick_deal_actions_give.id = "Quick_deal_actions_give"
Quick_deal_actions_give.priority = 999
AddAction(Quick_deal_actions_give)
-- instant可以充当SG的参数，就是Acthandler函数的第二个值，可以无SG来运行动作（未尝试），nil会使用默认SG
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.Quick_deal_actions_give, "give"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.Quick_deal_actions_give,"give"))
--搞一个新的给予判断（原判断放箱子的判定大于给予判定）
Quick_deal_tradable = function(inst, doer, target, actions)
    
    if target:HasTag("trader") and
        not (target:HasTag("player") or target:HasTag("ghost")) and
        not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding() and--还要增添额外判定
            not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer))) and
            (target.prefab == "pigking" or target.prefab == "antlion" or target.prefab == "birdcage" or target.prefab == "mermking") then
        table.insert(actions,ACTIONS.Quick_deal_actions_give)
    end
    
end
AddComponentAction("USEITEM", "tradable", Quick_deal_tradable)


--因为存储.容器的代码顺序在放鸟之前，所以特判调整一下原函数位置
--放鸟优先
Quick_deal_actions_store = deepcopy(ACTIONS.STORE)
Quick_deal_actions_store.id ="Quick_deal_actions_store"
Quick_deal_actions_store.priority = 999
Quick_deal_actions_store.fn = function(act)
    local target = act.target
    if target.prefab == "birdcage" and act.invobject ~= nil and
        act.invobject.components.occupier ~= nil and
        target.components.occupiable ~= nil and
        target.components.occupiable:CanOccupy(act.invobject) then
        return target.components.occupiable:Occupy(act.invobject.components.inventoryitem:RemoveFromOwner())
    end
    return false
end
AddAction(Quick_deal_actions_store)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.Quick_deal_actions_store, "doshortaction"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.Quick_deal_actions_store,"doshortaction"))
Quick_deal_store = function(inst, doer, target, actions)
    for k, v in pairs(OCCUPANTTYPE) do
        if target.prefab == "birdcage" and target:HasTag(v .. "_occupiable") then
            if inst:HasTag(v) then
                table.insert(actions, ACTIONS.Quick_deal_actions_store)
            end
            return
        end
    end
end
AddComponentAction("USEITEM", "occupier", Quick_deal_store)


--左键开箱（鸟笼）
Quick_deal_actions_container = deepcopy(ACTIONS.RUMMAGE)
Quick_deal_actions_container.id = "Quick_deal_actions_container"
Quick_deal_actions_container.priority = 999
AddAction(Quick_deal_actions_container)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.Quick_deal_actions_container, "doshortaction"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.Quick_deal_actions_container,"doshortaction"))
Quick_deal_container = function(inst, doer, actions, right)
    if inst:HasTag("bundle") then
        if right and inst.replica.container:IsOpenedBy(doer) then
            table.insert(actions, doer.components.constructionbuilderuidata ~= nil and doer.components.constructionbuilderuidata:GetContainer() == inst and ACTIONS.APPLYCONSTRUCTION or ACTIONS.WRAPBUNDLE)
        end
    elseif not inst:HasTag("burnt")
        and inst.replica.container:CanBeOpened()
        and doer.replica.inventory ~= nil
        and (not inst:HasTag("oceantrawler") or not inst:HasTag("trawler_lowered"))
        and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())
        and inst.prefab=="birdcage" then
        table.insert(actions, ACTIONS.Quick_deal_actions_container)
    end
end
AddComponentAction("SCENE", "container", Quick_deal_container)
Quick_deal_actions_harvest = deepcopy(ACTIONS.HARVEST)
Quick_deal_actions_harvest.id = "Quick_deal_actions_harvest"
Quick_deal_actions_harvest.priority = 1000--测试发现好像要求右键的优先级要比左键高才能使用右键
AddAction(Quick_deal_actions_harvest)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.Quick_deal_actions_harvest,"give"))--需要优化，原先不是这个SG
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.Quick_deal_actions_harvest,"give"))

--右键拿鸟（鸟笼）
Quick_deal_occupiable = function(inst, doer, actions, right)
    if inst:HasTag("occupied") and inst.prefab == "birdcage" and right then
        table.insert(actions, ACTIONS.Quick_deal_actions_harvest)
    end
end
AddComponentAction("SCENE", "shelf", Quick_deal_occupiable)







--添加Prefab
AddPrefabPostInit("pigking", add_deal_container)
AddPrefabPostInit("antlion", add_deal_container)
AddPrefabPostInit("birdcage", add_deal_container)
AddPrefabPostInit("mermking", add_deal_container)
AddPrefabPostInit("monkeyqueen", add_deal_container)
AddPrefabPostInit("monkeyisland_portal", add_deal_container)
