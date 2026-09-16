# 兼容性

| yunlink-python | yunlink | Sunray Profile | Python | MATLAB |
| --- | --- | --- | --- | --- |
| 1.3.x | >= 2.0.1（建图请用 GitHub v2.0.2 轮子） | com.yundrone.sunray 2.2 至 2.8 | 3.10、3.11、3.12、3.13 | R2022b 或更新 |

yunlink 绑定要求 CPython ≥ 3.10（`protobuf` 7 同样只要 3.10+）。MATLAB R2022a 官方只支持 3.8/3.9，因此不在支持范围。R2022b 请使用 Python 3.10。

SDK 当前宣告 `com.yundrone.sunray@2.8`，第一版使用的飞行类型为：

- 起飞、悬停、降落：minor 0
- 航点任务和 Planner 状态：minor 2
- MoveTo：复用单航点任务，minor 2

Bridge 必须同时协商 `org.yunlink.mobility@1` 和 `com.yundrone.sunray@2`。

1.3.x 不承诺恢复断线前的 Action。SDK 只恢复连接上下文和状态订阅。
