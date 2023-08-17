close all
clear all
[fname,pname]=uigetfile('*.avi','Video');
filename=[pname,fname];
v=VideoReader(filename);
boundingbox=[28/2 29/2 320/2 321/2];

%% Tune Hyperparameters %
% set to 1 if you've traced cusps before for this video
loadprev=0; %0 

% for drawing the graph 'total' for total GOA
% 'both' for total GOA and fractional (area per cusp)
% 'fractional' for fractional only
plottype = 'both'; 

% Control mask size (thresholds..etc)
blend=-10; % bigger value means shrink mask def (-10)
stelsize=10; %bigger value means a bigger mask def (10)
thresh2=-0.02; %def (-0.02)

% Timing setting
starttime=0.1;
fps=480; %480 for camera frame rate, def (960)
endtime=v.Duration*(v.framerate/fps);

%method of creating finalmask
optionno=3; %2,3,4,5 def (3)
%pick closest to centre 'd' or largest area 'aa'
include_criteria='d'; %'d'

%use active contours or not (slows down code)
activecontours=1; %1
shrinkFactor=1; %def 0.8
maxIterations = 10; %active contour def 20
%%%%%%%%%%%%%%%%%%

%% 
if activecontours == 1
    vw = VideoWriter([filename(1:end-13),'_',int2str(optionno),int2str(blend),int2str(stelsize),int2str(thresh2),'_GOA_',int2str(fps),'fps_Active.mp4']);
else
        vw = VideoWriter([filename(1:end-13),'_',int2str(optionno),int2str(blend),int2str(stelsize),int2str(thresh2),'_GOA_',int2str(fps),'fps.mp4']);
end
vw.FrameRate = v.FrameRate;
open(vw)
frame1=1;
tm=[];
ca=0;
i=1;
cusprate1=[];
cusprate2=[];
cusprate3=[];

while hasFrame(v)
    if frame1==1
        tm=(starttime/(v.framerate/fps))*(v.framerate/fps);
        v.CurrentTime=starttime/(v.framerate/fps);
        if loadprev==1
            load([pname,'load_',fname(1:end-13),'.mat']);
            frame1=frame1+1;
            circ_region=regionprops(BW2);
        else
            Background=readFrame(v);
            frame1=frame1+1;
            %Display Background
            h_im=imshow(Background);title('BackGround');
            
            %Red region as part of background
            e = imellipse(gca,boundingbox);
            pause
            BW2 = createMask(e,h_im);
            circ_region=regionprops(BW2);
            circle_vals=double(BW2).*double(rgb2gray(Background));
            avg_circle_vals=mean(circle_vals(circle_vals>0));
            New_Background=(double(~BW2).*avg_circle_vals)+(double(BW2).*double(rgb2gray(Background)));
            h1 = imfreehand; %drawfreehand
            pause
            mask1=createMask(h1);
            h2 = imfreehand;
            pause
            mask2=createMask(h2);
            h3 = imfreehand;
            pause
            mask3=createMask(h3);
        end
        summask1=sum(mask1(:));
        summask2=sum(mask2(:));
        summask3=sum(mask3(:));
        a=0;
        a1=0;
        a2=0;
        a3=0;
        %v.CurrentTime=starttime;
        %tm=v.CurrentTime;
        
        %tm=(starttime/(v.framerate/fps))*(v.framerate/fps);
        %v.CurrentTime=starttime/(v.framerate/fps);
        ccentroid=circ_region.Centroid;
        save([pname,'load_',fname(1:end-13),'.mat'],'BW2', 'mask1','mask2','mask3')
    else
        
        frame1=frame1+1;
        %Display Current Frame
        CurrentFrame=readFrame(v);
        
        % Otsu method from gray to bw
        Out = rgb2gray(CurrentFrame);
        counts = imhist(Out, 16);
        T = otsuthresh(counts);
        outmask=imbinarize(Out,T-thresh2);
        % remove red region
        outmask(BW2==0)=1;
        
        %Separate HSV channels and use for masking
        currenthsv=rgb2hsv(CurrentFrame);
        % Get s channel (2)
        sChannel=currenthsv(:,:,2);
        % segment s channel into 3 labels
        level2 = multithresh(sChannel,2);
        vlabels = imquantize(sChannel,level2);
        smask(1:size(CurrentFrame,1),1:size(CurrentFrame,2))=true;
        smask(vlabels==1)=false;
        smask(BW2==0)=1;
        smask(vlabels~=1)=1;
        
        % Get v channel (3)
        vChannel=currenthsv(:,:,3);
        % segment v channel into 3 labels
        level2 = multithresh(vChannel,2);
        vlabels = imquantize(vChannel,level2);
        vmask(1:size(CurrentFrame,1),1:size(CurrentFrame,2))=false;
        vmask(vlabels==1)=true;
        vmask(BW2==0)=0;
        vmask(vlabels~=1)=0;
        %         figure, imshow(vmask,[]);
        %         pause
        
        % Final mask
        switch optionno
            case 1
                finalmask=vmask|smask;
                finalmask(~BW2)=0;
            case 2
                finalmask=~outmask & vmask;
            case 3
                finalmask=~outmask;
            case 4
                finalmask=~outmask | (vmask|smask);
                finalmask(~BW2)=0;
            otherwise
                finalmask=vmask;
        end
        %         figure, imshow(finalmask,[]);
        %         pause
        
        % Join closer regions together and fill
        vmask_filled = imfill(finalmask,8,'holes');
        %                         subplot(3,1,2),  imshow(BW_filled,[]);title('Subtraction MASK');
        
        % Keep central region only
        littleParts=regionprops(vmask_filled);
        clear d
        clear aa
        clear areachange
        
        % distance between each area centroid and previous centroid (or
        % circ centroid in case none). Also record change in area
        for i=1:length(littleParts)
            d(i)=norm(littleParts(i).Centroid-ccentroid);
            areachange(i)=norm(littleParts(i).Area-ca);
            aa(i)=littleParts(i).Area;
            
        end
        if exist(include_criteria,'var')
            switch include_criteria
                case 'aa'
                    [wat,wer]=max(aa);
                otherwise
                    [wat, wer]=min(d);
            end
            
            labelParts=bwlabel(vmask_filled);
            bwNEW=zeros(size(vmask_filled,1),size(vmask_filled,2));
            bwNEW(labelParts==wer)=1;
            ca=littleParts(wer).Area;
            
            ax1=subplot(2,2,1); imshow(rgb2gray(CurrentFrame)); title(fname(1:end-13));
            ax2=subplot(2,2,2); imshow(rgb2gray(CurrentFrame)); 

            %                 visboundaries(ax1,bwNEW,'Color','g');
            
            se = strel('diamond',stelsize); % bigger size, bigger the mask
            bwNEW_dilated = imdilate(bwNEW,se);
            %         visboundaries(ax1,bwNEW_dilated,'Color','y');
            
            
            switch activecontours
                case 1
                    %in case of edge -ve dilates, pos shrinks
                    bw0 = activecontour(Out, bwNEW_dilated, maxIterations, 'edge','ContractionBias',shrinkFactor, 'SmoothFactor',2);
                    %         bw0 = activecontour(Out, bwNEW, maxIterations,  'Chan-Vese', 'SmoothFactor',1);
                    %         bw0_open=imopen(bw0,se);
                otherwise
                                    
                    bw0=bwNEW;
