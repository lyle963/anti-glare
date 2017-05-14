%laser guided headlights!.............
whos;imaqreset;
memory;
clear;
delete(imaqfind);
g=input('Press enter to start','s');
close all;clc;
simtime = 5000;
Output=1;% set to 1 for separate o/p window
cam = 1;% 1 = set camera as input
shadow = [0,0,0,0,0];
if(cam)
a = imaqhwinfo;
[camera_name, camera_id, format] = getCameraInfo(a);
vid = videoinput(camera_name, camera_id,'YUY2_640X480');
set(vid, 'TriggerRepeat', Inf);
set(vid, 'ReturnedColorspace', 'rgb')
imaqmem(2000000000);
vid.FrameGrabInterval = 1;
% Start Video Capture
start(vid);
else obj = mmreader('car.avi');
end;
simuptime = 3830;
while (simuptime<=simtime)
   clearvars -except simuptime simtime Output cam vid obj
   if(rem(simuptime,200)==0)
       close(gcf);
   end;
   if(cam)
        image0 = getsnapshot(vid);% Get the current frame
    else
        image0 = read(obj,simuptime);
    end;
    simuptime=simuptime+1;
    image1 = image0;
    %edited = imsubtract(image0(:,:,1)+image0(:,:,3)./8,150);%Reduce exposure values based on colour
    edited = imsubtract(image1(:,:,1), rgb2gray(image1));
    edited = medfilt2(edited, [3 3]);%Reduce noise
    edited = im2bw(edited,0.2);% Convert grayscale into a binary image
    red_src = edited;
    edited = bwareaopen(edited,125);% Remove blobs less than 125px
    v=[3,40];
    lines = strel('rectangle',v);% only keep rectangels of dim 3x40
    im_lines= imopen(edited, lines);
    bw = bwconncomp(im_lines);
    blobs = regionprops(bw, 'BoundingBox', 'Centroid');% group for analysis
    %road is split into sections
    
    ysum=0;wsum=1;
    %Check beam for defects and find avg y posisiton of sections
     for(lights = 1:length(blobs))
        centroid1 = blobs(lights).Centroid;
        if(centroid1(2)>250 && centroid1(1)>50)%crop
            border = blobs(lights).BoundingBox;
            width=border(3);
            wsum=wsum+width;
            ypos=centroid1(2);
            ysum=ysum+(ypos*width);% weigh averages using width of section
        end
     end
     yavg=ysum/wsum;% get average y position
     for(lights = 1:length(blobs))
        centroid1 = blobs(lights).Centroid;
        if(centroid1(2)>250 && centroid1(1)>50)%crop
            border = blobs(lights).BoundingBox;
            ypos=centroid1(2);
            pos1=border(1);
            width=border(3);
            if(abs(ypos-yavg)<=15)
                figure(1),subplot(2,2,4),rectangle('Position',[pos1,250,width,60],'FaceColor','g');
                figure(2),rectangle('Position',[pos1,250,width,60],'FaceColor','g');
            end;
        end
     end
    % Set raw,processed and output screens
    figure(1);
    axis on;
    subplot(2,2,1),subimage(image0);title('Raw Footage');
    subplot(2,2,2),subimage((red_src));title('Red light Detection');
    subplot(2,2,3),subimage(im_lines); title('Line detection');hold on;
    subplot(2,2,4);subimage(imcomplement(edited));title('Headlight Output');hold off;
    subplot(2,2,4),rectangle('Position',[0,0,640,480],'FaceColor','y');hold on;
    subplot(2,2,4),rectangle('Position',[0,470,640,480],'FaceColor','r');hold on;
    if(Output)
        figure(2);
        subimage(imcomplement(edited));title('Headlight Output');hold off;
    	rectangle('Position',[0,0,640,480],'EdgeColor','y','LineWidth',1,'FaceColor','y');hold on;
    	rectangle('Position',[0,470,640,480],'FaceColor','r');hold on;
    end;
    clearvars blobs;
end
% Both loops end here.
stop(vid);% Stop video aquisition.
flushdata(vid);% Flush all image data stored in memory buffer.
clear all% Clear all variables
clc