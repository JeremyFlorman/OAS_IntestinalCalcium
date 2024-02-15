function [] = previewH5(h5Folder)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
[fn, fp] = uigetfile('C:\src\OpenAutoScope-v2_20240205_1502\data\xy10x_all_YA_10x_2x2bin\2024_02_12_13_29_22_flircamera_behavior\*.h5')
% h5Folder = 'C:\src\OpenAutoScope-v2\data\Hannah\2024_1_30_wt\2024_01_30_10_41_07_flircamera_behavior';
%
% d = dir([h5Folder '\*.h5']);
% figure();
% for i = 1:length(d)
h5File = fullfile(fp,fn);

info = h5info(h5File, '/data');
h5size = info.Dataspace.Size;

figure();

for j = h5size(3):-5:1
    img = h5read(h5File, '/data',[1 1 j],[h5size(1),h5size(2),1]);
    imshow(img)
    % imshow(rot90(img(:,:,j),3))
    drawnow()
end


% end