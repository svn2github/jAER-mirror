count = zeros(128,128);
[total numEle] = size(spikes);

for i=1:500
     x = floor(spikes(i,1)/256)+1;
     y = floor(mod(spikes(i,1),256))+1; 
     count(y,x) = count(y,x) + 1;
end
%subplot(1,2,2)
imagesc(count(:,128:-1:1)',[min(min(count)),max(max(count))])
colorbar


