function yunlink_close(client)
%YUNLINK_CLOSE 关闭 Bridge 连接并释放 Session。
%   建议配合 onCleanup(@() yunlink_close(client))，避免脚本中途出错时占着连接。
client.close();
end
