allcount = zeros(128,128);
delaySec = 2;

for n=0:20
    
    fileNameTemp = num2str(n);
    fileName = ['inpSpike',fileNameTemp];
    eval(fileName);   

    count = zeros(128,128);
    [total numEle] = size(inpSpike);

    for i=1:numEle
         x = floor(inpSpike(i)/256)+1;
         y = floor(mod(inpSpike(i),256))+1; 
         count(y,x) = count(y,x) + 1;
    end
    allcount = allcount + count;
    
    subplot(2,2,1)
    imagesc(count(:,128:-1:1)',[min(min(count)),max(max(count))])
    colorbar    

    fileNameTemp = num2str(n);
    fileName = ['mem_pot',fileNameTemp];
    eval(fileName);
    
    s=max(max(memPot));    
    if s ~= 0 
        subplot(2,2,2)
        %imagesc(memPot(:,128:-1:1)',[min(min(memPot)),max(max(memPot))]);
        imagesc(memPot(128:-1:1,:),[min(min(memPot)),max(max(memPot))]);
        colorbar;    
    else
        fprintf(1,'MemPot%d\n',n);
    end

    subplot(2,2,3)
    %imagesc(allcount(:,128:-1:1)',[min(min(allcount)),max(max(allcount))])
    colorbar;    
    
    %keyboard;
    memPot=(memPot-60.0);
    index=(memPot > 0);
    allcount = zeros(128,128);
    allcount(index)=1;
    subplot(2,2,4)
    %imagesc(memPot(:,128:-1:1)',[min(min(memPot)),max(max(memPot))]);
    %imagesc(allcount(128:-1:1,:),[min(min(allcount)),max(max(allcount))]);
    colorbar;    
    
    pause(delaySec);
	%keyboard;
    %waitforkeypress;
end