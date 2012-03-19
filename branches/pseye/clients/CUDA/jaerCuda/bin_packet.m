maxtime=max(filt_packet(:,2));
mintime=min(filt_packet(:,2));

for bindelta=100:50:500
    numbin=int32((maxtime-mintime)/bindelta);
    numbin=numbin+2;
    bincnt=zeros(1,numbin);
    [totEle tmp]=size(filt_packet);
    for i=1:totEle    
       tmp =int32((filt_packet(i,2)-mintime)/bindelta) + 1;
       bincnt(tmp)=bincnt(tmp)+1;
    end
    figure
    bar(bincnt);
end    
