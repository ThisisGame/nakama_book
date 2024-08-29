--导入nakama库
local nk = require("nakama")

local function matchmaker_matched(context, matched_users)
    --打印匹配成功的用户信息
    for _, m in ipairs(matched_users) do
        nk.logger_info(m.presence["user_id"])
        nk.logger_info(m.presence["session_id"])
        nk.logger_info(m.presence["username"])
        nk.logger_info(m.presence["node"])

        for _, p in ipairs(m.properties) do
            nk.logger_info(p)
        end
    end

    --匹配成功的用户数量不是2个，返回nil。如果想让1个人也可以进匹配，那么这里下限为1，上限为自定义人数。
    if #matched_users ~= 2 then
        return nil
    end

    if matched_users[1].properties["mode"] ~= "authoritative" then
        return nil
    end

    if matched_users[2].properties["mode"] ~= "authoritative" then
        return nil
    end

    --创建一场匹配赛，lobby 是lua脚本名字
    return nk.match_create("lobby", {debug = true, expected_users = matched_users})
end

-- 注册MatchMaker匹配成功后的处理
nk.register_matchmaker_matched(matchmaker_matched)
