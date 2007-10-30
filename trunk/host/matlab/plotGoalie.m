% plot goalie logging

%% read data and plot data
m=csvread('corneroffsetmissing.csv',2,0);
systimens=m(:,1);
ballx=m(:,2);
bally=m(:,3);
armDesired=m(:,4);
armActual=m(:,5);
ballvelx=m(:,6);
ballvely=m(:,7);
ballxing=m(:,8);
timestamps=m(:,9);
eventrate=m(:,10);
ind=find(timestamps==0);
timestamps(ind)=NaN; % no events in these packets, no timestamp
t0=min(timestamps);
timestampsms=1e-3*(timestamps-t0);
systimems=systimens/1e6;
time=systimems;

figure(1);
% subplot(211);
plot182(time,armDesired, time, armActual, time, ballx,'x', time, bally, 's', time, ballxing,'o');
legend('arm desired', 'arm actual', 'ballx', 'bally', 'ball crossing pixel');
xlabel 'system time (ms)'
ylabel 'position (pixels)'
set(gca,'ylim',[-30,150]);

% subplot(212);
% plot(time,ballvelx,'x', time, ballvely,'o');
% legend('ballvelx', 'ballvely');
% xlabel 'system time (ms)'
% ylabel 'pixels/second'
% set(gca,'ylim',[-128/.01, 128/.01]);


%%
figure(2);
difftimes=diff(systimems); % delta t's on host, ms according to System.nanoTime
hist(difftimes,300);
xlabel 'update interval on host (ms)'
ylabel 'frequency'figure(3);
shorttimes=difftimes(find(difftimes<8));
mn=mean(shorttimes)
md=median(shorttimes)

% figure(3);
% plot(systimems,timestampsms);
% grid on
% xlabel 'system time (ms)'
% ylabel 'timestamp time (ms)'
