%% this function takes processed H5 recordings and creates tiff videos 
% of the 30 seconds preceeding each calcium spike. This is useful for 
% counting pumping rate. 

d = dir('Z:\OAS\5-HT\-Food\unc-31-noFood');
dirflag= [d(:).isdir];
d = d(dirflag);
d = d(3:end);

for j = 7:length(d)
    folder = fullfile(d(j).folder,d(j).name)
% folder = 'Y:\OAS\5-HT\wildtype+5HT\231006_zfis178_wildtype+5HT_1';

settings = returnPlotSettings;
settings.OAS = 1;
settings.traceylimit = [0 20];
settings.peakthreshold = 4;
settings.axylimit = [0 45];
settings.trimExperimentLength =1;

wd = dir([folder '\*wormdata.mat']);
h5file = dir([folder '\*behavior\*.h5']);

wormdata = fullfile(wd(1).folder, wd(1).name);

[mtdata, ~] = processWormdata(wormdata, settings);

%%
timePre = settings.framerate*30;

locs = mtdata.peakLoc(1:end);
ints = mtdata.peakIntervals;
img =  [];
tic

for i = 1:length(h5file)
    tempfile = fullfile(h5file(i).folder, h5file(i).name);
    tempimg = h5read(tempfile, '/data');
    if i == 1
        img = tempimg;
    elseif i>1
        img = cat(3,img, tempimg);
    end
end
toc
%%

if isempty(locs)
locs = floor(length(img/2));
end

for i = 1:length(locs)
    if i == 1
        interval = 'NA';
    else
        interval = num2str(round(ints(i-1)));
    end

    outputFileName = [strrep(wd.name, 'wormdata.mat', ['bfImage_' num2str(i) '_interval(' interval ').tiff'])];
    localPath = ['C:\tmp\' outputFileName]
    destinationPath = [folder '\' outputFileName];

    temploc = locs(i);
    if temploc-timePre <1
        starttime = 1;
    else 
        starttime = temploc-timePre;
    end

    endtime = starttime+timePre;

    for k = starttime:endtime
        imwrite(img(:, :, k), localPath, 'WriteMode', 'append','Compression','none');
    end

    [status, ~, ~] = copyfile(localPath, destinationPath);
    
    if status==1
        disp([outputFileName ' Uploaded Successfully, cleaning up...'])
        delete(localPath);
    end

end
toc
end
