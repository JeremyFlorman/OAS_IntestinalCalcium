folder = 'C:\src\OpenAutoScope-v2_20240205_1502\data\GCaMP_measurment\240305_cex-1_GCaMP6';
gch5 = dir([folder '\*gcamp']);
roiSz = 10;


for folderIdx = 1:length(gch5)
    %%% get tracking coordinates %%%
    h5fp = fullfile(gch5(folderIdx).folder,gch5(folderIdx).name);
    [events] = getVideoEvents(h5fp);
    frameIdx = 1;

    h5dir = dir([h5fp '\*.h5']);
    figure();
    for h5Idx = 1:length(h5dir)
        
        h5File = fullfile(h5dir(h5Idx).folder,h5dir(h5Idx).name);
        info = h5info(h5File, '/data');
        h5size = info.Dataspace.Size;

        for sliceIdx = 1:h5size(3)
            x = events.wormX(frameIdx);
            y = events.wormY(frameIdx);
            img = h5read(h5File, '/data',[1 1 sliceIdx],[h5size(1),h5size(2),1]);
            img = flipud(rot90(img));
            imshow(img)
            line(x,y,'Marker', 'o')
            drawnow()
            frameIdx = frameIdx+1;
        end        
    end



end

% getVideoEvents(folder)