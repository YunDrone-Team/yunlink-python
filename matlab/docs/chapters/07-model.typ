#import "../vendor/mantys/src/mantys.typ": *

= 连接与控制模型

== 两级标识

- *Bridge / 端点*：`endpoint_uid` 与连接地址 `ip:tcp_port`。搜索结果中的「连接地址」用于 `yunlink_connect`，「Bridge ID」用于多台时的选择。
- *实体*：`entity_uid`，例如 `e-f97f96-2-1`。用于 `yunlink_vehicle` 与 `yunlink_ugv`。显示名 `uav1` 仅供阅读。

== 三步调用

+ `yunlink_connect(address)` 建立与 Bridge 的会话。不 attach，不控制。
+ `yunlink_entities(client)` 读取目录。仍不 attach。
+ `yunlink_vehicle(client, entity_uid)` 或 `yunlink_ugv(client, entity_uid)` 才会 attach 并订阅遥测。

仅当调用起飞、平移、点位、Hold 等函数时，才会申请控制权并发送动作。只读订阅可与地面站并存。

== 状态字段

`yunlink_state` 返回 MATLAB 结构体，字段为 camelCase。飞行前请检查：

- `fresh`：为 false 或 0 时不要起飞。
- `landed`：已在空中时再次 `takeoff` 可能被 INIT 拒绝。
- `connected`：会话是否仍可用。
- `position.x` / `y` / `z`：单位米。
- `frameId`：世界系名称；为空时不要发送依赖坐标系的点位指令。

== 资源释放

请使用 `onCleanup` 在脚本结束或出错时关闭会话：

```matlab
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
```

控制函数返回 Python 对象 `ActionResult`。在 MATLAB `-batch` 中请使用 `string(result.detail)` 查看说明，以避免 `disp` 造成输出阻塞。

速度类指令带有时间租约。租约到期后结果常为 `CANCELLED`，表示本次租约已结束。
