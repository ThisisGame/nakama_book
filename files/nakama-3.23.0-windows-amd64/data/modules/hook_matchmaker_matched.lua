--导入nakama库
local nk = require("nakama")

--等待指派给DS的对局Collection
local MATCHES_WAIT_DS_COLLECTION = "matches_wait_ds"

--系统用户ID
local SYSTEM_USER_ID = "00000000-0000-0000-0000-000000000000"

local function matchmaker_matched(context, matched_users)
    nk.logger_info("Matchmaker matched users: " .. #matched_users)

    --序列化matched_users为json字符串
    local matched_users_json = nk.json_encode(matched_users)
    nk.logger_info("Matchmaker matched users json: " .. matched_users_json)

    --匹配成功的用户数量检查。如果想让1个人也可以进匹配，那么这里下限为1，上限为自定义人数。
    if #matched_users ==0 then
        nk.logger_error("Matchmaker matched users count is 0")
        return nil
    end

    --判断是否本地DS，本地DS只许一个人开局
    if matched_users[1].launch_local_dev_ds then
        if #matched_users > 1 then
            nk.logger_error("Matchmaker matched users count is more than 1, but launch_local_dev_ds is true")
            return nil
        end
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
        value = {
            match_id = match_id,
            create_time = os.time(),
            launch_local_dev_ds = matched_users[1].launch_local_dev_ds,
            matched_users = matched_users
        }
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
