--导入nakama库
local nk = require("nakama")

--- 请求创建对局
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据，存着MatchID
function client_request_user_create_match(context, payload)
    nk.logger_info("client_request_user_create_match is called, user_id: " .. tostring(context.user_id))

    --打印context
    nk.logger_info(nk.json_encode(context))

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

    --将payload转为table
    local payload_table = nk.json_decode(payload)

    --创建一场匹配赛，lobby 是lua脚本名字
    local match_id,optional_error_match_create=nk.match_create("lobby", {debug = true , local_dev_ds_mode = payload_table.local_dev_ds_mode})
    if optional_error_match_create then
        nk.logger_error("Failed to create match: " .. optional_error_match_create)
        return nk.json_encode({ success = false , error = optional_error_match_create })
    end
    nk.logger_info("Match created with ID: " .. match_id)

    --返回结果&请求的数据
    return nk.json_encode({ success = true , match_id = match_id ,local_dev_ds_mode = payload_table.local_dev_ds_mode })
end


nk.register_rpc(client_request_user_create_match, "client_request_user_create_match")