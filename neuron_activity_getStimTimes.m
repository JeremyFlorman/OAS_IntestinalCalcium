foldername = 'C:\src\OpenAutoScope-v2\data\RIM_GCaMP6\231206_RIM_GCaMP6';
fpts = strsplit(foldername, '\');
d=dir([foldername '\*behavior']);

for i = 1:length(d)
    [h5data] = processH5(fullfile(d(i).folder,d(i).name));
    %%
    nframes = length(h5data.time);
    stimTime = h5data.stimTimes(1);
    relativeStart = stimTime/15*-1;
    relativeEnd = (nframes-stimTime)/15;
    relativeTime = linspace(relativeStart,relativeEnd,nframes)';
    data2write = [relativeTime h5data.velocity];

    expName = [foldername '\' fpts{end} '_' num2str(i)];
    excelName = [expName '_ratio.xlsx'];


    if exist(excelName, 'file')
        disp(['writing experiment: ' expName])
        writecell({'Time', 'Velocity'}, excelName, 'Range', 'E1')
        writematrix(data2write, excelName, 'Range', 'E2')

    end
end