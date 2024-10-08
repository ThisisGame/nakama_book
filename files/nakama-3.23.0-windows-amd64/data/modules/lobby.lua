--导入nakama库
local nk = require("nakama")
nk.logger_info("Lobby module loaded")

--已经分配DS
local OPCODE_DS_ASSIGNED = 1

local M = {}

--- 当nk.match_create函数创建匹配项时调用，并设置匹配项的初始状态，仅在比赛开始时调用一次。
---@param context table 表示有关匹配项和服务器的信息，以供参考。
---@param initial_state table 可以是匹配的用户或您希望传递到此函数的任何其他数据。
---@return table, number, string
function M.match_init(context, initial_state)
	nk.logger_info("Match init")

	--state创建对局的成员变量，它在对局的每个函数中作为参数传递，如果是nil则结束比赛。
	local state = {
		initial_state = initial_state,
		presences = {},
		empty_ticks = 0
	}
	local tick_rate = 1 --每秒调用match_loop函数次数，相当于服务器的帧率。

	local label = {
        local_dev_ds_mode = tostring(state.initial_state.local_dev_ds_mode),--是否本地Dev DS模式
		ds_assigned = tostring(false),--是否已经分配DS
    }
	local match_label = nk.json_encode(label) --对局的标签，在MatchList中显示时，用于筛选的标签。调用dispatcher.match_label_update("updatedlabel")更新

	return state, tick_rate, match_label
end

--- 当客户端调用match_join时调用，可以控制玩家是否能加入对局，返回true表示允许加入，返回false表示不允许加入。
---@param context table 表示有关匹配项和服务器的信息，以供参考。
---@param dispatcher table 提供一些函数，例如dispatcher.broadcast_message(给玩家发消息)
---@param tick number 当前帧数
---@param state table 对局的成员变量，它在对局的每个函数中作为参数传递，如果是nil则结束比赛。
---@param presence table 包含加入对局的玩家信息
---@param metadata table 客户端请求加入对局的附加信息
function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	nk.logger_info("Match join attempt, user_id: " .. presence.user_id)
	-- Presence format:
	-- {
	--   user_id = "user unique ID",
	--   session_id = "session ID of the user's current connection",
	--   username = "user's unique username",
	--   node = "name of the Nakama node the user is connected to"
	-- }
	return state, true
end

function M.match_join(context, dispatcher, tick, state, presences)
	nk.logger_info("Match join")

	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = presence
	end

	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	nk.logger_info("Match leave")

	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = nil
	end

	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
	nk.logger_info("Match loop, tick: " .. tick)

	-- 计算当前对局中的玩家数量
	local totalPresences = 0
	for k, v in pairs(state.presences) do
		totalPresences = totalPresences + 1
	end

	--如果没有人加入，记录空帧数
	if totalPresences == 0 then
		state.empty_ticks = state.empty_ticks + 1
	end

	-- 等了600帧，还没有人加入，结束对局，因为是1秒调用一次，所以是10分钟。
	if state.empty_ticks > 600 then
		return nil
	end

	return state
end

--接收到外部信号，例如分配了DS，通知所有玩家连接DS
function M.match_signal(context, dispatcher, tick, state, data)
	nk.logger_info("Match signal, data: " .. data)

	--解析data
	local data_decode = nk.json_decode(data)

	if OPCODE_DS_ASSIGNED == data_decode.op_code then
		local opcode = OPCODE_DS_ASSIGNED
		local message = { ["message"] = "ds_assigned" , ["ds_url"] = data_decode.ds_url }
		local encoded = nk.json_encode(message)
		local presences = nil -- send to all.
		local sender = nil -- used if a message should come from a specific user.
		dispatcher.broadcast_message(opcode, encoded, presences, sender)

		--更新对局的标签，已经分配DS。
		local label = {
			local_dev_ds_mode = tostring(state.initial_state.local_dev_ds_mode),--是否本地Dev DS模式
			ds_assigned = tostring(true),
		}
		local match_label = nk.json_encode(label)
		dispatcher.match_label_update(match_label)
	end

	return state,"signal received: " .. data
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
	nk.logger_info("Match terminate")

	-- Grace period to allow clients to receive the match termination signal
	nk.match_terminate(grace_seconds)
end

return M