for i=0:20
    fileNameTemp = num2str(i);
    fileName = ['mem_pot',fileNameTemp];
    eval(fileName);
    s=max(max(memPot));
    if s ~= 0
        imagesc(memPot(:,128:-1:1)',[min(min(memPot)),max(max(memPot))]);
        colorbar;    
        pause(5);
    else
        fprintf(1,'MemPot%d\n',i);
    end
end
