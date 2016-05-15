clear all;

vidObj = VideoReader('Source2Cv\drop287.mp4');
imgObj = imread('Source2Cv\noload.JPG');
vidTitle = 'Dropping of mass onto board (m=287g)';
% startTime = 1.5; % Static loading and riding of mass (m=340g)
% startTime = 2.5; % Static loading, displacing, and removal of mass (m=340g)
% startTime = 1.2; % Static loading, displacing, and removal of mass (m=287g)
% startTime = 2; % Static loading, displacing, and removal of mass (m=140g)
% startTime = 1; % Static loading, displacing, and removal of mass (m=457g)
% startTime = 1; % Static loading, pushing, and removing of mass (m=170g)
% startTime = 2; % Static loading, pushing, and removing of mass (m=340g)
% startTime = 1; % Static loading, pushing, and removing of mass (m=287g)
startTime = 1; % Dropping of mass onto board (m=287g)

nFrames = vidObj.NumberOfFrames;
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

mov(1:nFrames) = ...
    struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
           'colormap',[]);
  
startFrame = ceil(startTime * vidObj.framerate);
displacement = zeros(nFrames-startFrame,10);
frame = nFrames;

pBar = waitbar(0,'Initializing...');
count = 1;

frame = startFrame;
% for frame = startFrame : nFrames
    mov(frame).cdata = read(vidObj,frame);
    vidFrame = mov(frame).cdata;
    hsvVid = rgb2hsv(imgObj);
    sPlane = 100*hsvVid(:,:,2);
    diff_im = (sPlane > 63) & (sPlane < 90);
    diff_im = medfilt2(diff_im, [10 6]);
    bw = bwlabeln(diff_im, 8);
    stats = regionprops(bw, 'BoundingBox', 'Centroid','Area');
    
    allStatsArea = [stats.Area];
    allowableAreaIndexes = (allStatsArea > 850) & (allStatsArea < 1800);
    keeperIndexes = find(allowableAreaIndexes);
    keeperStatsImage = ismember(bw, keeperIndexes);
    newBw = bwlabeln(keeperStatsImage, 8);
    stats = regionprops(newBw, 'BoundingBox', 'Centroid','Area');

% %     Display original image w/ detection
%     figure(1);
%     imshow(vidFrame)

%     hold on;
% 
%     for object = 1:length(stats)
%         bb = stats(object).BoundingBox;
%         bc = stats(object).Centroid;
%         rectangle('Position',bb,'EdgeColor','r','LineWidth',1)
%         plot(bc(1),bc(2), '-m+')
%         a=text(bc(1)+15,bc(2), strcat('X: ', num2str(round(bc(1))), '    Y: ', num2str(round(bc(2)))));
%         set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 6, 'Color', 'yellow');
%     end
%
%     mov(frame).cdata = frame2im(getframe);
%     hold off
   
    for i = 1:10
        displacement(count,i) = stats(i).Centroid(2);
    end

    count = count + 1;
    disp(sprintf('Frame is: %d', frame));
    perc = ceil((frame-startFrame)*100/(nFrames-startFrame));
    waitbar(perc/100,pBar,sprintf('Progress: %d%%',perc));
% end

close(pBar)
stdDev = std(displacement);
stdMean = mean(displacement);
smoothed = (displacement - stdMean)./3;

smoothed = smoothn(smoothed,'robust');
time = linspace(0,vidObj.Duration-startTime,size(smoothed,1));
time = time';

figure;hold;plot(time,smoothed);
grid on; title(vidTitle);
ylabel('Displacement (mm)');xlabel('Time (s)');

sprintf('%s','All frames processed!')
