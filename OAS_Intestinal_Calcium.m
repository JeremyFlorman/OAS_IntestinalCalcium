fld = 'C:\src\OpenAutoScope-v2_20240205_1502\data\myo-2_ReaChR\zfis178_myo-2-ReaChR\noFood+ATR\240617_zfis178_myo-2-ReaChR_4hz_+ATR'; % Folder containing the data you want to analyze
serverfolder = 'Z:\OAS\myo-2_ReaChR\Pumping Stimulation\zfis178_myo-2-ReaChR\noFood+ATR';  % upload everything to this location.

%% settings
startIndex = 1; % which video to start analysis.
startframe =1; % what frame to begin analysis

uploadresults = 1; % upload data to remote location (serverfolder)?
isremote = 0;    % is our tiff file on the server? If so, we'll copy to local
% folder to run the analysis then move the results to the
% server.

plotstuff = 1; % display tracking
videostuff =1; % record video
framerate = 7; % display video/plots every Nth iteration of loop.
fps = 15;      % frames per sec of input tiff.
troubleshoot =0; % show binary images instead of0 regular plots
showNormals = 1;
showAxialSignal = 1;

crop = 1; % num pixels to crop from image edge. set to 0 for no cropping.
minwormarea = 10000; %lower limit to worm area
maxwormarea = 20000; % upper limit to worm area
axSigLen = 200; % how many pixels to use for registering axial signal.
axSigHeight = 15; % how many pixels to sample across the width of the worm (i.e. dorsal to ventral)
axSigOrientation = 0; % 0=brighter signal on bottom, 1=brighter signal on top

useautothreshold = 1;% set to 1 to calculate a threshold for each image.
useadaptivethreshold = 0; % if useautothreshold is set to 0 adaptive thresholding can be used
removevignette = 30; % if not zero, size of kernel to use for flatfield correction.


%%
imgDir = dir([fld '\**\*behavior\*.h5']);
imgDir = unique({imgDir.folder});


