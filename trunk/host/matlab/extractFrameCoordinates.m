function [x,y]=extractFrameCoordinates(AE,xMask,yMask)

x=zeros(size(AE));
y=zeros(size(AE));
AE=double(AE);
for i=16:-1:1
    if (bitget(xMask,i)==1)
        x=bitshift(x,1);
        x=bitor(bitget(AE,16),x);
    end; %if
    if (bitget(yMask,i)==1)
        y=bitshift(y,1);
        y=bitor(bitget(AE,16),y);
    end; %if
    AE=bitshift(AE,1);
end; %for i
