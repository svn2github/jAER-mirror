function plotParticleTrackerLog(logName,frameN,time_shift,xshift,yshift,xscaling,yscaling,xlim,ylim)
% Hydrolab: xshift=-62*366e-6; yshift=67*366e-6; xscaling=-366e-6;
% yscaling=366e-6; xlim=[-70 70]*366e-6; ylim=xlim;

for i=frameN
  [particles]=feval(logName,i+time_shift);
  i
  if (~isempty(particles))
    x=xscaling*particles(:,2)-xshift;
    y=yscaling*particles(:,3)-yshift;
    u=xscaling*particles(:,4);
    v=yscaling*particles(:,5);
    plot(x,y,'o');
    hold on
    quiver(x,y,u*1e3,v*1e3,0);
    set(gca,'xlim',xlim,'ylim',ylim);
    hold off
  else
      cla;
  end; %if
  drawnow;
end; %for