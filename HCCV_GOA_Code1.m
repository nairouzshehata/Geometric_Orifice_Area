close all
clear all
% Select Video and Read it
[fname,pname]=uigetfile('*.mp4','Video');
filename=[pname,fname];

v=VideoReader(filename);

% Write cropped video in grayscale
writerObj1 = VideoWriter([filename,'-crop2.avi']); 
writerObj1.FrameRate=v.FrameRate;
open(writerObj1);
cropflag=1;
while hasFrame(v)
    im=readFrame(v);
    img=rgb2gray(im);
    if cropflag==1
        [imgc, rect] = imcrop(im);
        pause
        cropflag=0;
    else
        imgc = imcrop(im,rect);
    end
    writeVideo(writerObj1,imgc);
end
close(writerObj1)
