name = "快速交易(Quick_deal)"
author = "Raksasa_master"
description = [[
0.1.4版本更新，兼容鱼人王的三叉戟，铥矿头，大理石甲的给予
0.1.5版本更新，增加可配置的交易冷却和交易数量限制，防止游戏卡顿；增加对每个快速交易对象的配置，以增加对其他mod的兼容性，以及在mod出问题的时候可以定向关闭有问题的对象
]]
version = "0.1.5"
dst_compatible = true
forge_compatible = false
gorge_compatible = false
dont_starve_compatible = false
client_only_mod = false
all_clients_require_mod = true
icon_atlas = "modicon.xml"
icon = "modicon.tex"
forumthread = ""
api_version_dst = 10
priority = 0
mod_dependencies = {}
server_filter_tags = {}

-- mod的配置项，后面介绍
configuration_options = {
    {
        name = "quick_deal_count",             -- 配置项名换，在modmain.lua里获取配置值时要用到
        hover = "每次快速交易的数量限制",        -- 鼠标移到配置项上时所显示的信息
        options = {
            {                    -- 配置项目可选项
                description = "默认",        -- 可选项上显示的内容
                hover = "无限制",    -- 鼠标移动到可选项上显示的信息
                data = 0                  -- 可选项选中时的值，在modmain.lua里获取到的值就是这个数据，类型可以为整形，布尔，浮点，字符串
            },
            {
                description = "20个",
                hover = "交易20个物品",
                data = 20
            },
            {
                description = "40个",
                hover = "交易40个物品",
                data = 40
            },
            {
                description = "80个",
                hover = "交易80个物品",
                data = 80
            },
            {
                description = "160个",
                hover = "交易160个物品",
                data = 160
            },
            {
                description = "320个",
                hover = "交易320个物品",
                data = 320
            }
        },
        default = 0                   -- 默认值，与可选项里的值匹配作为默认值
    },
    {
        name = "quick_deal_cd",             
        hover = "每次快速交易的时间限制",        
        options = {
            {                    
                description = "默认",        
                hover = "无限制",    
                data = 0                  
            },
            {
                description = "1秒",
                hover = "快速交易有1秒冷却",
                data = 1
            },
            {
                description = "2秒",
                hover = "快速交易有2秒冷却",
                data = 2
            },
            {
                description = "3秒",
                hover = "快速交易有3秒冷却",
                data = 3
            },
            {
                description = "4秒",
                hover = "快速交易有4秒冷却",
                data = 4
            },
            {
                description = "5秒",
                hover = "快速交易有5秒冷却",
                data = 5
            }
        },
        default = 0               
    },
    {
        name = "quick_deal_pigking",          
        hover = "猪王快速交易",       
        options = {
            {                   
                description = "开启",       
                hover = "开启猪王快速交易",   
                data = true                  
            },
            {                    
                description = "关闭",        
                hover = "关闭猪王快速交易",    
                data = false                  
            }
        },
        default = true                   
    },
    {
        name = "quick_deal_antlion",             
        hover = "蚁狮快速交易",       
        options = {
            {                    
                description = "开启",        
                hover = "开启蚁狮快速交易",    
                data = true                  
            },
            {                    
                description = "关闭",        
                hover = "关闭蚁狮快速交易",    
                data = false                  
            }
        },
        default = true                   
    },
    {
        name = "quick_deal_birdcage",             
        hover = "鸟笼快速交易",       
        options = {
            {                    
                description = "开启",        
                hover = "开启鸟笼快速交易",    
                data = true                  
            },
            {                    
                description = "关闭",        
                hover = "关闭鸟笼快速交易",    
                data = false                  
            }
        },
        default = true                   
    },
    {
        name = "quick_deal_mermking",             
        hover = "鱼人王快速交易",       
        options = {
            {                    
                description = "开启",        
                hover = "开启鱼人王快速交易",    
                data = true                  
            },
            {                    
                description = "关闭",        
                hover = "关闭鱼人王快速交易",    
                data = false                  
            }
        },
        default = true                   
    },
    {
        name = "quick_deal_monkeyqueen",             
        hover = "月亮女王快速交易",       
        options = {
            {                    
                description = "开启",        
                hover = "开启月亮女王快速交易",    
                data = true                  
            },
            {                    
                description = "关闭",        
                hover = "关闭月亮女王快速交易",    
                data = false                  
            }
        },
        default = true                   
    },
    {
        name = "quick_deal_monkeyisland_portal",             
        hover = "非自然传送门快速交易",       
        options = {
            {                    
                description = "开启",        
                hover = "开启非自然传送门快速交易",    
                data = true                  
            },
            {                    
                description = "关闭",        
                hover = "关闭非自然传送门快速交易",    
                data = false                  
            }
        },
        default = true                   
    }
}