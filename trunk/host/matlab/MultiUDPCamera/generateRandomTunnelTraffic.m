function generateRandomTunnelTraffic()
dsx = 1280;
dsy = 128;
xshift=1; % bits to shift x to left
yshift=12; % bits to shift y to right

seq_length = 5000; %sequence length in ms
ts_resolution = 5;
blur = 3;
nr_agents = 6;
agent_start_x = (rand(nr_agents,1)-0.5)*2*dsx/3;
agent_start_y = (rand(nr_agents,1)-0.5)*2*dsy/3;
agent_speed = 1+(rand(nr_agents,1)-0.5);
agent_freq = 1+(rand(nr_agents,1)-0.5);
agent_amplitude = (rand(nr_agents,1)-0.5)*2;
length = 15;
ev_per_contour = 0.8;

spikes_count = 1;
ts = 1;
while ts < seq_length*1000
    ts = round(ts+ts_resolution*rand*2*1000);
    for a=1:nr_agents
        center_x = agent_start_x(a)+ts*agent_speed(a)*dsx/(seq_length*1000);
        center_y = agent_start_y(a)+agent_amplitude(a)*dsy/2*(1+sin(agent_freq(a)*2*pi*center_x/dsx));
        %circle for head
        for alpha=0:10*2*pi
           if rand<ev_per_contour*abs(sin(alpha/10))
               x = round(center_x+length*sin(alpha/10)+rand*blur);
               y = round(center_y+length*cos(alpha/10)+rand*blur);
               if (x>=0 && y>=0 && x<dsx && y<dsy)
                   if sin(alpha/10)>0 
                       pol=0;
                   else
                       pol=1;
                   end
                   spike_array(spikes_count,2)=bitor(bitor(bitshift(x,xshift),bitshift(y,yshift)),pol);
                   spike_array(spikes_count,1)=ts;
                   spikes_count = spikes_count+1;
               end
           end
        end
    end
    saveMultiAerdat(spike_array ,'randomTraffic');
end