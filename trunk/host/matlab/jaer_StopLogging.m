function jaer_StopLogging

port=8997; % printed on jaer startup for AEViewer remote control
u=udp('localhost',port,'inputbuffersize',8000);
fopen(u);
fprintf(u,'stoplogging');
fprintf('%s',fscanf(u));
fclose(u);
delete(u);
clear u
