--导入nakama库
local nk = require("nakama")

--等待指派给DS的玩家创建的对局Collection
local USER_CREATE_MATCHES_WAIT_DS_COLLECTION = "user_create_matches_wait_ds"

--已经指派给DS的玩家创建的对局Collection
local USER_CREATE_MATCHES_IN_DS_COLLECTION = "user_create_matches_in_ds"

--已经分配DS
local OPCODE_DS_ASSIGNED = 1

--- 请求对局任务
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据，存着MatchID
function ds_request_user_create_match_task(context, payload)
    nk.logger_info("ds_request_user_create_match_task is called")

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

    --将payload转为table
    local payload_table = nk.json_decode(payload)

    --从payload取到DS Url
    local ds_url = payload_table.ds_url
    if not ds_url then
        return nk.json_encode({ success = false , error = "No ds_url" })--如果没有DS Url，返回错误
    end

    --提取MatchID
    local match_id = payload_table.match_id
    if not match_id then
        return nk.json_encode({ success = false , error = "No match_id" })--如果没有MatchID，返回错误
    end

    --是否本地DS
    local local_dev_ds_mode = payload_table.local_dev_ds_mode
    nk.logger_info("ds_request_user_create_match_task local_dev_ds_mode: " .. tostring(local_dev_ds_mode))
    if not local_dev_ds_mode then
        return nk.json_encode({ success = false , error = "No local_dev_ds_mode" })--目前在客户端创建的Match，仅限本地DevDS。
    end

    --查找MatchID对应的对局
    local match,optional_error_match_get=nk.match_get(match_id)
    if optional_error_match_get then
        nk.logger_error("Failed to get match: " .. optional_error_match_get)
        return nk.json_encode({ success = false , error = optional_error_match_get })
    end
    nk.logger_info("Match retrieved: " .. nk.json_encode(match))

    --通知这个对局，已经分配了DS，可以通知玩家开局了。
    local data = nk.json_encode({ op_code = OPCODE_DS_ASSIGNED , ds_url = ds_url ,match_id = match_id})
    local response,optional_error_match_signal = nk.match_signal(match_id, data)
    if optional_error_match_signal then
        nk.logger_error("ds_request_user_create_match_task Failed to match_signal: " .. optional_error_match_signal)
        return nk.json_encode({ success = false , error = optional_error_match_signal })
    end

    --返回结果&请求的数据
    return nk.json_encode({ success = true , match_id = match_id})
end


nk.register_rpc(ds_request_user_create_match_task, "ds_request_user_create_match_task")