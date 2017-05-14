
%headlights!.............
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
   %if(rem(simuptime,200)==0)
   %    close(gcf);
   %end;
   if(cam)
        image0 = getsnapshot(vid);% Get the current frame
    else
        image0 = read(obj,simuptime);
    end;
    simuptime=simuptime+1;
    image1=image0;
    edited = imsubtract(image1(:,:,1)+image1(:,:,3)./8,150);%Reduce exposure values based on colour
    edited = medfilt2(edited, [3 3]);%Reduce noise
    edited = im2bw(edited,0.4);% Convert grayscale into a binary image
    disks = strel('disk',10,8);
    edited = imopen(edited, disks);% keep only circles
    edited = bwareaopen(edited,125);% Remove blobs less than 25px
    
    %bw = bwlabel(edited, 8);% Label all the connected components in the image.
    %blobs = regionprops(bw, 'BoundingBox', 'Centroid', 'Area'); % Image blob analysis4
    bw = bwconncomp(edited);
    blobs = regionprops(bw, 'BoundingBox', 'Centroid', 'Area');
    
    %Search for horizontal pairs of light source
    shadow(5)=0;  
    for(lights = 1:length(blobs))
        centroid1 = blobs(lights).Centroid;
        area1 = blobs(lights).Area;
        if(area1>=4500) continue; end;
        figure(1);
        border = blobs(lights).BoundingBox;subplot(2,2,2),rectangle('Position',border,'EdgeColor','g','LineWidth',1');
        a=text(centroid1(1)+15,centroid1(2)+20*lights, strcat('X:',num2str(round(centroid1(1))),' Y:',num2str(round(centroid1(2))),'  A',num2str(round(area1))));
        set(a, 'FontName', 'Arial', 'FontWeight', 'Normal', 'FontSize', 12, 'Color', 'green');
        if(centroid1(2)>50 && centroid1(1)>50)%crop
           % 
        for(check = lights+1:length(blobs))
            centroid2 = blobs(check).Centroid;    
            area2 = blobs(check).Area;
        angle=atand(abs(centroid1(2)-centroid2(2))/abs(centroid1(1)-centroid2(1)));% use tan inverse to find angle between 2 lights             
         
            
                if(abs(area1-area2)<2500)% Confirm equal area / intensity
                    
                        if(angle<15)
                        % Set new shadow position
                        border2 = blobs(check).BoundingBox;
                        subplot(2,2,2),rectangle('Position',border,'EdgeColor','r','LineWidth',3');
                        subplot(2,2,2),rectangle('Position',border2,'EdgeColor','r','LineWidth',3');
                        shadow(5)=1;
                        shadow(1)=border(1)-abs(centroid2(1)-centroid1(1))/10;
                        shadow(2)=border(2)-abs(centroid2(1)-centroid1(1))*2/3;
                        shadow(3)=border(3)+abs(centroid2(1)-centroid1(1))/2;
                        shadow(4)=round(abs(centroid2(1)-centroid1(1)))*2/3;
                        end
                    
                end 
                        
        end
        end
    if(shadow(5)==1) break;
    end   
    end
    % Set raw,processed and output screens
    figure(1);
    axis on;
    subplot(2,2,1),subimage(image0);title('Raw Footage');
    subplot(2,2,2),subimage((edited));title('Light Source Detection');
    subplot(2,2,3),subimage(image1); title('Realtime Shadow placement');hold on;
    if(shadow(5)) subplot(2,2,3),rectangle('Position',[shadow(1),shadow(2),shadow(3),shadow(4)],'EdgeColor','r','LineWidth',1,'FaceColor','g');hold off;end;
    subplot(2,2,4);subimage(imcomplement(edited));title('Headlight Output');hold off;
    subplot(2,2,4),rectangle('Position',[0,0,700,500],'EdgeColor','y','LineWidth',1,'FaceColor','y');hold on;
    if(shadow(5))subplot(2,2,4),rectangle('Position',[shadow(1),shadow(2),shadow(3),shadow(4)],'EdgeColor','k','LineWidth',1,'FaceColor','k','Curvature',[0.8,0.6]);hold off;end;
    if(Output)
        figure(2);
        subplot(1,1,1),subimage(imcomplement(edited));title('Headlight Output');
        subplot(1,1,1),rectangle('Position',[0,0,700,500],'EdgeColor','y','LineWidth',1,'FaceColor','y');hold on;
        if(shadow(5))subplot(1,1,1),rectangle('Position',[shadow(1),shadow(2),shadow(3),shadow(4)],'EdgeColor','k','LineWidth',1,'FaceColor','k','Curvature',[0.8,0.6]);hold off;end;
    end
    clearvars blobs;
end
% Both loops end here.
stop(vid);% Stop video aquisition.
flushdata(vid);% Flush all image data stored in memory buffer.
clear all% Clear all variables
clc