imgname = "C:\src\OpenAutoScope-v2\data\RIM_GCaMP6\231212_RIM_GCaMP6+mec-4Chrimson_10hz\231212_RIM_GCaMP6+mec-4Chrimson_10hz_1.tif";

fpts = strsplit(imgname,'\');
dataname = strrep(imgname, '.tif','_ratio.xlsx');
videopath = strrep(imgname, '.tif','_video.mp4');
data = readmatrix(dataname);

% signal = data(:,2);

time = data(:,5);
deltaF = smoothdata(data(:,6),'gaussian',5);
velocity = smoothdata(data(:,7), 'gaussian',5);
% f_zero = mean(signal(1:450));
% deltaF = smoothdata((signal-f_zero)/f_zero, 'gaussian',5);
% time = linspace(0,length(deltaF)/15,length(deltaF));


if exist('v','var') == 1
    close(v)
end

v = VideoWriter(videopath,'MPEG-4');
v.FrameRate = 30;
open(v)


vidfig = figure(Position=[1201 121 520 588], Color=[1 1 1]);
t=tiledlayout(4,1, "TileSpacing","compact",Padding="compact");
title(t,fpts{end}, 'Interpreter', 'latex')
imgAx = nexttile([2 1]);
sigAx = nexttile([1 1]);
velAx = nexttile([1 1]);

for i = 1:length(deltaF)
    img = imread(imgname,i);
    imshow(img, 'Parent',imgAx);
    text(imgAx, 10, 10, [num2str(round(time(i),2)) ' Sec'],'FontSize', 10, 'Color', [1 1 1])


    % Neuron Signal
    plot(sigAx,time(1:i),deltaF(1:i),'LineWidth', 1.5, 'Color', [0.38,0.78,0.09])
    line(sigAx, [min(time) max(time)], [0 0],'LineStyle', ':', 'Color', [0.5 0.5 0.5])
    xlim(sigAx,[min(time) max(time)])
    ylim(sigAx,[min(deltaF)*1.1 max(deltaF)*1.1])
    title(sigAx,'RIM Activity')
    ylabel(sigAx,'\DeltaF/F_0')
    box(sigAx,'off')

    if time(i)>= 0
        line(sigAx,0,max(deltaF)*1.03,'Marker', 'v', 'MarkerSize', 9, 'MarkerFaceColor',...
            [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0])
    end

    %Velocity
    plot(velAx,time(1:i),velocity(1:i),'LineWidth', 1.5, 'Color',[0.5 0.5 0.5])
    xlim(velAx,[min(time) max(time)])
    ylim(velAx,[min(velocity)*1.1 max(velocity)*1.1])
    title(velAx,'Speed')
    ylabel(velAx,'Steps/sec')
    xlabel(velAx, 'Time relative to stimulus (sec)')
    box(velAx,'off')
    if time(i)>= 0
        line(velAx,0,max(velocity)*1.03,'Marker', 'v', 'MarkerSize', 9, 'MarkerFaceColor',...
            [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0])
    end





    drawnow();

    frame = getframe(vidfig);
    writeVideo(v,frame);


end

close(v)