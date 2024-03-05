function [videoEvents] = getVideoEvents(h5Folder,videotimes)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
if nargin<1
    h5Folder = 'C:\src\OpenAutoScope-v2_20240205_1502\data\GCaMP_measurment\240305_cex-1_GCaMP6\2024_03_05_13_04_49_flircamera_gcamp';
end

if nargin<2
    videotimes = getVideoTimeStamps(h5Folder);
end
xLoc = nan(length(videotimes),1);
yLoc = nan(length(videotimes),1);
xSteps = nan(length(videotimes),1);
ySteps = nan(length(videotimes),1);
wormX = nan(length(videotimes),1);
wormY = nan(length(videotimes),1);
velocity =NaN(length(videotimes),1);
% mmPerStep = 0.001307092; % for OAS behavior-only tracker
mmPerStep = 0.001253814; % for OAS gcamp+behavior tracker
stimidx = [];
fps=15;
stimnum = 1;


[pth,~,~] = fileparts(h5Folder);
logd = dir([pth '\*log.txt']);

for i =1:length(logd)
    fid = fopen(fullfile(logd(i).folder, logd(i).name),"r");

    while~feof(fid)
        line = fgetl(fid);
        l = regexp(line, ' ', 'split');
        lTime = str2double(l{1}); % time at current line

        % only look at log events during our recording
        if lTime > videotimes(1) && lTime < videotimes(end)
            % get stage coordinates
            if contains(line, 'tracker_behavior received position')
                locTime = alignEvent(line,videotimes);
                pattern = '(-?\d+),(-?\d+),(-?\d+)'; % Pattern to match three numbers separated by commas
                r = regexp(line, pattern, 'tokens');
                if ~isempty(r)
                    r=r{:};
                    xSteps(locTime,1) = str2double(r{1,1});
                    ySteps(locTime,1) = str2double(r{1,2});
                    xLoc(locTime,1) = str2double(r{1,1})*mmPerStep; % X coordinate in mm units
                    yLoc(locTime,1) = str2double(r{1,2})*mmPerStep; % Y coordinate in mm units
                end
            end
            % get stim events
            if contains(line, 'DO _teensy_commands_set_led o 1')
                stimidx(stimnum) = alignEvent(line,videotimes);
                stimnum = stimnum+1;
            end
            
            % get worm coordinates (where the worm center/tracking
            % coordinate is within the image)
            if contains(line, 'tracker_behavior <TRACKER-WORM-COORDS> x-y coords:')
                r = regexp(line,'(\d+),(\d+)','tokens');
                r=r{:};
                wormTime = alignEvent(line,videotimes);
                wormX(wormTime) = str2double(r{1});
                wormY(wormTime) = str2double(r{2});

            end
        end
    end
end





for i = 2:length(xLoc)-(fps+1)
    dx = xLoc(i)-xLoc(i+fps); %change in xLoc per second
    dy = yLoc(i)-yLoc(i+fps); %change in yLoc per second
    velocity(i) = sqrt(dx.^2 + dy.^2);
end

velocity(velocity>0.5) = NaN;


if ~isempty(stimidx)
Stimuli.stimtimes = videotimes(stimidx);
Stimuli.stim_xLoc = xLoc(stimidx);
Stimuli.stim_yLoc = yLoc(stimidx);
Stimuli.stim_xSteps = xSteps(stimidx);
Stimuli.stim_ySteps = ySteps(stimidx);
videoEvents.stimuli = Stimuli;
end

videoEvents.velocity = velocity;
videoEvents.xLoc = xLoc;
videoEvents.yLoc = yLoc;
videoEvents.xSteps = xSteps;
videoEvents.ySteps = ySteps;
videoEvents.videotimes = videotimes;
videoEvents.wormX = floor(fillmissing(wormX,'linear'));
videoEvents.wormY = floor(fillmissing(wormY,'linear'));
videoEvents.folder = h5Folder;
spltnm = strsplit(h5Folder, '\');
outname = [h5Folder '\' spltnm{end} '_videoEvents.mat'];
save(outname, "videoEvents");


    function [idx] = alignEvent(event, time)
        et = regexp(event, ' ', 'split');
        eTime = str2double(et{1});
        idx = find(time>=eTime,1);
    end

    function [time] = getVideoTimeStamps(h5Folder)
        d = dir([h5Folder '\*.h5']);
        for k = 1:length(d)
            h5path = fullfile(d(k).folder,d(k).name);
            temptime = h5read(h5path, '/times');

            if k == 1
                time = temptime;
            else
                time = cat(1,time, temptime);
            end
        end
    end

end