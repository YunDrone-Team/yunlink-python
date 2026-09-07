# YunLink Python 文档

这是 `yunlink-python` 的中文文档入口。SDK 通过 YunLink Bridge 连接 SunrayV2，
不连接 ROS，也不替代 Bridge。

## 推荐阅读顺序

1. 阅读[完整中文使用手册](USAGE_GUIDE_CN.md)，先理解 Bridge 和设备的两级连接关系。
2. 运行 [`examples/01_discover.py`](../examples/01_discover.py)，搜索局域网中的 Bridge。
3. 运行 [`examples/02_connect_and_inspect.py`](../examples/02_connect_and_inspect.py)，连接一个 Bridge 并打印设备目录。
4. 使用目录中的 `entity_uid` 运行 [`examples/03_watch_state.py`](../examples/03_watch_state.py)，attach 指定设备并读取状态。
5. 确认状态新鲜后，再运行基础控制、航点和取消示例。

## 文档索引

- [完整中文使用手册](USAGE_GUIDE_CN.md)
- [按步骤示例教程](../examples/README.md)
- [测试人员使用指南](../TESTER_GUIDE.md)
- [兼容性说明](../COMPATIBILITY.md)
- [MATLAB 包装说明](../matlab)

## 最重要的连接边界

```text
discover()
  -> 选择 Bridge endpoint_uid
  -> connect() / connect_discovered()
  -> client.entities() 读取 Bridge 设备目录
  -> 选择 entity_uid
  -> client.vehicle(uid) / client.ugv(uid) attach 设备
  -> 读取状态或发送控制
```

`endpoint_uid` 是 Bridge ID，`entity_uid` 是 Bridge 下具体 UAV/UGV 的设备 ID。
二者不能混用，也不能用 IP 地址代替设备 ID。

## 操作边界速查

| 阶段 | 典型调用 | 是否会操作设备 |
| --- | --- | --- |
| 搜索 | `discover()` | 否，只发送 discovery 查询 |
| 连接 Bridge | `connect(address)` | 否，只建立 Session 并协商 Profile |
| 查看目录 | `client.entities()` | 否，只读取设备目录 |
| 选择设备 | `client.vehicle(uid)` / `client.ugv(uid)` | 会 attach 并订阅状态 |
| 执行动作 | `takeoff()`、`move_to()`、`land()` | 会申请权限并发送控制命令 |
