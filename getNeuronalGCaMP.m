folder = 'C:\src\OpenAutoScope-v2_20240205_1502\data\myo-2_ReaChR\240606_myo-2-ReaChR_4hz_10x';
gch5 = dir([folder '\*behavior']);
radius = 5;
showimage =1;
recordVideo = 1;


for folderIdx = 1:length(gch5)
    %%% get tracking coordinates from videoEvents %%%
    h5fp = fullfile(gch5(folderIdx).folder,gch5(folderIdx).name);
    [events] = getVideoEvents(h5fp);
    frameIdx = 1;

    h5dir = dir([h5fp '\*.h5']);
    if showimage == 1
        vidfig = figure('Position',[680 433 608 545], 'Color', [1 1 1]);
        tiledlayout(2,2, "TileSpacing","tight",Padding= "compact")
        ax1 = nexttile([1 1]);
        ax2 = nexttile([1 1]);
        ax3 = nexttile([1 2]);

        if recordVideo ==1
            if exist('v','var') == 1
                close(v)
            end

            [pth, nm] = fileparts(folder);
            videopath = [folder '\' nm '_signalVideo_' num2str(folderIdx) '.mp4'];
            v = VideoWriter(videopath,"MPEG-4");
            v.FrameRate = 30;
            open(v);

        end

    end

    for h5Idx = 1:length(h5dir)

        h5File = fullfile(h5dir(h5Idx).folder,h5dir(h5Idx).name);
        info = h5info(h5File, '/data');
        h5size = info.Dataspace.Size;
        signal = nan(length(h5dir)*3600,1);
        time =linspace(0, length(h5dir)*3600/900,length(h5dir)*3600);

        for sliceIdx = 1:h5size(3)-1
            x = events.wormX(frameIdx);
            y = events.wormY(frameIdx);
            img = h5read(h5File, '/data',[1 1 sliceIdx],[h5size(1),h5size(2),1]);
            img = flipud(rot90(img));


            %%%% measure image pixels using meshgrid coordinates
            [imgX, imgY] = meshgrid(1:h5size(1),1:h5size(2));
            mask = (imgX - x).^2 + (imgY - y).^2 <= radius^2;
            signal(frameIdx) = mean(img(mask));

            if showimage==1
                bfimg = h5read(strrep(h5File,'gcamp','behavior'), '/data',[1 1 sliceIdx],[h5size(1),h5size(2),1]);
                bfimg = flipud(rot90(bfimg));

                imshow(bfimg,Parent=ax1)
                bfroi = drawcircle(ax1,Center=[x y], Radius=radius, MarkerSize=0.1,...
                    LineWidth=0.1);

                imshow(img,Parent=ax2)
                roi = drawcircle(ax2,Center=[x y], Radius=radius, MarkerSize=0.1,...
                    LineWidth=0.1);

                plot(ax3,time,signal)
                %                 xlim(ax3,[1,length(time)])
                ylabel(ax3,'GCaMP Signal (a.u.)')
                xlabel(ax3,'Time (min)')
                drawnow()
                if recordVideo == 1
                    frame = getframe(vidfig);
                    writeVideo(v,frame);
                end
            end

            frameIdx = frameIdx+1;
        end
    end
    if exist('v','var') == 1
        close(v)
    end
end
