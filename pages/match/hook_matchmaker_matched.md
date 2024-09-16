匹配成功后，创建对局

```lua
---file:files\nakama-3.23.0-windows-amd64\data\modules\hook_matchmaker_matched.lua

local function matchmaker_matched(context, matched_users)
    nk.logger_info("Matchmaker matched users: " .. #matched_users)

    --序列化matched_users为json字符串
    local matched_users_json = nk.json_encode(matched_users)
    nk.logger_info("Matchmaker matched users json: " .. matched_users_json)

    ......
end

-- 注册MatchMaker匹配成功后的处理
nk.register_matchmaker_matched(matchmaker_matched)
```

这里通过Log形式输出`matched_users`参数的结构。

```lua
{"level":"info","ts":"2024-09-17T00:12:13.942+0800","caller":"server/runtime_lua_nakama.go:2329","msg":"Matchmaker matched users json: [{\"presence\":{\"node\":\"nakama\",\"session_id\":\"62af3517-7446-11ef-adf7-006100a0eb06\",\"user_id\":\"f66610a6-1a19-4ea1-a788-19b5716e262b\",\"username\":\"SCchmMDCyc\"},\"properties\":{\"game_difficulty\":2,\"game_mode\":1,\"region\":\"zh\"}},{\"presence\":{\"node\":\"nakama\",\"session_id\":\"1bf01e33-7446-11ef-adf7-006100a0eb06\",\"user_id\":\"dbebd9b8-6d8c-47a5-95c9-41129eb330f6\",\"username\":\"CfHDpqsvhN\"},\"properties\":{\"game_difficulty\":2,\"game_mode\":1,\"region\":\"zh\"}}]","runtime":"lua","mode":"matchmaker"}
```

格式化后

```json
[
    {
        "presence": {
            "node": "nakama",
            "session_id": "62af3517-7446-11ef-adf7-006100a0eb06",
            "user_id": "f66610a6-1a19-4ea1-a788-19b5716e262b",
            "username": "SCchmMDCyc"
        },
        "properties": {
            "game_difficulty": 2,
            "game_mode": 1,
            "region": "zh"
        }
    },
    {
        "presence": {
            "node": "nakama",
            "session_id": "1bf01e33-7446-11ef-adf7-006100a0eb06",
            "user_id": "dbebd9b8-6d8c-47a5-95c9-41129eb330f6",
            "username": "CfHDpqsvhN"
        },
        "properties": {
            "game_difficulty": 2,
            "game_mode": 1,
            "region": "zh"
        }
    }
]
```

可以看到每个玩家都包含两份数据，`presence`是Nakama内的玩家信息，`properties`是客户端这一次匹配时自定义的一些数据。

```c++
// Matchmaker Params
// Note: Query: player_level >= 10 does not work. See: https://heroiclabs.com/docs/nakama/concepts/multiplayer/query-syntax/
// Doing * instead
TOptional<int32> MinCount = 2;
TOptional<int32> MaxCount = 4;
TOptional<FString> Query = FString("*");
TMap<FString, FString> StringProperties;
StringProperties.Add("region", "zh");
TMap<FString, double> NumericProperties;
NumericProperties.Add("game_mode", 1);
NumericProperties.Add("game_difficulty", 2);
TOptional<int32> CountMultiple = 2;

NakamaRealtimeClient->AddMatchmaker(MinCount, MaxCount, Query, StringProperties, NumericProperties, CountMultiple, SuccessCallback, ErrorCallback);
```

和客户端请求匹配时自定义的数据是对的上的，那么可以在这里指定这一局为本地DS。

在匹配成功之后，这些自定义属性也会下发到客户端。

```c++
// 匹配成功
NakamaRealtimeClient->SetMatchmakerMatchedCallback( [&](const FNakamaMatchmakerMatched& MatchmakerMatched)
{
    // Join Match by Token
    UE_LOG( LogNakamaSubSystem, Warning, TEXT( "Socket Matchmaker Matched, MatchId: %s" ), *MatchmakerMatched.MatchId );
    auto JoinMatchSuccessCallback = [this](const FNakamaMatch& Match)
    {
        UE_LOG(LogNakamaSubSystem, Display, TEXT("Joined Match. MatchId: %s"), *Match.MatchId);
        UGameHudDelegateSubSystem::Get(this)->OnNakamaMatchSuccess.Broadcast(Match.MatchId);
    };

    auto JoinMatchErrorCallback = [this](const FNakamaRtError& Error)
    {
        UE_LOG(LogTemp, Warning, TEXT("Join Match Error. Message: %s"), *Error.Message);
        UGameHudDelegateSubSystem::Get(this)->OnNakamaMatchError.Broadcast(Error.Message);
    };
    
    // NakamaRealtimeClient->JoinMatch(MatchmakerMatched.MatchId, {}, JoinMatchSuccessCallback, JoinMatchErrorCallback);

    NakamaRealtimeClient->JoinMatchByToken(MatchmakerMatched.Token, JoinMatchSuccessCallback, JoinMatchErrorCallback);
});
```

```c++
USTRUCT(BlueprintType)
struct NAKAMAUNREAL_API FNakamaMatchmakerMatched
{
	GENERATED_BODY()

	// The matchmaking ticket that has completed.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	FString Ticket;

	// The match token or match ID to join.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	FString MatchId;

	// Match join token.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	FString Token;

	// The users that have been matched together, and information about their matchmaking data.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	TArray<FNakamaMatchmakerUser> Users;

	// A reference to the current user and their properties.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	FNakamaMatchmakerUser Me;

	FNakamaMatchmakerMatched(const FString& JsonString);
	FNakamaMatchmakerMatched();

};
```

```c++
USTRUCT(BlueprintType)
struct NAKAMAUNREAL_API FNakamaMatchmakerUser
{
	GENERATED_BODY()

	// User info.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	FNakamaUserPresence Presence;

	// String properties.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	TMap<FString, FString> StringProperties;

	// Numeric Properties.
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Nakama|Matchmaker")
	TMap<FString, int32> NumericProperties;

	FNakamaMatchmakerUser(const FString& JsonString);
	FNakamaMatchmakerUser();
};
```