%                     visboundaries(ax1,bw0,'Color','r');
            end
            v.CurrentTime
            cap=( sum(bw0(:))/sum(BW2(:)) *100 );
        else
            %             ccentroid=circ_region.Centroid;
            cap=0;
            ax1=subplot(2,2,1); imshow(rgb2gray(CurrentFrame)); title(fname(1:end-13));
            ax2=subplot(2,2,2); imshow(rgb2gray(CurrentFrame)); 

            bw0=zeros(size(CurrentFrame,1),size(CurrentFrame,2));
        end
        %         [wat wer]=min(d);
        diff_1=bw0 & mask1;
        diff_2=bw0 & mask2;
        diff_3=bw0 & mask3;
        
        
        
        % plot time against area
        
        a=[a cap];
        tm=[tm v.CurrentTime*(v.framerate/fps)];
        
        ca1=( (sum(diff_1(:))/summask1) *100 );
        a1=[a1 ca1];
        ca2=( (sum(diff_2(:))/summask2) *100 );
        a2=[a2 ca2];
        ca3=( (sum(diff_3(:))/summask3) *100 );
        a3=[a3 ca3];
        
        switch plottype
            case 'total'
                p=subplot(2,2,[3,4]); plot(p,tm,a);
                visboundaries(ax1,bw0,'Color','black');
            case 'both'
                p=subplot(2,2,[3,4]); plot(p,tm,a, 'black');
                hold on,
                p=subplot(2,2,[3,4]); plot(p,tm,a1,'r');
                hold on,
                p=subplot(2,2,[3,4]); plot(p,tm,a2,'g');
                hold on,
                p=subplot(2,2,[3,4]); plot(p,tm,a3,'b');
                visboundaries(ax1,bw0,'Color','black');
                visboundaries(ax1,diff_1,'Color','r');
                visboundaries(ax1,diff_2,'Color','g');
                visboundaries(ax1,diff_3,'Color','b');
            otherwise
                p=subplot(2,2,[3,4]); plot(p,tm,a1,'r');
                hold on,
                p=subplot(2,2,[3,4]); plot(p,tm,a2,'g');
                hold on,
                p=subplot(2,2,[3,4]); plot(p,tm,a3,'b');
                visboundaries(ax1,diff_1,'Color','r');
                visboundaries(ax1,diff_2,'Color','g');
                visboundaries(ax1,diff_3,'Color','b');
        end
        
        
        
        xlim([0 v.Duration*(v.framerate/fps)])
        ylim([0 100])
        xlabel('Time [seconds]')
        ylabel('Geometric Orifice Area [%]')
        

        
        axf=gcf;
        drawnow();
        writeVideo(vw,getframe(axf));
                
    end
end
close(vw)
area=a';
timest=tm';
save ([pname, fname(1:end-13),'.mat'], 'area', 'timest', 'a1', 'a2', 'a3');
% save ([fname(1:end-13),'data.mat'], 'mask1', 'mask2', 'mask3', 'BW2');
xlswrite([pname,fname(1:end-13),'.xlsx'], [timest area a1' a2' a3']);
