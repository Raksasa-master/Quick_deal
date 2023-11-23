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
    if item.prefab == "birdcage" then
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
    if not AcceptTest(inst, item, giver) then
        giver.components.talker:Say("不接受该物品")
        return false
    end

    return true
end

--交易函数
local function deal(giver, inst)
    for i = 1, 9 do
        local item = inst.components.container:GetItemInSlot(i)                                  --获得箱子第i格的东西
        if item ~= nil then                                                                      --如果这一格为空就跳过
            local num = item.components.stackable and item.components.stackable:StackSize() or 1 --获得其数量
            local OnGetItemFromPlayer = inst.components.trader.onaccept
            for i = 1, num do
                if check(inst, giver, item) then           --判断是否可以交易，鱼人王会有吃饱的情况，所以反复判断，减少食物浪费
                    OnGetItemFromPlayer(inst, giver, item) --进行交易
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
        
    end
    print("add container success!")
    -- --添加容器组件
    -- inst:AddComponent("container")
    -- --设置容器名
    -- inst.components.container:WidgetSetup("deal_container")
    -- -- inst.components.container.onopenfn = onopen
    -- -- inst.components.container.onclosefn = onclose
    -- print("prefab start!")
end
-- Quick_deal_actions_give = deepcopy(ACTIONS.GIVE)
-- Quick_deal_actions_give.priority = 999
local Quick_deal_actions_give = deepcopy(ACTIONS.GIVE)
-- Quick_deal_actions_give.fn = function(act)
--     ACTIONS.GIVE.fn(act)
-- end
Quick_deal_actions_give.id = "Quick_deal_actions_give"
-- Quick_deal_actions_give.str = ACTIONS.GIVE.str
Quick_deal_actions_give.priority = 999
AddAction(Quick_deal_actions_give)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.Quick_deal_actions_give, "give"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.Quick_deal_actions_give,"give"))
-- ACTIONS.Quick_deal_actions_give.priority = 999
--搞一个新的给予判断（原判断放箱子的判定大于给予判定）
Quick_deal_give = function(inst, doer, target, actions)
    
    if target:HasTag("trader") and
        not (target:HasTag("player") or target:HasTag("ghost")) and
        not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding() and--还要增添额外判定
            not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer))) and
            (target.prefab == "pigking" or target.prefab == "antlion" or target.prefab == "birdcage" or target.prefab == "mermking") then
        table.insert(actions,ACTIONS.Quick_deal_actions_give)
    end
    
end
AddComponentAction("USEITEM", "tradable", Quick_deal_give)


--因为存储.容器的代码顺序在放鸟之前，所以特判调整一下原函数位置
old_store = ACTIONS.STORE.fn
Quick_deal_actions_store = function(act)
    local target = act.target
    if target.prefab == "birdcage" and act.invobject ~= nil and
        act.invobject.components.occupier ~= nil and
        target.components.occupiable ~= nil and
        target.components.occupiable:CanOccupy(act.invobject) then
        return target.components.occupiable:Occupy(act.invobject.components.inventoryitem:RemoveFromOwner())
    end
    old_store(act)--会说废话，回头优化
end
ACTIONS.STORE.fn = Quick_deal_actions_store


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


--添加Prefab
AddPrefabPostInit("pigking", add_deal_container)
AddPrefabPostInit("antlion", add_deal_container)
AddPrefabPostInit("birdcage", add_deal_container)
AddPrefabPostInit("mermking", add_deal_container)
AddPrefabPostInit("monkeyqueen", add_deal_container)
