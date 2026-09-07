# 兼容性

| yunlink-python | yunlink | Sunray Profile | Python |
| --- | --- | --- | --- |
| 1.1.x | >= 2.0.1 | com.yundrone.sunray 2.2 至 2.8 | 3.10-3.12 |

SDK 当前宣告 `com.yundrone.sunray@2.8`，第一版使用的飞行类型为：

- 起飞、悬停、降落：minor 0
- 航点任务和 Planner 状态：minor 2
- MoveTo：复用单航点任务，minor 2

Bridge 必须同时协商 `org.yunlink.mobility@1` 和 `com.yundrone.sunray@2`。

1.1.x 不承诺恢复断线前的 Action。SDK 只恢复连接上下文和状态订阅。
