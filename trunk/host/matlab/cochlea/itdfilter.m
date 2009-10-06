function [ bins ] = itdfilter(varargin)
%ITDFILTER Computes ITDbins from an AER file for every channel seperately.
%   bins=ITDFILTER() will open a file dialog to choose the .dat file and will
%   then compute the bins and display them in a surface plot. For the plot
%   the histograms of all channels are sumed up.
%
%   bins=ITDFILTER('PropertyName',VALUE,'PropertyName',VALUE,...)
%   creates the movie with the specified property values.
%
%   ITDFILTER Properties:
%
%   DATFILENAME - The filename of the .dat file
%
%   DT - The timeresolution in seconds to plot the bins
%
%   AVERAGINGDECAY - The timeconstant with which the histogram decays over
%   time
%
%   MAXITD - Only ITDs below this limit will be computed (in us)
%
%   NUMOFBINS - The number of bins in the ITD histogram
%
%   MAXWEIGHT - The maximum weight for a single ITD
%
%   DIMLASTTS - The maximum number of spikes with which the correlation is
%   computed.
%
%   MAXWEIGHTTIME - The maximum ISI in us over which the weight for an ITD decays
%   linearly. 
%
%   NUMOFCHANNELS - The number of cochlea channels (default: 64)
%
%   Author: Holger Finger
%

%% default values:
dt=0.1;
averagingDecay=1;
maxITD=1000;
numOfBins=32;
maxWeight=5;
dimLastTs=4;
maxWeightTime=4000;
numOfChannels=64;

%% parse properties:
datFileName=[];
if nargin > 0
    for arg = 1:2:(nargin - 1)
        switch lower(varargin{arg})
            case 'datfilename'
                datFileName = varargin{arg + 1};
            case 'dt'
                dt=varargin{arg + 1};
            case 'averagingdecay'
                averagingDecay=varargin{arg + 1};
            case 'maxitd'
                maxITD=varargin{arg + 1};
            case 'numofbins'
                numOfBins=varargin{arg + 1};
            case 'maxweight'
                maxWeight=varargin{arg + 1};
            case 'dimlastts'
                dimLastTs=varargin{arg + 1};
            case 'maxweighttime'
                maxWeightTime=varargin{arg + 1};
            case 'numofchannels'
                numOfChannels=varargin{arg + 1};
            otherwise
                error('Invalid property. Type ''help itdfilter''for information about available properties.');
        end
    end
end

%% load the AER data and extract the events:
if isempty(datFileName)
    [allAddr,allTs]=loadaerdat;
else
    [allAddr,allTs]=loadaerdat(datFileName);
end
[chan, neuron, filterType, side] = extractAMS1bEventsFromAddr( allAddr );

%% initialize some variables:
newTs=allTs(1):dt*1e6:allTs(end);
bins=zeros(length(newTs),numOfBins,numOfChannels);
totaltimesteps=length(newTs);
lastTs=zeros(numOfChannels,4,2,dimLastTs);
lastTsCursor=ones(numOfChannels,4,2);
indexTs = 1;
currentT = allTs(1);
decayconstant = exp(- dt / averagingDecay);

%% Main time loop updates the bins every dt seconds:
for i=1:totaltimesteps
    
    %% Update the bins with exponential decay:
    for j = 1:size(bins,2)
        for k = 1:size(bins,3)
            bins(i+1,j,k) = bins(i,j,k) * decayconstant;
        end
    end
    
    %% iterate over all spikes which occured in the last interval dt
    while currentT <= newTs(i)
        otherside=3-side(indexTs);
        
        %% compute the ITD to all spikes from all 4 neurons of other side
        for compare2neuron=1:4
            cursor=lastTsCursor(chan(indexTs),compare2neuron,otherside);
            
            %% this is a do...while loop in which the ITDs are computed:
            dowhile = true;
            while (cursor~=lastTsCursor(chan(indexTs),compare2neuron,otherside)) || dowhile
                dowhile = false;
                
                %% compute the time difference
                diff=int32(allTs(indexTs)-lastTs(chan(indexTs),compare2neuron,otherside,cursor));
                
                %% if reaching an ITD which is too big then interrupt
                if abs(diff) > maxITD
                    break;
                end
                %% make ITD negative depending on side:
                if (side(indexTs) == 1)
                    diff = -diff;
                end
                
                %% Compute the weight for this ITD:
                lastWeight = 1;
                weightTimeThisSide = currentT - lastTs(chan(indexTs),neuron(indexTs),side(indexTs),lastTsCursor(chan(indexTs),neuron(indexTs),side(indexTs)));
                if (weightTimeThisSide > maxWeightTime)
                    weightTimeThisSide = maxWeightTime;
                end
                lastWeight = lastWeight * (((weightTimeThisSide * (maxWeight - 1)) / maxWeightTime) + 1);
                weightTimeOtherSide = lastTs(chan(indexTs),compare2neuron,otherside,cursor) - lastTs(chan(indexTs),compare2neuron,otherside,1+mod(cursor,dimLastTs));
                if (weightTimeOtherSide > maxWeightTime)
                    weightTimeOtherSide = maxWeightTime;
                end
                lastWeight = lastWeight * (((weightTimeOtherSide * (maxWeight - 1)) / maxWeightTime) + 1);
                if (weightTimeOtherSide < 0 || weightTimeThisSide < 0)
                    lastWeight = 0;
                end
                
                %% compute index of the corresponding bin:
                indexBin=1+round(((diff + maxITD) * (numOfBins-1)) / (2 * maxITD));
                
                %% Add the ITD to the histogram with the weight:
                bins(i+1,indexBin,chan(indexTs))=bins(i+1,indexBin,chan(indexTs))+lastWeight*exp( double(currentT - newTs(i)) / (1e6*averagingDecay) );
                
                cursor = 1+mod(cursor,dimLastTs);
            end
        end
        
        %% Now decrement the cursor (circularly)
        if (lastTsCursor(chan(indexTs),neuron(indexTs),side(indexTs)) == 1)
            lastTsCursor(chan(indexTs),neuron(indexTs),side(indexTs)) = dimLastTs+1;
        end
        lastTsCursor(chan(indexTs),neuron(indexTs),side(indexTs))=lastTsCursor(chan(indexTs),neuron(indexTs),side(indexTs))-1;
        
        %% Add the new timestamp to the list:
        lastTs(chan(indexTs),neuron(indexTs),side(indexTs),lastTsCursor(chan(indexTs),neuron(indexTs),side(indexTs))) = currentT;
        
        %% go to the next spike:
        indexTs = indexTs+1;
        currentT = allTs(indexTs);
        
    end
end
bins=bins(2:end,:,:);

%% plot the result:
binsum=sum(bins,3);
surf(linspace(-maxITD,maxITD,numOfBins),newTs,binsum);
xlabel('ITD [us]')
ylabel('time [us]')


end