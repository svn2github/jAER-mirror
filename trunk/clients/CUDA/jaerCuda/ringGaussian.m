%********************************************
%circle template
tempSize=60;
objectRadius=15;
dogimg = zeros(tempSize,tempSize);
center=int16(tempSize/2);
res=MidpointCircle(dogimg,objectRadius,center,center,1);
n=-30:30;
%********************************************

%********************************************
%gaussian template for ring
maxAmp0=2.5;
minAmp0=-0.625;
sigma0=2.0;
amp0 = (maxAmp0-minAmp0);
[X,Y]=meshgrid(n,n);
gXY0= amp0*exp(-((X.^2)+(Y.^2))/(2*(sigma1^2)));
gXY0=gXY0+minAmp0;
%********************************************

%********************************************
% DOG template generation
sigma1=2.0;
amp1 = 3.2;
[X,Y]=meshgrid(n,n);
gXY1= amp1*exp(-((X.^2)+(Y.^2))/(2*(sigma1^2)));        

sigma2=12.0;
amp2 = 0.7;
gXY2=amp2*exp(-((X.^2)+(Y.^2))/(2*(sigma2^2)));

dgXY = (gXY1-gXY2);                %difference of gaussian
%********************************************

%********************************************
% final template for the ball 

dgimg = zeros(tempSize,tempSize);   % DOG based Ring Template
gimg  = zeros(tempSize,tempSize);   % Basic Gaussian Ring Template

resArr=find(res == 1);
[len,tmp]=size(resArr);
minDist = zeros(tempSize,tempSize);
for i=1:tempSize
    for j=1:tempSize
        minVal=100000000;
        for k=1:len
            [x1,y1]=ind2sub(size(res),resArr(k));
            dis=sqrt(((x1-i)^2)+((y1-j)^2));
            if(dis<=minVal)
               minVal = dis;
               m=x1;
               n=y1;
            end
        end
        dgimg(i,j)=dgXY(31+i-m,31+j-n);
        gimg(i,j) =gXY0(31+i-m,31+j-n);
        minDist(i,j) = minVal;
    end
end
%********************************************


%********************************************
surf(gimg);
figure; surf(dgimg);
%********************************************




