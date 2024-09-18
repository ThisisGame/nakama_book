--导入nakama库
local nk = require("nakama")

--等待指派给DS的对局Collection
local MATCHES_WAIT_DS_COLLECTION = "matches_wait_ds"

--已经指派给DS的对局Collection
local MATCHES_IN_DS_COLLECTION = "matches_in_ds"

--已经分配DS
local OPCODE_DS_ASSIGNED = 1


--系统用户ID
local SYSTEM_USER_ID = "00000000-0000-0000-0000-000000000000"

--- 请求创建对局
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据，存着MatchID
function request_create_match(context, payload)
    nk.logger_info("request_create_match is called")

    --打印context
    nk.logger_info(nk.json_encode(context))

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

    --将payload转为table
    local payload_table = nk.json_decode(payload)

    --从payload取到local_dev_ds_mode
    local local_dev_ds_mode = payload_table.local_dev_ds_mode
    nk.logger_info("request_match_task local_dev_ds_mode: " .. tostring(local_dev_ds_mode))

    --创建一场匹配赛，lobby 是lua脚本名字
    local match_id,optional_error_match_create=nk.match_create("lobby", {debug = true})
    if optional_error_match_create then
        nk.logger_error("Failed to create match: " .. optional_error_match_create)
        return nk.json_encode({ success = false , error = optional_error_match_create })
    end
    nk.logger_info("Match created with ID: " .. match_id)

    --查找这场匹配赛
    local match,optional_error_match_get=nk.match_get(match_id)
    if optional_error_match_get then
        nk.logger_error("Failed to get match: " .. optional_error_match_get)
        return nk.json_encode({ success = false , error = optional_error_match_get })
    end
    nk.logger_info("Match retrieved: " .. nk.json_encode(match))

    --存储到对局列表Collection中
    local new_objects = {{
        collection = MATCHES_WAIT_DS_COLLECTION,
        key = match_id,
        user_id = SYSTEM_USER_ID,
        value = {
            match_id = match_id,
            create_time = os.time(),
            local_dev_ds_mode = local_dev_ds_mode
        }
    }}
    local _,optional_error_storage_write=nk.storage_write(new_objects)
    if optional_error_storage_write then
        nk.logger_error("Failed to write storage: " .. optional_error_storage_write)
        return nk.json_encode({ success = false , error = optional_error_storage_write })
    end
    nk.logger_info("Match stored in collection: " .. match_id)

    --返回结果&请求的数据
    return nk.json_encode({ success = true , match_id = match_id ,local_dev_ds_mode = local_dev_ds_mode })
end


nk.register_rpc(request_create_match, "request_create_match")