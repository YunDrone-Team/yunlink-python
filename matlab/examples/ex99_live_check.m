% 99_LIVE_CHECK  对着现场 Bridge 跑示例会用到的路径。
%
% 做什么：搜索、连接、目录、attach、读状态、故意点一个不存在的设备。
% 会不会飞：默认不飞、不跑航点。桌面会问要不要短时 hover/Hold。
% 本步要读：yunlink.env 或 yunlink.env.example。
%
% 若只想手跑几个 example，最小集是：
%   ex00_setup → ex01_discover → ex02_connect_and_inspect →
%   ex03_watch_state → ex08_errors
% 这几条过了，其余只读脚本走的是同一套连接/目录/状态。

yunlink_live_check();
