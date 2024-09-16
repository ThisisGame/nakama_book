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




