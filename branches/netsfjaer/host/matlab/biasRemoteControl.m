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

%% sweep one bias and record currents
k6430_sourcevolt(1); % vdrain
u=udp('localhost',8995);
fopen(u);
vals=0:5:1000;
cur=NaN*zeros(1,length(vals));
for i=1:length(vals),
    v=vals(i);
    c=sprintf('setvdacspout1 %d\n',v);
    fprintf(c,v);
    fprintf(u,c);
    fprintf('%s',fscanf(u));
    pause(.3);
    thiscur=k6430_take;
    cur(i)=thiscur;
    semilogy(vals, cur);
    drawnow;
end
fclose(u);
delete(u);
clear u

%% sweep one pfet bias and record currents
k6430_sourcevolt(2.3); % vdrain = 1v for pfet
u=udp('localhost',8995);
fopen(u);
vdd=floor(3.3/5*4095);
vals=vdd:-5:vdd-1000;
cur=NaN*zeros(1,length(vals));
for i=1:length(vals),
    v=vals(i);
    c=sprintf('setvdacspout1 %d\n',v);
    fprintf(c,v);
    fprintf(u,c);
    fprintf('%s',fscanf(u));
    pause(.3);
    thiscur=-k6430_take;
    cur(i)=thiscur;
    semilogy(vals, cur);
    drawnow;
end
fclose(u);
delete(u);
clear u


%% sweep fet bias using onchip biasgen
k6430_sourcevolt(1.5); 
u=udp('localhost',8995);
fopen(u);
vals=(2.^(1:.1:24))-1;
cur=NaN*zeros(1,length(vals));
bitvals=NaN*zeros(1,length(vals)); % need to read actual bit values
for i=1:length(vals),
    v=round(vals(i));
    c=sprintf('setivbampp %d\n',v);
    fprintf(c,v);
    fprintf(u,c);
    line=fscanf(u);
    fprintf('%s',line);
    bitval=sscanf(line,'IPot VbampP with bitValue=%d');
    bitvals(i)=bitval;
    pause(.3);
    thiscur=-k6430_take;
    cur(i)=thiscur;
    loglog(bitvals, cur);
    drawnow;
end
fclose(u);
delete(u);
clear u