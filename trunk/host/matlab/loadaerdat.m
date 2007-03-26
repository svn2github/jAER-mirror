function [allAddr,allTs]=loadaerdat(file);
%function [allAddr,allTs]=loadaerdat(file);
% loads events from a .dat file.
% allAddr are int16 raw addresses.
% allTs are int32 timestamps (1 us tick).
% noarg invocations open file browser dialog (in the case of no input argument) directly create vars allAddr, allTs in
% base workspace (in the case of no output argument).
%
% Header lines starting with '#' are ignored and printed
%
% Note: it is possible that the header parser can be fooled if the first
% data byte is the comment character '#'; in this case the header must be
% manually removed before parsing. Each header line starts with '#' and
% ends with the hex characters 0x0D 0x0A (CRLF, windows line ending).

maxEvents=30e6;

if nargin==0,
    [filename,path,filterindex]=uigetfile('*.dat','Select recorded retina data file');
    if filename==0, return; end
end
if nargin==1,
    path='';
    filename=file;
end


f=fopen([path,filename],'r');
% skip header lines
bof=ftell(f);
line=native2unicode(fgets(f));
while line(1)=='#',
    fprintf('%s\n',line(1:end-2)); % print line using \n for newline, discarding CRLF written by java under windows
    bof=ftell(f);
    line=native2unicode(fgets(f)); % gets the line including line ending chars
end

fseek(f,0,'eof');
numEvents=floor((ftell(f)-bof)/6); % 6 bytes/event
if numEvents>maxEvents, 
    fprintf('clipping to %d events although there are %d events in file\n',maxEvents,numEvents);
    numEvents=maxEvents;
end

% read data
fseek(f,bof,'bof'); % start just after header
allAddr=uint16(fread(f,numEvents,'uint16',4,'b')); % addr are each 2 bytes (uint16) separated by 4 byte timestamps
fseek(f,bof+2,'bof'); % timestamps start 2 after bof
allTs=uint32(fread(f,numEvents,'uint32',2,'b')); % ts are 4 bytes (uint32) skipping 2 bytes after each
fclose(f);

if nargout==0,
   assignin('base','allAddr',allAddr);
   assignin('base','allTs',allTs);
   fprintf('%d events assigned in base workspace as allAddr,allTs\n', length(allAddr));
   dt=allTs(end)-allTs(1);
   fprintf('min addr=%d, max addr=%d, Ts0=%d, deltaT=%d=%.2f s assuming 1 us timestamps\n',...
       min(allAddr), max(allAddr), allTs(1), dt,double(dt)/1e6);
end
