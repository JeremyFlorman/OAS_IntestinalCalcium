path = 'C:\src\OpenAutoScope-v2-development\data\240903_tph-1_GCaMP_10mM_TA\2024_09_03_15_29_01_flircamera_gcamp';

d= dir([path '\*.h5']);

fp = fullfile(d.folder,d.name);
info = h5info(fp, '/data');

imgWidth = info.Dataspace.Size(1);
imgHeight = info.Dataspace.Size(2);
nFrames = info.Dataspace.Size(3);
signal = nan(nFrames,1);

figure()
t = tiledlayout(2,1);
ax1 = nexttile;
ax2 = nexttile;

for i = 1:nFrames
    img = h5read(fp, '/data', [1 1 i], [imgWidth imgHeight 1]);
    mask = false([imgWidth imgHeight 1]);

    values = sort(reshape(img,[],1),'descend'); % make vector of img values
    cutoff = values(ceil(.00001*length(values))); % find a brightness cutoff

    [row,col,~] = find(img>cutoff);

    mask(row,col) = 1;
    mask = imdilate(mask,strel('disk',10));
    outline = bwmorph(mask,'remove');

    signal(i) = sum(img(mask))/nnz(mask); % calculate the signal by adding the value of the pixels and dividing by number of pixels
    time =linspace(0,nFrames/20, nFrames);
    
    
    imshow(imoverlay(img,outline,'green'),'Parent',ax1);
    plot(time(:), signal(:),'Parent',ax2)
    
    pause(0.05)

    % imshow(img, [0 100])
    % drawnow()

    
end

