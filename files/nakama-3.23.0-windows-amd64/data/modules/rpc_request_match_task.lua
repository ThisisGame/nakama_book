--导入nakama库
local nk = require("nakama")

--已经分配DS
local OPCODE_DS_ASSIGNED = 1

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

    --查找一个等待DS的对局
    local limit = 1
    local isAuthoritative = true
    local label = nil
    local min_size = 0
    local max_size = 4
    local filter = "label.ds_assigned:false"
    local matches = nk.match_list(limit, isAuthoritative, label, min_size, max_size,filter)

    for _, match in ipairs(matches) do
        nk.logger_info(string.format("Match id %s", match.match_id))
    end

    if #matches == 0 then
        return nk.json_encode({ success = false , error = "No match to assign DS" })
    end

    if #matches > 1 then
        return nk.json_encode({ success = false , error = "More than one match to assign DS" })
    end

    --找到一个等待DS的对局
    local match = matches[1]

    --通知这个对局，已经分配了DS，可以通知玩家开局了。
    local match_id = match.match_id
    local data = nk.json_encode({ op_code = OPCODE_DS_ASSIGNED , ds_url = ds_url})
    local response,optional_error_match_signal = nk.match_signal(match_id, data)
    if optional_error_match_signal then
        nk.logger_error("request_match_task Failed to match_signal: " .. optional_error_match_signal)
        return nk.json_encode({ success = false , error = optional_error_match_signal })
    end

    --返回结果&请求的数据
    return nk.json_encode({ success = true , match_id = match.match_id})
end


nk.register_rpc(request_match_task, "request_match_task")