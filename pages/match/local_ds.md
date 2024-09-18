## 本地DS开发服

因为是先连接到局外服，然后CreateMatch，然后由DS去请求对局任务，然后局外服再通知客户端连接DS。

这个流程，就决定了，一个局外服只能用作一种类型。

用于远程DS的局外服，不能用作本地DS的局外服。

所以本地DS开发服是要单独搭建一个局外服的。

但是单独单间一个局外服，它也是一样的流程，本地启动DS后，从局外服请求对局任务，然后局外服把本地DS Url返回给编辑器。

看起来是没问题，那如果多个人同时使用这个本地DS开发服，就有问题了。

A创建对局-->B创建对局-->B启动完毕DS请求任务-->开发服把A的对局指派给了B的DS

所以直接用远程DS这套流程是不行的。

那么本地DS服就不用DS主动请求对局任务这套，而是最简单的，客户端创建对局后，局外服返回创建对局成功，编辑器收到结果就拉起DS并将MatchID作为启动参数传入，然后DS准备好，就通知局外服，局外服根据MatchID找到Match，发出Signal，然后dispatcher.broadcastMessage通知客户端。

大部分流程也是一样的。


同一个局外解决远程和本地DS两种模式？

这需要客户端通知局外，我这一局是本地DS，然后对这一局进行标记，标记为本地DS，这一局唯一的User就是我。

然后局外通知客户端匹配成功时，带上这个标记，客户端就直接拉起DS。

DS起来后向局外请求对局任务，传入玩家ID，拿到对应的对局任务，然后局外通知客户端连入DS。

可以在进行匹配时，带入自定义参数。

```lua
--- 当nk.match_create函数创建匹配项时调用，并设置匹配项的初始状态，仅在比赛开始时调用一次。
---@param context table 表示有关匹配项和服务器的信息，以供参考。
---@param initial_state table 可以是匹配的用户或您希望传递到此函数的任何其他数据。
---@return table, number, string
function M.match_init(context, initial_state)
	nk.logger_info("Match init")

	--state创建对局的成员变量，它在对局的每个函数中作为参数传递，如果是nil则结束比赛。
	local state = {
		presences = {},
		empty_ticks = 0
	}
	local tick_rate = 1 --每秒调用match_loop函数次数，相当于服务器的帧率。
	local label = "" --比赛的标签，在MatchList中显示时，用于筛选的标签。

	return state, tick_rate, label
end
```

感觉`initial_state`这里能够传入自定义参数。

```lua
--创建一场匹配赛，lobby 是lua脚本名字
local match_id,optional_error_match_create=nk.match_create("lobby", {debug = true, expected_users = matched_users})
```

应该是这里传入的自定义参数，一个Table，改成下面的

```lua
--创建一场匹配赛，lobby 是lua脚本名字
local match_id,optional_error_match_create=nk.match_create("lobby", {debug = true, expected_users = matched_users, is_local_dev_ds = true, dev_user_id  = matched_users[0].presence["user_id"]})
```

这样就可以标记这一个对局是本地DS了。

那么现在的问题是，如何开一个单人局？

还有一个问题就是，客户端创建对局时传入的参数并不会传递到Hook里？还是说在matched_users某个字段里？

```lua
local function matchmaker_matched(context, matched_users)
    nk.logger_info("Matchmaker matched users: " .. #matched_users)

    --打印匹配成功的用户信息
    for _, m in ipairs(matched_users) do
        nk.logger_info("user_id:" .. m.presence["user_id"])
        nk.logger_info("session_id:" .. m.presence["session_id"])
        nk.logger_info("username:" .. m.presence["username"])
        nk.logger_info("node:" .. m.presence["node"])

        for _, p in ipairs(m.properties) do
            nk.logger_info("propertie:" .. p)
        end
    end
    ......
end
```

---------------------

Nakama内部限制了最小匹配人数是2

Invalid minimum count, must be >=2

在  https://github.com/heroiclabs/nakama/blob/5d71edf31f894f48803f5b30a0eb6c229beb8964/server/pipeline_matchmaker.go#L31

```go
func (p *Pipeline) matchmakerAdd(logger *zap.Logger, session Session, envelope *rtapi.Envelope) (bool, *rtapi.Envelope) {
	incoming := envelope.GetMatchmakerAdd()

	// Minimum count.
	minCount := int(incoming.MinCount)
	if minCount < 2 {
		_ = session.Send(&rtapi.Envelope{Cid: envelope.Cid, Message: &rtapi.Envelope_Error{Error: &rtapi.Error{
			Code:    int32(rtapi.Error_BAD_INPUT),
			Message: "Invalid minimum count, must be >= 2",
		}}}, true)
		return false, nil
	}
```

确实是写死了。

可能得改改代码，或者放弃MatchMaker支持单人本地DS

---

Client Relayed模式里的客户端直接请求创建对局，

```c++
void UNakamaRealtimeClient::CreateMatch(
	TFunction<void(const FNakamaMatch& Match)> SuccessCallback,
	TFunction<void(const FNakamaRtError& Error)> ErrorCallback)
{
	SendMessageWithEnvelope(TEXT("match_create"), {},
		[SuccessCallback](const FNakamaRealtimeEnvelope& Envelope)
		{
			if (SuccessCallback)
			{
				FNakamaMatch Match = FNakamaMatch(Envelope.Payload);
				SuccessCallback(Match);
			}
		},
		[ErrorCallback](const FNakamaRtError& Error)
		{
			if (ErrorCallback)
			{
				ErrorCallback(Error);
			}
		}
	);
}
```

原来就是直接跳过了匹配，创建了对局……，直接执行了`match_create`。

而普通的匹配是先匹配成功后，然后在`files\nakama-3.23.0-windows-amd64\data\modules\hook_matchmaker_matched.lua` 匹配成功的Hook中调用了`match_create`。

```lua
--创建一场匹配赛，lobby 是lua脚本名字
local match_id,optional_error_match_create=nk.match_create("lobby", {debug = true, expected_users = matched_users})
if optional_error_match_create then
    nk.logger_error("Failed to create match: " .. optional_error_match_create)
    return match_id,optional_error_match_create
end
nk.logger_info("Match created with ID: " .. match_id)
```

那么就用这个来做本地DS，客户端成功后直接拉起，不在服务器做存储，但是什么时候去连接DS呢？

看下有没有register来hook

    https://heroiclabs.com/docs/nakama/server-framework/introduction/hooks/#message-names

```
MatchCreate	

A client to server request to create a realtime match.
```

可以使用这个。可以添加before和after，这里就用after来将这个对局记录到StorageEngine中。

也测试一下这个after，对在`files\nakama-3.23.0-windows-amd64\data\modules\hook_matchmaker_matched.lua` 匹配成功的Hook中调用的`match_create`，是否生效，如果生效那就很方便了，做统一处理存储到StorageEngine。

获取对局信息 https://heroiclabs.com/docs/nakama/server-framework/lua-runtime/function-reference/#match_get


看下match_get会不会返回dispatcher

```
{"level":"info","ts":"2024-09-18T20:46:56.845+0800","caller":"server/runtime_lua_nakama.go:2329","msg":"Match retrieved: {\"authoritative\":true,\"handler_name\":\"lobby\",\"label\":\"\",\"match_id\":\"042bfc8d-610c-4b94-b533-ef18675ef82b.nakama\",\"size\":0,\"tick_rate\":1}","runtime":"lua","mode":"matchmaker"}
```

不太行，返回的是基础信息？

