%% analyze timestamps from silabs monitor
load timestamps;
t=timestamps(:,2);
n=timestamps(:,1);

%%
plot(t,n);

%%
tms=t*1e-6;
hist(diff(tms));