for nf =startIndex:length(imgDir)
    path = imgDir{nf}
    h5Data = processH5(path);
    gfp = h5Data.gfp;
    bf = h5Data.bf;
    stimTimes = h5Data.stimTimes;
    velocity = h5Data.velocity;
    vel = smoothdata(velocity, 'gaussian', 15);

    [fold, nm, ~] = fileparts(path);
    protopath = regexp(fold,'\', 'split');
    expSuffix = [protopath{end} '_' num2str(nf)];
    protosavename = [fold '\' expSuffix];

    %%
    if plotstuff == 1
        if showAxialSignal == 0
            figure('Position', [978 233 719 653],'Color',[1 1 1]);
            tiledlayout(4,3,'Padding','compact')
            ax1 = nexttile([2 1]);
            ax2 = nexttile([2 1]);
            ax3 = nexttile([2 1]);
            ax4 = nexttile([1 1]);
            ax5 = nexttile([1 1]);
            ax6 = nexttile([1 1]);
            ax7 = nexttile([1 3]);
        elseif showAxialSignal == 1
            figure('Position',[340 77 887 903],'Color',[1 1 1]);
            tiledlayout(9,3,'TileSpacing', 'compact', 'Padding','tight')
            ax1 = nexttile([3 1]);
            ax2 = nexttile([3 1]);
            ax3 = nexttile([3 1]);
            ax4 = nexttile([2 3]);
            ax7 = nexttile([2 3]);
            areaAx = nexttile([1 3]);
            velAx = nexttile([1 3]);

        end


        if videostuff == 1
            vidfig = gcf;
            if exist('v','var') == 1
                close(v)
            end
            videopath = [fold '\' protopath{end} '_' num2str(nf) '_Tracking_Video.mp4'];
            v = VideoWriter(videopath,'MPEG-4');
            v.FrameRate = 15;
            open(v)
        end
    end

    %     if showNormals ==1
    %     normfig = figure();
    %     normAx = axes(Parent=normfig);
    %     end

    [imgWidth ,imgHeight, nFrames] = size(bf);




    axialSignal = NaN(nFrames, axSigLen);
    autoAxialSignal = NaN(nFrames, axSigLen);
    axialBF = NaN(nFrames, axSigLen);
    sumSignal = NaN(nFrames,1);
    bulkSignal = NaN(nFrames,1);
    bulkAboveBkg = NaN(nFrames,1);
    backgroundSignal = NaN(nFrames,1);
    orientation = NaN(nFrames,1);
    area = NaN(nFrames,1);
    mag = NaN(nFrames,1);

    time = linspace(0,round((nFrames)/fps/60,1),ceil(nFrames)); %minutes per frame
    wormIdx = [];

    % image registration transform
    %     theta = -5.1;
    %     translation = [-30 10];
    %     tform = rigidtform2d(theta,translation);
    %     rA = imref2d([imgWidth imgHeight]);

    %% Tracking Block
    for i = startframe:nFrames

        mCh = bf(:,:,i);
        GFP = gfp(:,:,i);
        %         GFP = imwarp(gfp(:,:,i),tform,'OutputView',rA);

        if removevignette ~=0
            mCh = imflatfield(mCh,removevignette);
        end

        if crop ~= 0
            mCh = mCh(crop:end-crop,crop:end-crop);
            GFP = GFP(crop:end-crop,crop:end-crop);
            imgWidth = size(mCh, 2);
            imgHeight = size(mCh,1);
        end
        %         imshow(imadjust(mCh))
        % set up thresholding and binary image processing
        if useautothreshold ==1
            T = graythresh(mCh);
            BW = imbinarize(mCh, T); % create mask
        elseif useadaptivethreshold == 1
            BW = imbinarize(mCh,'adaptive','ForegroundPolarity','dark','Sensitivity',0.6);
        end


        BW = imcomplement(BW);
        BW = bwmorph(BW,'clean');
        BW = bwmorph(BW,'fill');
        tempb = BW;

        BW = ~bwareaopen(~BW, 500);
        BW = imdilate(BW,strel('disk',4));
        BW = imerode(BW,strel('disk',4));
        tempb2 = BW;

        % identify connected objects
        CC = bwconncomp(BW);
        L = labelmatrix(CC);
        bwprops = regionprops(L, 'Area', 'Centroid','Orientation');

        % Filter connected components to get biggest most central object.
        if ~isempty(bwprops)
            xy = vertcat(bwprops.Centroid);
            x = xy(:,1);
            y = xy(:,2);
            distances = sqrt((imgWidth/2 - x) .^ 2 + (imgHeight/2 - y) .^ 2);
            [centralSize, centralIdx] = min(distances); % most central object
            [bigSize, bigIdx] = max([bwprops.Area]); % largest object

            % filtering block: wormIdx is the object that we suspect is the worm.
            % if the biggest object is also the most central object than we will
            % assume that is the worm. If there is another big object off center,
            % as will occur with vignetting, we will check to make sure that the
            % most central object is within a size range determined by the values
            % of minwormarea and maxwormarea.
            if bigIdx == centralIdx && bwprops(bigIdx).Area<= maxwormarea
                wormIdx = bigIdx;
            elseif bwprops(centralIdx).Area <= maxwormarea && ...
                    bwprops(centralIdx).Area >= minwormarea
                disp(['segmentation error at frame: ' num2str(i)]);
                wormIdx = centralIdx;
            else
                wormIdx = [];
            end

            % create a copy of the label matrix Lw that contains only the worm.
            Lw = L;


            %   imshow(label2rgb(L,'jet','k','shuffle'))
            if ~isempty(wormIdx)
                Lw(Lw~=wormIdx) = 0;

                orientation(i,1) = bwprops(wormIdx).Orientation;


                % generate mask, outline and skeleton
                mask = logical(Lw);
                outline = bwmorph(mask, 'remove',1);
                %             skel = bwskel(mask,'MinBranchLength', 20);
                skel = bwmorph(mask,'thin', inf);

                outskel = logical(outline+skel);
                [ep] = bwmorph(skel,'endpoints');


                % Extract Axial signal by sampling perpendicular lines from skeleton %

                if nnz(ep) >0
                    [ey,ex] = find(ep,1);
                    sortSkel= bwtraceboundary(skel,[ey ex],'E');
                    sortSkel = sortSkel(1:ceil(length(sortSkel)/2),:);

                    stepSize = 3; % # of points along spine for each spine segment
                    Clen = axSigHeight; % length of perpendicular line to sample

                    temptrace = cell(1,length(sortSkel)-1); %NaN(Clen,length(sortSkel)-1);
                    tempbf = cell(1,length(sortSkel)-1); %NaN(Clen,length(sortSkel)-1);
                    perpX = cell(1,length(sortSkel)-1);
                    perpY = cell(1,length(sortSkel)-1);



                    parfor ii = 1:length(sortSkel)-1
                        if ii+stepSize<length(sortSkel)
                            seg = sortSkel(ii:ii+stepSize,:);
                        else
                            seg = sortSkel(ii:end,:);
                        end



                        A = [seg(1,2) seg(1,1)]; % [x y] coords of point 1
                        B = [seg(end,2) seg(end,1)]; % [x y] coords of point 2

                        AB = B - A;     % Call AB the vector that points in the direction from A to B

                        % Normalize AB to have unit length
                        AB = AB/norm(AB);

                        % compute the perpendicular vector to the line
                        % because AB had unit norm, so will ABperp
                        ABperp = AB*[0 -1;1 0];

                        % midpoint between A and B
                        ABmid = (A + B)/2;
                        % Compute new points C and D, each at a ditance
                        % Clen off the line. Note that since ABperp is
                        % a vector with unit eEuclidean norm, if I
                        % multiply it by Clen, then it has length Clen.
                        C = ABmid + Clen*ABperp;
                        D = ABmid - Clen*ABperp;

                        try
                            temptrace(ii) = {improfile(GFP,[C(1);D(1)],[C(2);D(2)],Clen)};
                            tempbf(ii) = {improfile(mCh,[C(1);D(1)],[C(2);D(2)],Clen)};
                            perpX(ii) = {[C(1); D(1)]}
                            perpY(ii) = {[C(2); D(2)]}
                        catch
                        end
                    end

                    hold off



                    temptrace = cell2mat(temptrace);
                    tempbf = cell2mat(tempbf);
                    perpX = cell2mat(perpX);
                    perpY = cell2mat(perpY);

                    %                 h1 = plot(perpX,perpY);




                    if ~isempty(temptrace)
%                         tt = resample(max(temptrace), size(axialSignal,2), size(temptrace,2),5,20);  % max?
%                         abf = resample(mean(tempbf), size(axialSignal,2), size(tempbf,2),5,20);

                        % resample axial images
                        x1 = linspace(1,size(temptrace,2), size(temptrace,2));
                        x2 = linspace(1,size(temptrace,2),axSigLen);
                        temptrace = interp1(x1, temptrace',x2)';
                        tempbf = interp1(x1, tempbf',x2)';

                        tt = max(temptrace);
                        abf = mean(tempbf);


                        % % % % real-time autoFixSignal % % %
                        querryLength = length(tt)*0.1; % fraction of signal to querry
                        leftMean = mean(tt(1:querryLength),'omitnan');
                        rightMean = mean(tt(length(tt)-querryLength:length(tt)),'omitnan');

                        if axSigOrientation == 0
                            if leftMean>rightMean
                                temptrace = fliplr(temptrace);
                                tt = fliplr(tt);

                                abf = fliplr(abf);
                                tempbf = fliplr(tempbf);
                            end
                        else
                            if leftMean<rightMean
                                temptrace = fliplr(temptrace);
                                tt = fliplr(tt);

                                abf = fliplr(abf);
                                tempbf = fliplr(tempbf);
                            end
                        end

                        % % % % % % % % % % % % % % % % % % % %

                        axialBF(i,1:size(abf,2)) = abf;
                        axialSignal(i,1:size(tt,2)) = tt;
                    end
                end

                % Bulk signal and background signal
                blksig = GFP(mask);
                sumSignal(i,1) = sum(blksig,"all",'omitnan');
                bulkSignal(i,1) = mean(blksig,"all",'omitnan');
                backgroundSignal(i,1) = mean(GFP(~mask),'all','omitnan');

                abovebkg = blksig>mean(GFP(~mask));
                bulkAboveBkg(i,1) = mean(blksig(abovebkg)-mean(GFP(~mask)),"all",'omitnan');

                area(i,1) = bwprops(wormIdx).Area;



                if plotstuff == 1
                    if mod(i,framerate) == 0

                        imshow(label2rgb(L,'jet','k','shuffle'),'Parent', ax1)
                        title(ax1,'Binary Mask');
                        if showNormals == 1
                            line(perpX,perpY,'Color', [0.9 0.9 0.9],'Parent', ax1)
                            title(ax1,'Binary Mask + Normal Vectors');
                        end

                        if troubleshoot == 1
                            imshow(tempb,'Parent', ax2);
                            title(ax2,'Initial Threshold');

                            imshow(tempb2,'Parent', ax3);
                            title(ax3,'Processed Mask');
                        else
                            try

                                mdiff = size(mCh,2)-size(tempbf,2);

                                if mdiff>0
                                    mpadTrace = padarray(tempbf,[0, ceil(mdiff/2)],0,'both');
                                    mpadTrace = mpadTrace(:,1:size(mCh, 2));
                                elseif mdiff<0
                                    mpaTrace = tempbf(:,abs(mdiff):size(mCh, 2));
                                end

                                bfAdj = [0 1];
                                gfpAdj = [0 0.3];

                                mpad_Outskel = padarray(outskel, [size(mpadTrace,1),0], 'post');
                                mmergedImage = vertcat(mCh, mpadTrace);
                                mmergedOverlay = imoverlay(imadjust(mmergedImage, bfAdj), mpad_Outskel, [1 0 0]);
                                imshow(mmergedOverlay,'Parent', ax2)
                                title(ax2,'Brightfield');

                                gdiff = size(GFP,2)-size(temptrace,2);

                                if gdiff>0
                                    gpadTrace = padarray(temptrace,[0, ceil(gdiff/2)],0,'both');
                                    gpadTrace = gpadTrace(:,1:size(GFP, 2));
                                elseif gdiff<0
                                    gpaTrace = temptrace(:,abs(gdiff):size(GFP, 2));
                                end
                                map = turbo(256);
                                gpad_Outskel = padarray(outskel, [size(gpadTrace,1),0], 'post');
                                gmergedImage = vertcat(GFP, gpadTrace);
                                gmergedOverlay = imoverlay(imadjust(gmergedImage, gfpAdj), gpad_Outskel, [0 1 0]);
                                imshow(gmergedOverlay,'Parent', ax3)
                                colormap(ax3, "turbo")
                                title(ax3,'GCaMP');
                            catch
                                imshow(imoverlay(imadjust(mCh, bfAdj), outskel, [1 0 0]), 'Parent', ax2)
                                title(ax2,'Brightfield');

                                imshow(imoverlay(imadjust(GFP,gfpAdj), outskel, [0 1 0]), 'Parent', ax3)
                                title(ax3,'GCaMP');
                            end
                        end

                        if showAxialSignal == 0
                            plot(time,area(:), 'Parent', ax4);
                            title(ax4,'Worm Area');
                            ylabel(ax4,'Pixels');
                            xlabel(ax4,'Time (min)');

                            plot(time,orientation(:), 'Parent', ax5);
                            title(ax5,'Worm Orientation');
                            ylabel(ax5,'Degrees');
                            xlabel(ax5,'Time (min)');

                            plot(1:size(axialSignal,2),axialSignal(i,:), 'g',...
                                1:size(axialBF,2),axialBF(i,:),'r', 'Parent', ax6)
                            ax6.XLim = [0 size(axialSignal,2)];
                            ax6.YLim = [0 30];
                            title(ax6,'Signal Along Midline');
                            ylabel(ax6,'Mean Fluorescent Intensity (a.u.)');
                            xlabel(ax6, 'head <--- Distance (pixels) ---> tail');
                            legend(ax6,{'GCaMP6', 'Brightfield'}, 'Location', 'northwest', ...
                                'Box', 'off');
                            % axial signal
                        elseif showAxialSignal == 1
                            axsig = smoothdata(axialSignal(1:i,:),1,'gaussian',10)'-median(backgroundSignal(1:i),'omitnan');
                            imagesc(axsig,'Parent',ax4)
                            ax4.CLim = [0 100];
                            ax4.XLim = [1, length(axialSignal)];
                            ax4.XAxis.Visible = 0;
                            ax4.YTickLabel = [];
                            ax4.YTick = [];
                            ylabel(ax4, 'Axial Ca^2^+ Signal')
                            box(ax4, 'off')
                            colormap turbo

                            if ~isempty(stimTimes)
                                for k =1:length(stimTimes)
                                    hold(ax4, "on")
                                    if i>= stimTimes(k)
                                        plot(stimTimes(k),1,'Marker', 'diamond', 'Marker', 'v', 'MarkerSize', 8, 'MarkerFaceColor', [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0],'Parent', ax4)
                                    end
                                    hold(ax4, "off")
                                end
                            end
                        end
                        % bulk signal

                        plot(time,bulkSignal,time',backgroundSignal, 'Parent', ax7)
                        ax7.XLim = [0 time(end)];
                        ylabel(ax7, 'Bulk Ca^2^+ Signal');


                        %
                        if ~isempty(stimTimes)
                            for k =1:length(stimTimes)
                                if i>= stimTimes(k)
                                    hold(ax7, "on")
                                    plot(time(stimTimes(k)),ax7.YLim(2)*0.99,'Marker', 'v', 'MarkerSize', 8, 'MarkerFaceColor', [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0],'Parent', ax7)
                                    hold(ax7, 'off')
                                end
                            end
                        end
                        box(ax7, 'off')
                        ax7.TickLength = [0.005 0.005];

                        % Area
                        plot(time(1:i),smoothdata(area(1:i), 'gaussian', 30), 'Parent', areaAx)
                        ylabel(areaAx, 'Worm Area');
                        areaAx.TickLength = [0.005 0.005];
                        box(areaAx, 'off');
                        xlim(areaAx,[0 time(end)]);


                        % velocity
                        plot(time(1:i),smoothdata(velocity(1:i),'gaussian', 30), 'Parent', velAx)
                        if ~isempty(stimTimes)
                            for k =1:length(stimTimes)
                                if i>= stimTimes(k)
                                    hold(velAx, "on")
                                    plot(time(stimTimes(k)),velAx.YLim(2)*0.99,'Marker', 'v', 'MarkerSize', 8, 'MarkerFaceColor', [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0])
                                    hold(velAx, 'off')
                                end
                            end
                        end

                        xlim(velAx,[0 time(end)]);
                        ylabel(velAx, 'Velocity');
                        xlabel(velAx,'Time (min)');
                        velAx.TickLength = [0.005 0.005];
                        box off

                        drawnow

                        if videostuff == 1
                            frame = getframe(vidfig);
                            writeVideo(v,frame);
                        end
                    end
                end
            end
        end
        if mod(i,90) == 0
            disp(['Working... ' num2str((i/nFrames)*100) '% complete, just chill...'])
        end
    end

    disp('file processed in:')


    if exist('v','var') == 1
        close(v)
    end
    %% %%%%%%%%%%%%%%%%%%%%% Auto Fix Axial Signal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    autoAxialSignal = axialSignal;
    %     fractionToQuerry = 0.1;
    %     autoAxialSignal = autoFixSignal(axialSignal,fractionToQuerry);

    %     for ii = 1:length(axialSignal)
    %         left = mean(axialSignal(ii,1:10),'omitnan');
    %         right = mean(axialSignal(ii,end-10:end),'omitnan');
    %         if left > right
    %             autoAxialSignal(ii,:) = fliplr(axialSignal(ii,:));
    %             autoAxialBF(ii,:) = fliplr(axialBF(ii,:));
    %             axmat(ii,1) = {fliplr(axmat{ii,1})};
    %             axmat(ii,2) = {fliplr(axmat{ii,2})};
    %         elseif left <= right
    %             autoAxialSignal(ii,:) = axialSignal(ii,:);
    %             autoAxialBF(ii,:) = axialBF(ii,:);
    %         end
    %     end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






    % peak analysis
    [pk,loc,w] = findpeaks(bulkSignal,'MinPeakProminence',3.5,'MinPeakDistance',150);
    peakpad = fps*15; % framerate*time in seconds;
    pktime = linspace(-15,15, peakpad*2)';
    if isempty(loc)
        loc = NaN;
        locinmin = NaN;
    end

    pktraces = NaN(peakpad*2,length(loc));
    for k = 1:length(loc)
        prepeak = loc(k)-peakpad;
        postpeak = loc(k)+peakpad-1;
        temppeak = [];

        if prepeak>1 && postpeak<length(bulkSignal)
            pktraces(1:peakpad*2,k) = bulkSignal(prepeak:postpeak,1);
        elseif prepeak>1 && postpeak>length(bulkSignal)
            temptrace = bulkSignal(prepeak:end,1);
            pktraces(1:length(temptrace),k) = temptrace;
        end

    end
    pkmean = mean(pktraces,2,'omitnan');

    %% Save Stuff

    datasavename = [protosavename '_wormdata.mat']


    wormdata = struct();
    wormdata.autoAxialSignal = autoAxialSignal;
    wormdata.sumSignal = sumSignal;
    wormdata.bulkSignal = bulkSignal;
    wormdata.bulkAboveBkg = bulkAboveBkg;
    wormdata.backgroundSignal = backgroundSignal;
    wormdata.orientation = orientation;
    wormdata.area = area;
    wormdata.peakTraces = pktraces;
    wormdata.peakLoc = loc;
    wormdata.include = 1;
    wormdata.stimTimes = stimTimes;
    wormdata.velocity = h5Data.velocity;

    save(datasavename, 'wormdata')

    %% load stuff
    % tic
    %     load(datasavename)
    %     autoAxialSignal = wormdata.autoAxialSignal;
    %     sumSignal = wormdata.sumSignal;
    %     bulkSignal = wormdata.bulkSignal;
    %     bulkAboveBkg = wormdata.bulkAboveBkg;
    %     backgroundSignal =wormdata.backgroundSignal;
    %     wormdata.orientation = orientation;
    %     area = wormdata.area;
    %     pktraces = wormdata.peakTraces;
    %     loc = wormdata.peakLoc;
    %     stimTimes = wormdata.stimTimes;
    %     velocity = wormdata.velocity;

    %% Plot traces
    if ~exist('time','var')
        time = linspace(0,round((nFrames)/fps/60,1),nFrames); %minutes per frame
    end
    if ~exist('pk','var')
        [pk,loc,w] = findpeaks(bulkSignal,'MinPeakProminence',3.5, 'MinPeakDistance',150);
        peakpad = fps*15;
        pktime = linspace(-15,15, peakpad*2)';
        pkmean = mean(pktraces,2,'omitnan');
    end



    figure('Position', [135.4000 142.6000 902.6000 586.4000],Color=[1 1 1])
    t = tiledlayout(4,4,'TileSpacing','compact','Padding','tight');

    % % % Bulk Signal % % %
    nexttile([1 3])
    if ~isnan(loc)
        plot(time,bulkSignal,time(loc),pk*1.01, 'rv')
    else
        plot(time,bulkSignal)
    end
    hold on
    if ~isempty(stimTimes)
        ax = gca;
        plot(time(stimTimes),ax.YLim(2)*.98,'Marker', 'v', 'MarkerSize', 9, 'MarkerFaceColor', [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0])
    end

    plot(time, backgroundSignal)
    hold off

    xlim([0 time(end)])
    %     xlabel(gca, 'Time (min)')
    ylabel(gca,'Fluorescence (a.u.)');
    title(gca, 'Whole Animal Calcium Trace')
    ax = gca;
    xt = ax.XTick;
    xtl = ax.XTickLabels;
    ax.TickLength =[0.005 0.005];
    box off

    % % % Peak Profile % % %
    nexttile([1 1])
    plot(pktime, pktraces, 'Color', [0.7 0.7 0.7])
    hold on
    plot(pktime, pkmean, 'Color', [1 0 0], 'LineWidth', 2);
    hold off
    title(gca, 'Spike Profile');
    ylabel(gca,'Fluorescence (a.u.)');
    colormap bone
    box off

    % % % Axial Signal % % %
    ax = nexttile([1 3]);
    imagesc(smoothdata(autoAxialSignal,1,'gaussian',60)'-median(backgroundSignal,'omitnan'))
    title(gca, 'Axial Calcium Trace')
    hold on
    plot(loc,1, 'vw', 'MarkerFaceColor' ,[.4 .5 .6]);
    if ~isempty(stimTimes)
        plot(stimTimes,1,'Marker', 'diamond', 'Marker', 'v', 'MarkerSize', 9, 'MarkerFaceColor', [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0])
    end
    hold off
    box off

    %     xlabel('Time (min)')
    ax.XTick = xt*60*fps; %linspace(0,length(autoAxialSignal),length(xtl));
    ax.XTickLabels = xtl;
    ax.YTick = [20 size(autoAxialSignal,2)-20];
    ax.YTickLabel = {'Head', 'Tail'};
    ax.CLim =[0 50];
    colormap turbo
    ax.TickLength = [0.001 0.001];


    % % % Interval Histogram % % %
    nexttile([1 1])
    edges = 0:2:120;
    histogram(diff(loc)./fps,'BinEdges',edges);
    title(gca,'Inter-Peak Interval');
    ylim([0 10])
    xlim([0 120])
    xlabel(gca,'Time (s)');
    ylabel(gca,'Count');
    box off
    % % % Worm Area % % %
    nexttile([1 3]);
    plot(time,smoothdata(area,'gaussian', 30))
    xlim([0 time(end)])
    title(gca, 'Worm Area')
    ylabel(gca,'Pixels')
    %     xlabel(gca,'Time (min)')
    ax =  gca;
    ax.TickLength = [0.005 0.005];
    box off

    % % % Peak Widths % % %
    nexttile([1 1])
    histogram(w./fps,'BinEdges', 1:15);
    ylim([0 10])
    xlim([0 15])
    title(gca,'Peak Widths');
    ylabel(gca,'Count');
    xlabel(gca,'Time (s)');
    box off


    % % % Velocity  % % %
    nexttile([1 3]);
    plot(time,smoothdata(velocity,'gaussian',30))
    ax = gca;
    hold on
    if ~isempty(stimTimes)
        plot(time(stimTimes),ax.YLim(2)*.98,'Marker', 'v', 'MarkerSize', 9, 'MarkerFaceColor', [0.8 .2 .5], 'MarkerEdgeColor', [0 0 0])
    end
    hold off
    xlim([0 time(end)])
    title(gca, 'Velocity')
    ylabel(gca,'Steps/sec')
    xlabel(gca,'Time (min)')
    ax.TickLength = [0.005 0.005];
    box off

    %     nexttile([1 1]);
    %     plot(orientation,time);
    %     ylim([0 time(end)])
    %     title(gca, 'Worm Orientation')
    %     set(gca,'YDir', 'reverse')
    %     xlabel(gca,'Orientation (degrees)')
    %     ylabel(gca, 'Time (min)')



    reg = regexp(path, '\', 'split');
    reg = [reg{end-1} ' | ' reg{end}];
    title(t, strrep(strrep(reg,'_', ' ' ), 'flircamera behavior', ''));

    summaryPlotName = [protosavename '_Summary_Plots.png'];

    saveas(gcf, summaryPlotName)



    %% Copy to server
    if uploadresults == 1
        if isremote == 0  % if working with local files, upload to serverfolder (specified in settings)


            serverLocation = [serverfolder '\' expSuffix];

            if ~isfolder(serverLocation)
                mkdir(serverLocation);
            end


            % copy behavior h5 files
            behaviorH5Dir = imgDir{nf};
            [parentfolder, h5folder] = fileparts(behaviorH5Dir);
            [statusbeh,~,~]=copyfile(behaviorH5Dir, [serverLocation '\' h5folder '\']);

            % copy GCaMP h5 files
            gcampH5Dir = strrep(behaviorH5Dir, 'behavior', 'gcamp');
            [statusgc,~,~]=copyfile(gcampH5Dir, [serverLocation '\' strrep(h5folder, 'behavior', 'gcamp') '\']);

            % copy log files

            logDir = dir([parentfolder '\*log.txt']);
            for li = 1:length(logDir)
                [statuslog,~,~]=copyfile(fullfile(logDir(li).folder,logDir(li).name), serverLocation);
            end

            % copy wormdata
            [statuswormdata,~,~]=copyfile(datasavename, serverLocation);

            % copy summary plots
            [statussummaryplot,~,~]=copyfile(summaryPlotName, serverLocation);

            % copy summary plots
            [statusvideoplot,~,~]=copyfile(videopath, serverLocation);


        elseif isremote == 1  % if working with remote files, moved analyzed results back to where we found them.
            clear('img')

            % copy wormdata
            [statuswormdata,~,~]=copyfile(datasavename, serverLocation);

            % copy summary plots
            [statussummaryplot,~,~]=copyfile(summaryPlotName, serverLocation);

            % copy summary plots
            [statusvideoplot,~,~]=copyfile(videopath, serverLocation);

        end
    end


    if exist('wormdata', 'var')
        clear('wormdata');
    end

    if exist('img', 'var')
        clear('img')
    end

end











%% Move everything to z drive
% localfolders = dir('E:\Jeremy Acquisitions\FreelyMoving\Analysis\');
%
% for i = 3:length(localfolders)
%     query = ['Z:\Calcium Imaging\FreelyMoving\**\*' localfolders(i).name];
%     remotefolder = dir(query);
%     remotepath = fullfile(remotefolder.folder, remotefolder.name);
%
%     localdir = dir(fullfile(localfolders(i).folder, localfolders(i).name));     % move everything
%     ftm = fullfile({localdir.folder},{localdir.name});  %move everything
%     ftm = ftm(4:end);
%     for j = 1:length(ftm)
%          copyfile(ftm{j}, [remotepath '\'])
%      disp(['Moving: ' ftm{j} ' to ' remotepath])
%     end
%
%     axial = dir([fullfile(localfolders(i).folder, localfolders(i).name) '\*axialSignal.txt']); % move axial
%     plots = dir([fullfile(localfolders(i).folder, localfolders(i).name) '\*Summary_Plots.png']);  % move summary plot
%     copyfile(fullfile(axial.folder, axial.name), [remotepath '\'])
%     copyfile(fullfile(plots.folder, plots.name), [remotepath '\'])
% end


