--导入nakama库
local nk = require("nakama")

--等待指派给DS的对局Collection
local MATCHES_WAIT_DS_COLLECTION = "matches_wait_ds"

--已经指派给DS的对局Collection
local MATCHES_IN_DS_COLLECTION = "matches_in_ds"

--系统用户ID
local SYSTEM_USER_ID = "00000000-0000-0000-0000-000000000000"

--- 请求对局任务
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据，存着MatchID
function request_match_task(context, payload)
    nk.logger_info("request_match_task is called")

    --打印context类型(table)
    nk.logger_info(type(context))

    --打印payload类型(string)
    nk.logger_info(type(payload))

    --遍历payload
    for k, v in pairs(nk.json_decode(payload)) do
        nk.logger_info(("key: %q value: %q"):format(k, v))
    end

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

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

    --只取了一个任务
    local object = objects[1]
    nk.logger_info("request_match_task get match task,match_id: " .. object.value.match_id)

    --删除等待指派给DS的对局Collection中的任务
    local delete_objects= {object}
    local optional_error = nk.storage_delete(delete_objects)
    if optional_error then
        nk.logger_error("request_match_task Failed to delete storage: " .. optional_error)
        return nk.json_encode({ success = false , error = optional_error })
    end

    --移动到已经指派给DS的对局Collection
    local new_objects = {{
        collection = MATCHES_IN_DS_COLLECTION,
        key = object.key,
        user_id = SYSTEM_USER_ID,
        value = object.value
    }}
    local versions,optional_error = nk.storage_write(new_objects)
    if optional_error then
        nk.logger_error("request_match_task Failed to write storage: " .. optional_error)
        return nk.json_encode({ success = false , error = optional_error })
    end

    --返回结果&请求的数据
    return nk.json_encode({ success = true , match_id = object.value.match_id })
end


nk.register_rpc(request_match_task, "request_match_task")