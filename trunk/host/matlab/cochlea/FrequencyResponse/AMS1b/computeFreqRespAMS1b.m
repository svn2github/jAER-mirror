function [ freqResponse ] = computeFreqRespAMS1b( calibrationname, frequencies, signallength, record, evaluate )
%calibrationname is a string used for the foldername to store the files
%frequencies is a vector containing the frequencies to test (in Hz)
%signallength is the playtime of every frequency (in seconds)
%record=0 -> don't record
%evaluate=0 -> don't evaluate the frequencies

mkdir(['Recording/' calibrationname])
Fs=16000;
numOfCochleaChannels=64;

if record
    %Open connection to jAER:
    u=udp('localhost',8997);
    fopen(u);
    
    for trial=1:length(frequencies)
        signal=sin((1:signallength*Fs)*2*pi*frequencies(trial)/(signallength*Fs));
        commandJAER(u,['startlogging ' pwd '\Recording\' calibrationname '\ITD' num2str(frequencies(trial)) '.dat'])
        pause(0.5);
        fprintf('playing now sine wave with %d Hz, %d measurments left \n', frequencies(trial), length(frequencies)-trial);
        soundsc(signal,Fs);
        pause(signallength+1);
        commandJAER(u,'stoplogging')
        pause(0.5);
    end
    % clean up the UDP connection to jAER:
    fclose(u);
    delete(u);
    clear u
end

if evaluate
    freqResponse=cell(4,2,2); % Neuron, FilterType, Side
    for neuron=1:4
        for filtertype=1:2
            for side=1:2
                freqResponse{neuron,filtertype,side}=zeros(length(frequencies),numOfCochleaChannels);
            end
        end
    end
    
    for trial=1:length(frequencies)
        [trialAddr,trialTs]=loadaerdat([pwd '\Recording\' calibrationname '\ITD' num2str(frequencies(trial)) '.dat']);
        [trialChan, trialNeuron, trialFilterType, trialSide]=extractCochleaEventsFromAddrAMS1b(trialAddr);
        
        for chan=1:numOfCochleaChannels
            for neuron=1:4
                for filtertype=1:2
                    for side=1:2
                        freqResponse{neuron,filtertype,side}(trial,chan)=...
                            length(find(trialChan==chan & trialNeuron==neuron & trialFilterType==filtertype & trialSide==side));
                    end
                end
            end
        end
    end
    
    figure(1)
    for neuron=1:4
        for filtertype=1:2
            for side=1:2
                subplot(4,4,neuron+filtertype*4+side*8)
                surf(1:numOfCochleaChannels,frequencies,freqResponse{neuron,filtertype,side})
                set(gca, 'YScale', 'log')
                ylabel('Played Frequency');
                xlabel('Cochlea Channel');
                zlabel('Response');
                title(['Neuron=' neuron ' filtertype=' filtertype 'side=' side]);
            end
        end
    end
end

end