% plot goalie logging

%% read data and plot data
m=csvread('goalie.csv',2,0);
systimens=m(:,1);
ballx=m(:,2);
bally=m(:,3);
armDesired=m(:,4);
armActual=m(:,5);
ballvelx=m(:,6);
ballvely=m(:,7);
ballxing=m(:,8);
timestamps=m(:,9);
ind=find(timestamps==0);
timestamps(ind)=NaN; % no events in these packets, no timestamp
t0=min(timestamps);
timestampsms=1e-3*(timestamps-t0);
systimems=systimens/1e6;
time=systimems;

figure(1);
plot182(time,armDesired, time, armActual, time, ballx,'x', time, bally, 's', time, ballxing,'o');
legend('arm desired', 'arm actual', 'ballx', 'bally', 'ball crossing pixel');
xlabel 'system time (ms)'
ylabel 'position (pixels)'
set(gca,'ylim',[-30,150]);

%%
figure(2);
difftimes=diff(systimems); % delta t's on host, ms according to System.nanoTime
hist(difftimes,100);
% plot(systimems,timestampsms);
xlabel 'update interval on host (ms)'
ylabel 'frequency'