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

--- 请求对局任务
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据，存着MatchID
function request_match_task(context, payload)
    nk.logger_info("request_match_task is called")

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

    --将payload转为table
    local payload_table = nk.json_decode(payload)

    --从payload取到DS Url
    local ds_url = payload_table.ds_url
    nk.logger_info("request_match_task ds_url: " .. ds_url)

    --如果没有DS Url，返回错误
    if not ds_url then
        return nk.json_encode({ success = false , error = "No ds_url" })
    end

    --从等待指派给DS的对局Collection中取一个任务
    local objects,cursor,optional_error = nk.storage_list(SYSTEM_USER_ID, MATCHES_WAIT_DS_COLLECTION, 1)
    if optional_error then
        nk.logger_error("request_match_task Failed to list storage: " .. optional_error)
        return nk.json_encode({ success = false , error = optional_error })
    end

    --没有任务
    if #objects == 0 then
        nk.logger_info("request_match_task No match task")
        return nk.json_encode({ success = false , error = "No match task" })
    end

    --只需要取第一个任务
    local object = objects[1]
    nk.logger_info("request_match_task get match task,match_id: " .. object.value.match_id)

    --删除等待指派给DS的对局Collection中的任务
    local delete_objects= {object}
    local optional_error_storage_delete = nk.storage_delete(delete_objects)
    if optional_error_storage_delete then
        nk.logger_error("request_match_task Failed to delete storage: " .. optional_error_storage_delete)
        return nk.json_encode({ success = false , error = optional_error_storage_delete })
    end

    --移动到已经指派给DS的对局Collection
    local new_objects = {{
        collection = MATCHES_IN_DS_COLLECTION,
        key = object.key,
        user_id = SYSTEM_USER_ID,
        value = {
            match_id = object.value.match_id,
            matched_users = object.value.matched_users,
            ds_url = ds_url,
            create_time = os.time()
        }
    }}
    local versions,optional_error_storage_write = nk.storage_write(new_objects)
    if optional_error_storage_write then
        nk.logger_error("request_match_task Failed to write storage: " .. optional_error_storage_write)
        return nk.json_encode({ success = false , error = optional_error_storage_write })
    end
    if #versions ~= 1 then
        nk.logger_error("request_match_task Failed to write storage: versions count is not 1")
        return nk.json_encode({ success = false , error = "Failed to write storage: versions count is not 1" })
    end

    --通知这个对局，已经分配了DS，可以通知玩家开局了。
    local match_id = object.value.match_id
    local data = nk.json_encode({ op_code = OPCODE_DS_ASSIGNED , ds_url = ds_url})
    local response,optional_error_match_signal = nk.match_signal(match_id, data)
    if optional_error_match_signal then
        nk.logger_error("request_match_task Failed to match_signal: " .. optional_error_match_signal)
        return nk.json_encode({ success = false , error = optional_error_match_signal })
    end

    --返回结果&请求的数据
    return nk.json_encode({ success = true , match_id = object.value.match_id,matched_users = object.value.matched_users})
end


nk.register_rpc(request_match_task, "request_match_task")