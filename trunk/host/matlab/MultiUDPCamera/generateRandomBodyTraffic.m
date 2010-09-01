function generateRandomBodyTraffic()
dsx = 1280;
dsy = 128;
xshift=1; % bits to shift x to left
yshift=12; % bits to shift y to right

filename = strcat('randomBodyTraffic_',datestr(now,'yyyy-mm-ddTHH-MM-SS'),'.aedat');

% body = [-1 0 1 2 2 2 2 2 2  2  2  2  2  1  0 -1 -2 -2 -2 -2 -2 -2 -2 -2 -2 -2 -1 0 1 -1  0  1
%         6  6 6 5 4 3 2 1 0 -1 -2 -3 -4 -5 -5 -5 -4 -3 -2 -1  0  1  2  3  4  5  2 3 2 -1 -2 -1];
body = generateBody();

seq_length = 30000; %sequence length in ms
ts_resolution = 80; %how often a point has the chance to create a spike [in ms]
nr_agents = 20;
agent_start_x = ((rand(nr_agents,1)-0.5)*2)*dsx;
agent_start_y = rand(nr_agents,1)*dsy;
max_speed = 0.02;
agent_speed = max_speed*rand(nr_agents,1);
agent_freq = 1+(rand(nr_agents,1)-0.5);
agent_amplitude = (rand(nr_agents,1)-0.5)*2;
ev_per_contour = 0.8;

spikes_count = 1;
base_ts = 1; %in us
max_elements = round(nr_agents*10*2*pi);
while base_ts < seq_length*1000 %us
    base_ts = round(base_ts+ts_resolution*1000);
    spike_array = zeros(max_elements, 2);
    for a=1:nr_agents
        %body
        for index=1:size(body,2)
           if rand<ev_per_contour*(agent_speed(a)/max_speed)
               ts = base_ts+rand*ts_resolution;
               center_x = agent_start_x(a)+ts*agent_speed(a)/(1000);
               center_y = agent_start_y(a)+agent_amplitude(a)*dsy/2*(1+sin(agent_freq(a)*2*pi*center_x/dsx));
               x = round(center_x+body(1,index));
               y = round(center_y+body(2,index));
               if (x>=0 && y>=0 && x<dsx && y<dsy)
                   if body(1,index)>=0 
                       pol=0;
                   else
                       pol=1;
                   end
                   spike_array(spikes_count,2)=bitor(bitor(bitshift(x,xshift),bitshift(y,yshift)),pol);
                   spike_array(spikes_count,1)= ts;
                   spikes_count = spikes_count+1;
               end
           end
        end
    end
    [ col, row, values1] = find(spike_array(:,1));
    values2 = spike_array(col,2);
    output_length = size(values1,1);
    output_array = zeros(output_length,2);
    output_array(:, 1) = values1;
    output_array(:, 2) = values2;
    output_array = sortrows(output_array);
    saveMultiAerdat(output_array ,filename);
    spikes_count = 1;
end