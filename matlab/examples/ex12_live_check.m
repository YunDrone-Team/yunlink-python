% 12_LIVE_CHECK  对着现场 Bridge 跑示例会用到的路径。
%
% 做什么：搜索、连接、目录、attach、读状态、错误路径，然后起飞、平移、悬停、降落。
% 会不会飞：会。有 UAV 就动；有 UGV 就走。不限仿真。
% 桌面会先弹一次确认，默认「继续飞」。
% 本步要读：yunlink.env 或 yunlink.env.example。
% 上一步：前面编号都跑过更好；没跑过也可以直接用本脚本验收。
%
% 运动量在 yunlink_live_check.m 里：
%   起飞高度 1.0 米。
%   前进：速度 0.15 m/s × 0.6 秒 ≈ 0.09 米（不是「飞 0.15 米」）。
%   无人车点位：当前 x 加 0.3 米。
%
% 命令窗口输入：yunlink_live_check   或   ex12_live_check

yunlink_live_check();
