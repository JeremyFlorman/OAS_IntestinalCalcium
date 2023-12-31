foldername = 'C:\src\OpenAutoScope-v2\data\Escape_GCaMP6\231213_EscapeGC6_mec4Chrimson_10hz';
fpts = strsplit(foldername, '\');
d=dir([foldername '\*behavior']);

for i = 1:length(d)
    expName = [foldername '\' fpts{end} '_' num2str(i)];
    excelName = [expName '_ratio.xlsx'];

    if exist(excelName, 'file')
        [h5data] = processH5(fullfile(d(i).folder,d(i).name));
        excelData = readmatrix(excelName);


        framerate = 10;
        nframes = length(h5data.time);
        stimTime = h5data.stimTimes(1);
        relativeStart = stimTime/framerate*-1;
        relativeEnd = (nframes-stimTime)/framerate;
        relativeTime = linspace(relativeStart,relativeEnd,nframes)';
        GC_signal = excelData(:,2);
        f_zero = mean(GC_signal(1:stimTime-1));
        deltaF = (GC_signal-f_zero)/f_zero;
        data2write = [relativeTime deltaF h5data.velocity];





        disp(['writing experiment: ' expName])
        writecell({'Time','Delta f/f' 'Velocity'}, excelName, 'Range', 'E1')
        writematrix(data2write, excelName, 'Range', 'E2')

    end
end