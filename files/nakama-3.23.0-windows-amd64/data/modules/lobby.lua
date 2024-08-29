local M = {}

--- 当nk.match_create函数创建匹配项时调用，并设置匹配项的初始状态，仅在比赛开始时调用一次。
---@param context table 表示有关匹配项和服务器的信息，以供参考。
---@param initial_state table 可以是匹配的用户或您希望传递到此函数的任何其他数据。
---@return table, number, string
function M.match_init(context, initial_state)
	--state创建对局的成员变量，它在对局的每个函数中作为参数传递，如果是nil则结束比赛。
	local state = {
		presences = {},
		empty_ticks = 0
	}
	local tick_rate = 1 --每秒调用match_loop函数次数，相当于服务器的帧率。
	local label = "" --比赛的标签，在MatchList中显示时，用于筛选的标签。

	return state, tick_rate, label
end

function M.match_join(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = presence
	end

	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = nil
	end

	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
  -- Get the count of presences in the match
  local totalPresences = 0
  for k, v in pairs(state.presences) do
    totalPresences = totalPresences + 1
  end

	-- If we have no presences in the match according to the match state, increment the empty ticks count
	if totalPresences == 0 then
		state.empty_ticks = state.empty_ticks + 1
	end

	-- If the match has been empty for more than 100 ticks, end the match by returning nil
	if state.empty_ticks > 100 then
		return nil
	end

	return state
end