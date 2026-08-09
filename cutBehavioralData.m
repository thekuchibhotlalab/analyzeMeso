% --- 1. 参数设置 ---
inputFile = 'G:\rockfish\ziyi\zz177_video\20260305152350.avi';   % 原视频的文件名或路径
outputFile = 'G:\rockfish\ziyi\zz177_video\20260305152350_output1.avi'; % 裁剪后保存的新文件名

startTime = 55;  % 裁剪起始时间（单位：秒）
endTime = 75;   % 裁剪结束时间（单位：秒）

% --- 2. 读取原视频 ---
vReader = VideoReader(inputFile);

% --- 3. 设置输出视频 ---
% 注意：VideoWriter 默认创建 AVI 文件
vWriter = VideoWriter(outputFile);
vWriter.FrameRate = vReader.FrameRate; % 保持与原视频相同的帧率，防止播放变快或变慢

% 打开写入对象
open(vWriter);

% --- 4. 定位并提取视频段 ---
% 将读取器的当前时间跳转到起始时间
vReader.CurrentTime = startTime;

disp('开始裁剪视频...');

% 使用 while 循环逐帧读取，直到到达结束时间或视频末尾
while hasFrame(vReader) && vReader.CurrentTime <= endTime
    % 读取一帧图像数据
    frame = readFrame(vReader);
    % 将该帧写入到新视频中
    writeVideo(vWriter, frame);
end

% --- 5. 关闭并保存文件 ---
close(vWriter);

disp('视频裁剪并保存完成！');