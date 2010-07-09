function saveMultiAerdat(spikes,filename)
% function saveaerdat(spikes[,filename])
% write events to a .dat file (tobi's aer data format).
% run this script, which opens a file browser. browse to the .dat file and click "Open".
%
% argument spikes is the data, an Nx2 array.
% spikes(:,1) are the timestamps with 1us tick, spikes(:,2) are the
% addresses.
% these address are raw; to generate addressses corresponding to a
% particular x,y location and event type, you need to know the bit mapping.
%
% filename is an optional filename which overrides the dialog box

if nargin==1,
    [filename,path,filterindex]=uiputfile('*.aedat','Save data file');
elseif nargin==2,
    path='';
end

ts=spikes(:,1);
addr=spikes(:,2);

f=fopen([path,filename],'w','b'); % open the file for writing with big endian format

% data format:
%
% int32 addr
% int32 timestamp
% int32 address
% int32 timestamp
% ....

% the skip argument to fwrite is how much to skip *before* each value is written

% timestamps
fseek(f,0,'bof'); % seek to start of file, because we will skip before first timestamp
fwrite(f,[35 33 65 69 82 45 68 65 84 50 46 48 13 10 35 32 84 104 105 115 32 105 115 32 97 32 114 97 119 32 65 69 32 100 97 116 97 32 102 105 108 101 32 45 32 100 111 32 110 111 116 32 101 100 105 116 13 10 35 32 68 97 116 97 32 102 111 114 109 97 116 32 105 115 32 105 110 116 51 50 32 97 100 100 114 101 115 115 44 32 105 110 116 51 50 32 116 105 109 101 115 116 97 109 112 32 40 56 32 98 121 116 101 115 32 116 111 116 97 108 41 44 32 114 101 112 101 97 116 101 100 32 102 111 114 32 101 97 99 104 32 101 118 101 110 116 13 10 35 32 84 105 109 101 115 116 97 109 112 115 32 116 105 99 107 32 105 115 32 49 32 117 115 13 10 35 32 99 114 101 97 116 101 100 32 77 111 110 32 74 117 108 32 48 53 32 49 53 58 50 57 58 52 54 32 67 69 83 84 32 50 48 49 48 13 10],'int8');
pos = ftell(f);
count=fwrite(f,uint32(ts),'uint32',4); % write 4 byte timestamps, skipping 4 bytes before each

% addressses
fseek(f,pos,'bof'); % seek to start of data which is where addresses start
count=fwrite(f,uint32(addr(1)),'uint32'); % write first address
fseek(f,pos+4,'bof'); % seek to place so that skip of 4 will bring us to 2nd address
count=fwrite(f,uint32(addr(2:end)),'uint32',4); % write 4 byte addresses, skipping 4 bytes after each
fclose(f);
