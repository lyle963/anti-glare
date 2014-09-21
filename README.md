anti-glare
==========


%% lyle963
%initialise values
simtime = 200;
% %{
a = imaqhwinfo;
[camera_name, camera_id, format] = getCameraInfo(a);
vid = videoinput(camera_name, camera_id, format);
set(vid, 'FramesPerTrigger', Inf);
set(vid, 'ReturnedColorspace', 'rgb')
vid.FrameGrabInterval = 1;


% Start Video Capture
start(vid);
simuptime = 0;
while(simuptime<=simtime)
    simuptime=vid.FramesAcquired;% Check no of frames completed
    image = getsnapshot(vid);% Get the current frame
    edited = imsubtract(image(:,:,1),150);%Reduce exposure values
    edited = medfilt2(edited, [3 3]);%Reduce noise
    edited = im2bw(edited,0.4);% Convert grayscale into a binary image.
    edited = bwareaopen(edited,400);% Remove blobs less than 400px
    bw = bwlabel(edited, 8);% Label all the connected components in the image.
    blobs = regionprops(bw, 'BoundingBox', 'Centroid', 'Area'); % Image blob analysis
   
    
    % Set raw,processed and output screens  
    subplot(1,3,1),subimage(image);title('Raw Footage'); 
    subplot(1,3,2),subimage(imcomplement(edited));title('Detection and masking'); 
    text(400,900,strcat('Simulation Progress: ',num2str(round((simuptime-1)*100/simtime)),'%'),'FontSize',14, 'Color','k','HorizontalAlignment','Center', 'VerticalAlignment','Bottom');
    axis off
    subplot(1,3,3),subimage(imcomplement(edited));title('Headlight Output'); 
    hold on
    subplot(1,3,3),rectangle('Position',[0,0,700,500],'EdgeColor','y','LineWidth',1,'FaceColor','y');
    lightposition = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    
    %populate array with x coordinate of light
    for (lights = 1:length(blobs))
        centroid1 = blobs(lights).Centroid;
        lightposition(lights)=round(centroid1(2));
    end
    
    %Search for horizontal pairs of headlightslights
    for(lights = 1:length(blobs))
        centroid1 = blobs(lights).Centroid;    
        area1 = blobs(lights).Area;
        border = blobs(lights).BoundingBox;subplot(1,3,2),rectangle('Position',border,'EdgeColor','r','LineWidth',2');
        a=text(centroid1(1)+15,centroid1(2), strcat('X:',num2str(round(centroid1(1))),' Y:',num2str(round(centroid1(2))),'  A',num2str(round(area1))));
        set(a, 'FontName', 'Arial', 'FontWeight', 'Normal', 'FontSize', 12, 'Color', 'green');
        for(check = lights+1:length(blobs))
            centroid2 = blobs(check).Centroid;    
            area2 = blobs(check).Area;
                      
            if(centroid1(2)-centroid2(2)<30)% search for pairs along x-axis
                if(abs(area1-area2)<3000)% Confirm equal area / intensity
                    if(abs(centroid1(1)-centroid2(1))<500) % Confirm distance between headlights
                        subplot(1,3,3),rectangle('Position',[0,0,700,500],'EdgeColor','y','LineWidth',1,'FaceColor','y');
                        rectangle('Position',[border(1)-30,border(2)-round(abs(centroid2(1)-centroid1(1))*2/3),30+border(3)+centroid2(1)-centroid1(1),round(abs(centroid2(1)-centroid1(1))*2/3)],'EdgeColor','k','LineWidth',1,'FaceColor','k','Curvature',[0.8,0.6]);
                    end
                end 
            end
        end
        
    end
    hold off
end
% Both the loops end here.


stop(vid);% Stop video aquisition.
flushdata(vid);% Flush all the image data stored in the memory buffer.
clear all% Clear all variables
clc
end
