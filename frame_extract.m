obj = VideoReader('rec/rec.mp4');
for f=1:obj.NumberOfFrames
  thisframe=read(obj,f);
  figure(1);imagesc(thisframe);
  thisfile=sprintf('frame_%04d.jpg',f);
  imwrite(thisframe,thisfile);
end