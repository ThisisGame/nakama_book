--导入nakama库
local nk = require("nakama")

--等待指派给DS的对局Collection
local MATCHES_WAIT_DS_COLLECTION = "matches_wait_ds"

--系统用户ID
local SYSTEM_USER_ID = "00000000-0000-0000-0000-000000000000"

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

    --创建一场匹配赛，lobby 是lua脚本名字
    local match_id,optional_error_match_create=nk.match_create("lobby", {debug = true, expected_users = matched_users})
    if optional_error_match_create then
        nk.logger_error("Failed to create match: " .. optional_error_match_create)
        return match_id,optional_error_match_create
    end
    nk.logger_info("Match created with ID: " .. match_id)

    --存储到对局列表Collection中
    local new_objects = {{
        collection = MATCHES_WAIT_DS_COLLECTION,
        key = match_id,
        user_id = SYSTEM_USER_ID,
        value = nk.json_encode({
            match_id = match_id,
            matched_users = matched_users,
            create_time = os.time()
        })
    }}
    local versions,optional_error=nk.storage_write(new_objects)
    if optional_error then
        nk.logger_error("Failed to write storage: " .. optional_error)
        return nil
    end
    nk.logger_info("Match stored in collection: " .. match_id)

    return match_id,optional_error_match_create
end

-- 注册MatchMaker匹配成功后的处理
nk.register_matchmaker_matched(matchmaker_matched)
