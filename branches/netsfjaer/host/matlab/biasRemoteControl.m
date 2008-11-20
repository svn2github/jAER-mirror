%% control biases via udp remote control
u=udp('localhost',8995);
fopen(u);
vals=(2.^(1:24))-1;
for i=1:length(vals),
    v=vals(i);
    c=sprintf('setpr %d\n',v);
    fprintf(c,v);
    fprintf(u,c);
    fprintf('%s',fscanf(u));
    pause(.3);
end
fclose(u);
delete(u);
clear u
