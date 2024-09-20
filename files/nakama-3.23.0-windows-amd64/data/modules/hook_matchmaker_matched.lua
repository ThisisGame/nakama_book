--导入nakama库
local nk = require("nakama")

local function matchmaker_matched(context, matched_users)
    nk.logger_info("Matchmaker matched users: " .. #matched_users)

    --序列化matched_users为json字符串
    local matched_users_json = nk.json_encode(matched_users)
    nk.logger_info("Matchmaker matched users json: " .. matched_users_json)

    --匹配成功的用户数量检查,设置至少2个人。
    if #matched_users <2 then
        nk.logger_error("Matchmaker matched users count is less than 2")
        return nil
    end

    --创建一场匹配赛，lobby 是lua脚本名字
    local match_id,optional_error_match_create=nk.match_create("lobby", {debug = true, expected_users = matched_users , local_dev_ds_mode = false})
    if optional_error_match_create then
        nk.logger_error("Failed to create match: " .. optional_error_match_create)
    else
        nk.logger_info("Match created with ID: " .. match_id)
    end

    --查找MatchID对应的对局
    local match,optional_error_match_get=nk.match_get(match_id)
    if optional_error_match_get then
        nk.logger_error("Failed to get match: " .. optional_error_match_get)
    else
        nk.logger_info("Match retrieved: " .. nk.json_encode(match))
    end

    return match_id --这里注意只能返回match_id一个值，如果返回多个值，会导致客户端解析到后面的值作为match_id
end

-- 注册MatchMaker匹配成功后的处理
nk.register_matchmaker_matched(matchmaker_matched)
