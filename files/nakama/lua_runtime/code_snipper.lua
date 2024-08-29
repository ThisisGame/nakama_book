--- 向一个或多个玩家发送消息
---@param op_code number
---@param data string json字符串，可以通过nk.json_encode(t)将table转换为json字符串
---@param presences table 目标玩家，如果为nil，则向所有玩家发送消息
---@param sender nkruntime.Presence 发送者，如果是某个玩家发送，那么这里就填特定玩家，如果为nil，则表示系统发送。
---@return error 一个可选错误，可能指示在向匹配参与者广播数据时出现问题。
function dispatcher.broadcast_message(op_code,data,presences,sender)
    -- body
    return nil
end

--- 玩家加入对局成功，已经准备好接受局内的消息
---@param context table 表示有关匹配项和服务器的信息，以供参考。
---@param dispatcher table 提供一些函数，例如dispatcher.broadcast_message(给玩家发消息)
---@param tick number 当前帧数
---@param state table 对局的成员变量，它在对局的每个函数中作为参数传递，如果是nil则结束比赛。
---@param presences table 包含加入对局的玩家信息
local function match_join(context, dispatcher, tick, state, presences)
	-- Presences format:
	-- {
	--   {
	--     user_id = "user unique ID",
	--     session_id = "session ID of the user's current connection",
	--     username = "user's unique username",
	--     node = "name of the Nakama node the user is connected to"
	--   },
	--  ...
	-- }
        local opcode = 1234
        local message = { ["hello"] = "world" }
        local encoded = nk.json_encode(message)
        local presences = nil -- send to all.
        local sender = nil -- used if a message should come from a specific user.
        dispatcher.broadcast_message(opcode, encoded, presences, sender)
	return state
end