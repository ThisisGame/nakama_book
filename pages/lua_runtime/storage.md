
https://heroiclabs.com/docs/nakama/server-framework/lua-runtime/function-reference/#storage_read
https://heroiclabs.com/docs/nakama/server-framework/lua-runtime/function-reference/#storage_write

https://heroiclabs.com/docs/nakama/concepts/storage/collections/

### 1. 存储结构

官方文档介绍数据存储结构如下：

```
Collection
+---------------------------------------------------------------------+
|  Object                                                             |
|  +----------+------------+-------------+-----+-------------------+  |
|  | ?UserId? | Identifier | Permissions | ... |       Value       |  |
|  +---------------------------------------------------------------+  |
+---------------------------------------------------------------------+
```

一脸懵逼，还是用一个例子来解释吧。

要存储玩家的等级奖励领取状态，在使用NoSql数据库时，需要设计一个表，命名为`player_level_rewards_status`，结构如下：

|奖励等级   |玩家ID   |奖励领取状态 |
|---|---|---|
|reward_level   |player_id   |status|
|5   |4ec4f126-3f9d-11e7-84ef-b7c182b36521   |{"get":1,"timestamp":1725632295}|

Nakama存储引擎存储数据的结构和NoSql类似，在Nakama中：

`Collection = Table`

`Object = Row`

`Identifier = reward_level` 表示这一行要存储的数据键。

`Value = status` 表示存储的数据值。

`UserId = player_id` 用来标志这一行数据是哪个玩家的。

这样好理解多了。


### 2. 读写权限

Nakama的存储引擎是为了用户设计的，所以每一行数据都必须存储`UserId`，并且还有一个字段`Permissions`存储当前这一条数据的读写权限。

客户端在写入一个Object时，无需设置Object的UserId字段，它就只能归属于当前用户，并且默认的`Permissions`也限定于当前用户读写。

```c++
//设置今天的心情(feeling)为不开心
auto successCallback = [](const NStorageObjectAcks& acks)
{
    std::cout << "Successfully stored objects " << acks.size() << std::endl;
};

std::vector<NStorageObjectWrite> objects;

NStorageObjectWrite savesObject;
savesObject.collection = "player_public_info";
savesObject.key = "feeling";
savesObject.value = "sad";
objects.push_back(savesObject);

client->writeStorageObjects(session, objects, successCallback);
```

```c++
//设置今天的心情(feeling)为不开心，所有人可见
auto successCallback = [](const NStorageObjectAcks& acks)
{
    std::cout << "Successfully stored objects " << acks.size() << std::endl;
};

std::vector<NStorageObjectWrite> objects;

NStorageObjectWrite savesObject;
savesObject.collection = "player_public_info";
savesObject.key = "feeling";
savesObject.value = "sad";
savesObject.permissionRead = NStoragePermissionRead::PUBLIC_READ;//设置为所有人可见，其他玩家客户端也可以调用readStorageObjects来读取。
objects.push_back(savesObject);

client->writeStorageObjects(session, objects, successCallback);
```

```c++
//读取当前用户的数据
auto successCallback = [](const NStorageObjects& objects)
{
  for (auto& object : objects)
    {
        std::cout << "Object key: " << object.key << ", value: " << object.value << std::endl;
    }
};

std::vector<NReadStorageObjectId> objectIds;
NReadStorageObjectId objectId;
objectId.collection = "player_level_rewards_status";
objectId.key = "5";
objectId.userId = session->getUserId();
objectIds.push_back(objectId);
client->readStorageObjects(session, objectIds, successCallback);
```

如果你想这个数据，公开给其他玩家访问，可以指定读权限。

```c++
/// The read access permissions.
enum class NStoragePermissionRead
{
    NO_READ     = 0,  ///< The object is only readable by server runtime.
    OWNER_READ  = 1,  ///< Only the user who owns it may access.
    PUBLIC_READ = 2   ///< Any user can read the object.
};
```

例如玩家设置了今天的心情，这个数据可以公开。



而写权限，并不能公开，一条数据由你创建，就只能你写入，不能给其他玩家修改。

```c++
/// The write access permissions.
enum class NStoragePermissionWrite
{
    NO_WRITE    = 0,  ///< The object is only writable by server runtime.
    OWNER_WRITE = 1   ///< Only the user who owns it may write.
};
```

唯一例外的是服务器，在服务器脚本里可以读写任何用户创建的数据，服务器脚本拥有最高权限。

```lua
--读取指定玩家的等级奖励领取状态

local user_id = "4ec4f126-3f9d-11e7-84ef-b7c182b36521"

local object_ids = {
  { collection = "player_level_rewards_status", key = "5", user_id = user_id },--读取等级5的奖励领取状态
  { collection = "player_level_rewards_status", key = "10", user_id = user_id }--读取等级10的奖励领取状态
}

local objects = nk.storage_read(object_ids)

for _, r in ipairs(objects) do
  local message = string.format("read: %q, write: %q, value: %q", r.permission_read, r.permission_write, r.value)
  nk.logger_info(message)
end
```

```lua
--更新指定玩家的等级奖励领取状态

local user_id = "4ec4f126-3f9d-11e7-84ef-b7c182b36521"

local new_objects = {
  { collection = "player_level_rewards_status", key = "5", user_id = user_id, value = "{\"get\":1,\"timestamp\":1725632295}" },--更新
  { collection = "player_level_rewards_status", key = "10", user_id = user_id, value = "{\"get\":0}", permission_read = 1, permission_write = 1 }--更新并指定权限
}

nk.storage_write(new_objects)
```