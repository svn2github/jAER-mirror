% plot goalie logging

%% read data and plot data
m=csvread('goalie.csv',2,0);
timens=m(:,1);
ballx=m(:,2);
bally=m(:,3);
armDesired=m(:,4);
armActual=m(:,5);
ballvelx=m(:,6);
ballvely=m(:,7);
ballxing=m(:,8);
timestamps=m(:,9);
timestampsms=1e-3*(timestamps-timestamps(1));

time=timestampsms;

timems=timens/1e6;
figure(1);
plot(time,armDesired, time, armActual, time, ballx,'x', time, bally, 's', time, ballxing,'o');
legend('arm desired', 'arm actual', 'ballx', 'bally', 'ball crossing pixel');
xlabel 'time (ms)'
ylabel 'position (pixels)'
set(gca,'ylim',[-30,150]);

figure(2);
plot(timems,timestampsms);
xlabel 'system time (ms)'
ylabel 'timestamp time(ms)'
grid on