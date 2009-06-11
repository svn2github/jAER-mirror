function [ freqResponse ] = freqResponseAMS1b( calibrationname, frequencies, volumes, signallength, doRecord, doEvaluate, doPlot )
%COMPUTEFREQRESPAMS1B Summary of this function goes here

%Call the function without arguments to plot a previously stored freqResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Otherwise:
%calibrationname is a string used for the foldername to store the files
%frequencies is a vector containing the frequencies to test (in Hz)
%volumes is a vector containing the volume levels to play
%signallength is the playtime of every frequency (in seconds)
%doRecord=0 -> don't record
%doEvaluate=0 -> don't evaluate the frequencies
%doPlot=0 -> don't plot


if nargin==0,
    [filename,path]=uigetfile('*.mat','Select file');
    if filename==0, return; end
    load([path,filename]);
    doRecord=0;
    doEvaluate=0;
    doPlot=1;
end

numOfCochleaChannels=64;

if doRecord
    mkdir(['Recording/' calibrationname])
    Fs=16000;
    
    %Open connection to jAER:
    u=udp('localhost',8997);
    fopen(u);
    
    for indFrequency=1:length(frequencies)
        for indVolume=1:length(volumes)
            signal=sin((1:signallength*Fs)*2*pi*frequencies(indFrequency)/(signallength*Fs));
			fprintf(u,['startlogging ' pwd '\Recording\' calibrationname '\Freq' num2str(indFrequency) 'Vol ' num2str(indVolume) '.dat']);
			fprintf('%s',fscanf(u));
            pause(0.5);
            fprintf('playing now sine wave with %d Hz and %d volume, %d measurments left \n', frequencies(indFrequency), volumes(indVolume), (length(frequencies)-indFrequency)*length(volumes)-indVolume);
            sound(signal*volumes(indVolume),Fs);
            pause(signallength+1);
            fprintf(u,'stoplogging');
			fprintf('%s',fscanf(u));
			pause(0.5);
        end
    end
    % clean up the UDP connection to jAER:
    fclose(u);
    delete(u);
    clear u
    save(['Recording\' calibrationname '\settings']);
end

if doEvaluate
    freqResponse=cell(4,2,2,length(volumes)); % Neuron, FilterType, Side
    for neuron=1:4
        for side=1:2
            for indVolume=1:length(volumes)
                freqResponse{neuron,side,indVolume}=zeros(length(frequencies),numOfCochleaChannels);
            end
        end
    end
    for indFrequency=1:length(frequencies)
        for indVolume=1:length(volumes)
            [trialAddr]=loadaerdat([pwd '\Recording\' calibrationname '\Freq' num2str(indFrequency) 'Vol ' num2str(indVolume) '.dat']);
            [trialChan, trialNeuron, trialFilterType, trialSide]=extractAMS1bEventsFromAddr(trialAddr);
            fprintf('evaluating now %d Hz and %d volume, %d left \n', frequencies(indFrequency), volumes(indVolume), (length(frequencies)-indFrequency)*length(volumes)-indVolume);
            for chan=1:numOfCochleaChannels
                for neuron=1:4
                    for side=1:2
                        freqResponse{neuron,side,indVolume}(indFrequency,chan)=length(find(trialChan==chan & trialNeuron==neuron & trialSide==side))/signallength;
                    end
                end
            end
        end
    end
    save(['Recording\' calibrationname '\freqResponse']);
end

if doPlot
    for indVolume=1:length(volumes)
        for side=1:2
            figure()
            for neuron=1:4
                subplot(2,2,neuron)
                surf(1:numOfCochleaChannels,frequencies,freqResponse{neuron,side,indVolume})
                set(gca, 'YScale', 'log')
                ylabel('frequency');
                xlabel('channel');
                zlabel('spikes/sec');
                title(['neuron=' num2str(neuron) ' volume=' num2str(volumes(indVolume))]);
            end
        end
    end
end

end