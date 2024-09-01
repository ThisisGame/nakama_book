--导入nakama库
local nk = require("nakama")

local function matchmaker_matched(context, matched_users)
    nk.logger_info("Matchmaker matched users: " .. #matched_users)

    --打印匹配成功的用户信息
    for _, m in ipairs(matched_users) do
        nk.logger_info("user_id:" .. m.presence["user_id"])
        nk.logger_info("session_id:" .. m.presence["session_id"])
        nk.logger_info("username:" .. m.presence["username"])
        nk.logger_info("node:" .. m.presence["node"])

        for _, p in ipairs(m.properties) do
            nk.logger_info("propertie:" .. p)
        end
    end

    --匹配成功的用户数量不是2个，返回nil。如果想让1个人也可以进匹配，那么这里下限为1，上限为自定义人数。
    if #matched_users ~= 2 then
        nk.logger_error("Matchmaker matched users count is not 2")
        return nil
    end

    -- if matched_users[1].properties["mode"] ~= "matchmaker" then
    --     nk.logger_error("Matchmaker matched user 1 mode is not matchmaker, mode: " .. tostring(matched_users[1].properties["mode"]))
    --     return nil
    -- end

    -- if matched_users[2].properties["mode"] ~= "matchmaker" then
    --     nk.logger_error("Matchmaker matched user 2 mode is not matchmaker, mode: " .. tostring(matched_users[2].properties["mode"]))
    --     return nil
    -- end

    --创建一场匹配赛，lobby 是lua脚本名字
    return nk.match_create("lobby", {debug = true, expected_users = matched_users})
end

-- 注册MatchMaker匹配成功后的处理
nk.register_matchmaker_matched(matchmaker_matched)
