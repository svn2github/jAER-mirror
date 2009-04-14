filtered_packet_1();
maxtime=max(filt_packet(:,2));
mintime=min(filt_packet(:,2));

for bindelta=100:100:500
    numbin=int32((maxtime-mintime)/bindelta);
    numbin=numbin+2;
    bincnt=zeros(1,numbin);
    bintime=zeros(1,numbin);
    [totEle tmp]=size(filt_packet);
    prevtime=bincnt(1);
    binpos=1;
    bincnt(binpos)=1;
    bintime(binpos)=prevtime;
    for i=2:totEle    
       curtime=filt_packet(i,2);
       if (curtime-prevtime < bindelta) 
           bincnt(binpos)=bincnt(binpos)+1;
       else
           binpos=binpos+1;
           bintime(binpos)=curtime;
           bincnt(binpos)=1;
           prevtime=curtime;
       end
    end
    %figure
    %bar(bincnt);
    fprintf(1, 'dela=%d, mean=%f, max=%f, min=%f\n', bindelta, mean(bincnt(1:binpos)), max(bincnt(1:binpos)), min(bincnt(1:binpos)));
end    
