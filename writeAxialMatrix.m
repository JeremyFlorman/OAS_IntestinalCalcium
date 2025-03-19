function [] = writeAxialMatrix(datapath)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
datapath = 'C:\src\OpenAutoSCope-v2\data\TrainingData\240207_QW135_L4_10x\240207_QW135_L4_10x_1_wormdata.mat';

load('C:\src\OpenAutoSCope-v2\data\TrainingData\240207_QW135_L4_10x\240207_QW135_L4_10x_1_wormdata.mat', 'wormdata')


axialMatrix= wormdata.axialMatrix;
outputfilename = strrep(datapath, 'wormdata.mat', 'Straigtened_Images.tiff');
if isfile(outputfilename)
    delete(outputfilename)
end

for i = 1:size(axialMatrix,3)
    img = uint8(axialMatrix(:, :, i));
    imwrite(img,outputfilename , 'WriteMode', 'append','Compression','none');
end