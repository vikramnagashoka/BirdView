source = VideoReader('2017_05_17.mp4');
fr = imread('background.jpg');
bground = imread('background.jpg');

fr_bw = rgb2gray(fr);     
fr_size = size(fr);             
width = fr_size(2);
height = fr_size(1);
fg = zeros(height, width);
bg_bw = zeros(height, width);



C = 3;                                  
M = 3;                                  
D = 2.5;                                
alpha = 0.01;                           
thresh = 0.25;                          
sd_init = 6;                            
w = zeros(height,width,C);              
mean = zeros(height,width,C);           
sd = zeros(height,width,C);             
u_diff = zeros(height,width,C);         
p = alpha/(1/C);                        
rank = zeros(1,C);                      




pixel_depth = 8;                        
pixel_range = 2^pixel_depth -1;

i = 1:height;
j = 1:width;
k = 1:C; 
R = rand(height,width,C);
mean = R*pixel_range;
sd = ones(height,width,C)*sd_init;
w = ones(height,width,C)*(1/C);


for n = 477:source.NumberOfFrames
    
    thisfile=sprintf('frame_%04d.jpg',n);
    fr = imread(thisfile);       
    fr = imresize(fr,[996 3996]);
    fr_bw = rgb2gray(fr);       
    
    m = 1:C;
    u_diff(:,:,m) = abs(double(fr_bw) - double(mean(:,:,m)));
    %%%%%
    cond = abs(u_diff <= D*sd);
    
    i=1:height;
    j=1:width;
    k = 1:C;
                                  
    for i=1:height
        for j=1:width
            
             match = 0;
             for k=1:C                       
                 if (abs(u_diff(i,j,k)) <= D*sd(i,j,k))       
                     
                     match = 1;                          
                     
                     w(i,j,k) = (1-alpha)*w(i,j,k) + alpha;
                     p = alpha/w(i,j,k);                  
                     mean(i,j,k) = (1-p)*mean(i,j,k) + p*double(fr_bw(i,j));
                     sd(i,j,k) =   sqrt((1-p)*(sd(i,j,k)^2) + p*((double(fr_bw(i,j)) - mean(i,j,k)))^2);
                 else                                    
                     w(i,j,k) = (1-alpha)*w(i,j,k);      
                     
                 end
             end
             
             %end
            w(i,j,:) = w(i,j,:)./sum(w(i,j,:));        
            bg_bw(i,j)=0;
            for k=1:C
                bg_bw(i,j) = bg_bw(i,j)+ mean(i,j,k)*w(i,j,k);
            end
            
            if (match == 0)
                [min_w, min_w_index] = min(w(i,j,:));  
                mean(i,j,min_w_index) = double(fr_bw(i,j));
                sd(i,j,min_w_index) = sd_init;
            end

            rank = w(i,j,:)./sd(i,j,:);             
            rank_ind = [1:1:C];
            
            
            for k=2:C               
                for m=1:(k-1)
                    
                    if (rank(:,:,k) > rank(:,:,m))                     
                        
                        rank_temp = rank(:,:,m);  
                        rank(:,:,m) = rank(:,:,k);
                        rank(:,:,k) = rank_temp;
                        
                        
                        rank_ind_temp = rank_ind(m);  
                        rank_ind(m) = rank_ind(k);
                        rank_ind(k) = rank_ind_temp;    

                    end
                end
            end
            
            
            match = 0;
            k=1;
            
            fg(i,j) = 0;
            while ((match == 0)&&(k<=M))

                if (w(i,j,rank_ind(k)) >= thresh)
                    if (abs(u_diff(i,j,rank_ind(k))) <= D*sd(i,j,rank_ind(k)))
                        fg(i,j) = 0;
                        cond(i,j) = 1;
                        match = 1;
                    else
                        fg(i,j) = fr_bw(i,j);     
                    end
                end
                k = k+1;
            end
        end
    end
    
    figure(1),subplot(3,1,1),imshow(fr)
    subplot(3,1,2),imshow(uint8(bg_bw))
    subplot(3,1,3),imshow(uint8(fg)) 
    
    
    outfile=sprintf('aresult_%04d.jpg',n);
    
    imwrite(uint8(fg),outfile);
    outfile1 = sprintf('abresult_%04d.jpg',n);
    imwrite(uint8(bg_bw),outfile1);
end