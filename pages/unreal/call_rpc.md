## 执行Nakama RPC

在UE中想要执行Nakama RPC函数，有2种方式：
1. 通过HTTP请求，无需登录。
2. Nakama Plugin提供的接口，需要先登录。

两种方式都有自己的应用场景，在DS上与Nakama进行交互时，通过HTTP请求。在客户端与Nakama交互时，通过Plugin接口。

### 1. HTTP请求RPC

在luaruntime介绍三方服务器与Nakama交互时，就介绍了如何同通过HTTP执行Nakama RPC函数，当时是通过控制台或者Postman，现在换成在UE代码来发送Post请求即可。


```c++
///file:Source/ThirdPersonDemo/NakamaSubSystem.cpp

void UNakamaSubSystem::RpcByHttp(const FString& RpcId, const FString& Payload)
{
	//通过Http请求RPC，仅在DS可以使用，HttpKey属于机密信息，禁止编译到客户端。
#if UE_SERVER
	UE_LOG(LogNakamaSubSystem, Display, TEXT("UNakamaSubSystem::RpcByHttp RpcId: %s, Payload: %s"), *RpcId, *Payload);
	
	auto Http = &FHttpModule::Get();
	auto Request = Http->CreateRequest();
	Request->SetURL("http://127.0.0.1:7350/v2/rpc/rpc_echo?http_key=defaulthttpkey");

	//给IHttpRequest SetHeader
	Request->SetHeader(TEXT("User-Agent"), TEXT("X-UnrealEngine-Agent"));
	Request->SetHeader(TEXT("Content-Type"), TEXT("application/json"));
	Request->SetHeader(TEXT("Accepts"), TEXT("application/json"));

	//设置POST命令，传递json数据
	Request->SetVerb("POST");

	TSharedPtr<FJsonObject> JsonObject = MakeShareable(new FJsonObject());
	JsonObject->SetStringField(TEXT("key"), TEXT("value"));
	JsonObject->SetNumberField(TEXT("numberKey"), 42);
	JsonObject->SetBoolField(TEXT("boolKey"), true);

	FString JsonString;
	TSharedRef<TJsonWriter<>> Writer = TJsonWriterFactory<>::Create(&JsonString);
	FJsonSerializer::Serialize(JsonObject.ToSharedRef(), Writer);
	
	const FString EscapedPayload = EscapeJsonString(JsonString);
	Request->SetContentAsString(EscapedPayload);

	//设置回调函数
	Request->OnProcessRequestComplete().BindLambda([](FHttpRequestPtr Request, FHttpResponsePtr Response, bool bWasSuccessful)
	{
		if (!bWasSuccessful)
		{
			UE_LOG(LogNakamaSubSystem, Error, TEXT("HTTP Request failed"));
			return;
		}

		//获取返回的json数据
		FString ResponseStr = Response->GetContentAsString();
		UE_LOG(LogNakamaSubSystem, Display, TEXT("HTTP Response:%s"), *ResponseStr);
	});

	//发送请求
	Request->ProcessRequest();
#endif
}
```


### 2. Plugin接口请求RPC

Nakama Plugin提供了两种接口来请求RPC，一种是传递Session，另一个是传递HttpKey。

传递Session的接口用来调用玩家相关的RPC，例如更新账号数据。

```c++
///file:Source/ThirdPersonDemo/NakamaSubSystem.cpp

void UNakamaSubSystem::RpcBySession(const FString& RpcId, const FString& Payload)
{
	UE_LOG(LogNakamaSubSystem, Display, TEXT("UNakamaSubSystem::Rpc RpcId: %s, Payload: %s"), *RpcId, *Payload);
	
	if(IsValid(NakamaClient)==false)
	{
		UE_LOG(LogNakamaSubSystem, Error, TEXT("UNakamaSubSystem::Rpc NakamaClient is nullptr"));
		return;
	}
	
	// Notification RPC
	auto RPCSuccessCallback = [&](const FNakamaRPC& RPC)
	{
		UE_LOG(LogNakamaSubSystem, Display, TEXT("UNakamaSubSystem::Rpc Sent RPC with Payload: %s"), *RPC.Payload);

		if(!RPC.Payload.IsEmpty())
		{
			UE_LOG(LogNakamaSubSystem, Display, TEXT("UNakamaSubSystem::Rpc RPCWithHttpKey Test Passed - Payload: %s"), *RPC.Payload);
		}
		else
		{
			UE_LOG(LogNakamaSubSystem, Error, TEXT("UNakamaSubSystem::Rpc RPCWithHttpKey Test Failed"));
		}
	};

	auto RPCErrorCallback = [&](const FNakamaError& Error)
	{
		UE_LOG(LogNakamaSubSystem, Error, TEXT("UNakamaSubSystem::Rpc RPCWithHttpKey Test. ErrorMessage: %s"), *Error.Message);
	};

	NakamaClient->RPC(UserSession, RpcId, Payload, RPCSuccessCallback, RPCErrorCallback);
}
```

传递HttpKey的接口用来调用服务器框架相关的，例如获取服务器状态。

<font color=red>HttpKey属于机密信息，禁止在客户端使用！！</font>

```c++
/**
	 * Send an RPC message to the server using HTTP key.
	 *
	 * @param HttpKey The HTTP key for the server.
	 * @param Id The ID of the function to execute.
	 * @param Payload The string content to send to the server.
	 * @param SuccessCallback Callback invoked upon successfully sending the RPC message using the HTTP key and receiving a response.
	 * @param ErrorCallback Callback invoked if an error occurs, detailing the failure.
	 */
	void UNakamaClient::RPC ( // HTTPKey
		const FString& HttpKey,
		const FString& Id,
		const FString& Payload,
		TFunction<void(const FNakamaRPC& Rpc)> SuccessCallback,
		TFunction<void(const FNakamaError& Error)> ErrorCallback
	);
```

后续并不会使用这个接口，就不介绍了。



