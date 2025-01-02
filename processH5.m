function [h5Data] = processH5(foldername)
%Interpolates OAS behavior and GCaMP files to synchronize time
%   Detailed explanation goes here
% foldername = 'C:\src\OpenAutoScope-v2\data\zfis178';

% foldername = 'C:\src\OpenAutoScope-v2_20240205_1502\data\noFood_longDuration\250102_zfis178_unc-43(sa200)-noFoodLD\2025_01_02_12_34_55_flircamera_behavior'
d = dir([foldername '\*.h5']);
registerImage = 1;
showRegistration =0;
videostuff = 0;
mmPerStep = 0.001253814; % calibration for gcamp + behavior tracker
% mmPerStep = 0.001307092; % calibration for OAS behavior-only tracker

translation = [1 -3 0];


for i = 1:length(d)
    bPath = fullfile(d(i).folder,d(i).name);
    gPath =strrep(bPath,'behavior', 'gcamp');

    bTimes = h5read(bPath, '/times');
    gTimes = h5read(gPath, '/times');

    bData = h5read(bPath, '/data');
    gData = h5read(gPath, '/data');
    bFrames = size(bData,3);
    gFrames = size(gData,3);


    idx = NaN(gFrames,1);

    if videostuff == 1
        if exist('v','var') == 1
            close(v)
        end
        videopath = strrep(foldername, 'flircamera_behavior', 'Video.mp4');
        v = VideoWriter(videopath,'MPEG-4');
        v.FrameRate = 30;
        open(v)
    end



    for j=1:bFrames
        ii = find(gTimes >=bTimes(j), 1);
        if ~isempty(ii)
            idx(j) = ii;
        end
    end

    idx = idx(~isnan(idx));
    tempbf = bData(:,:,1:length(idx));
    tempgfp = gData(:,:,idx);
    temptime = bTimes(1:length(idx));
    if i == 1
        starttime = temptime(1);
    end


    if i == 1
        bf = tempbf;
        gfp = tempgfp;
        time = temptime;
    elseif i>1
        bf = cat(3,bf,tempbf);
        gfp = cat(3,gfp, tempgfp);
        time = cat(1,time, temptime);
    end

end



if registerImage == 1
    gfp = imtranslate(gfp(:,:,:),translation);

    if showRegistration == 1
        figure()
        for j = 1:length(gfp)
            imshowpair(bf(:,:,j) ,gfp(:,:,j))
            text(20,20, ['Time: ' num2str(round(time(j)-starttime,2)) ' sec'])
            %             pause(0.0001)

            if videostuff  == 1
                frame = getframe(gcf);
                writeVideo(v,frame);
            end
        end
    end
end


%% process log file
[fld, ~, ~]=fileparts(foldername);
logd = dir([fld '\*.txt']);
acq = 0; % acquires log data within recording range when set to 1;
stimTimes = [];
xLoc = NaN(length(time),1);
yLoc = NaN(length(time),1);
xflip = 1;
yflip = 1;

for i = 1:length(logd)
    fid = fopen(fullfile(logd(i).folder, logd(i).name),"r");

    while~feof(fid)
        line = fgetl(fid);
        l = regexp(line, ' ', 'split');
        lTime = str2double(l{1}); % time at current line

        if contains(line, 'command sent: DO _writer_start') % find a line matching the beginning of the recording
            ls = regexp(line, ' ', 'split');
            logStart = str2double(ls{1});
            if abs(logStart-starttime)<1
                acq= 1;
                disp(line)
            end
        end

        % stop acquisition when recording ends
        if lTime>max(time)
            disp(line)
            acq = 0;
            break
        end

        if acq == 1
            if contains(line, '<CLIENT WITH GUI> command sent: DO _teensy_commands_set_led o 1')
                stimTimes(end+1,1) = alignEvent(line,time);
                disp(line)
            end
        end

        if acq == 1
            if contains(line, 'tracker_behavior received position')
                locTime = alignEvent(line,time);
                r = regexp(line,' ', 'split');
                r = regexp(r{end}, '(-?\d+)', 'match');
                xl = str2double(r{1})*mmPerStep; % X coordinate in mm units
                yl = str2double(r{2})*mmPerStep; % Y coordinate in mm units

                % % check for crossing origin % % 
                if abs(xl)<0.01
                    if abs(xl)-abs(xLoc(locTime-1,1))>=0
                        xflip = xflip*-1;
                    end
                end

                if abs(yl)<0.01
                    if abs(yl)-abs(yLoc(locTime-1,1))>=0
                    yflip = yflip*-1;
                    end
                end
                
                % % convert orgin crossings to negative coordinates % % 
                xLoc(locTime,1) = xl*xflip;
                yLoc(locTime,1) = yl*yflip;




            end
        end

    end
    fclose(fid);
end

%% calculate instantaneous velocity

reltime = time-starttime;
firstsec = find(reltime>1,1);
secondsec = find(reltime>2,1);

sec = secondsec-firstsec;
velocity =NaN(length(time),1);

for i = 2:length(xLoc)-(sec+1)
    dx = xLoc(i)-xLoc(i+sec); %change in xLoc per second
    dy = yLoc(i)-yLoc(i+sec); %change in yLoc per second
    velocity(i) = sqrt(dx.^2 + dy.^2);
end

h5Data.gfp = gfp;
h5Data.bf = bf;
h5Data.time = time;
h5Data.startime = starttime;
h5Data.stimTimes =stimTimes;
h5Data.velocity = velocity;
h5Data.xLoc = xLoc;
h5Data.yLoc = yLoc;

end


function [idx] = alignEvent(event, time)
et = regexp(event, ' ', 'split');
eTime = str2double(et{1});
idx = find(time>=eTime,1);
end




