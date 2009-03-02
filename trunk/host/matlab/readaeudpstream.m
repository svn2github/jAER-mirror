% receive events continuosly from jaer AEViewer which sends them
% using AEUnicastOutput on default port 8991 on localhost
port=8991;
try
    fprintf('opening datagram input to localhost:%d\n',port);
    u=udp('localhost','localport',port,'timeout',1);
    fopen(u);
    while 1,
        b=fread(u);
        fprintf('%d bytes\n',length(b));
    end
catch ME
    ME
    fclose(u);
    delete(u);
    clear u
end
