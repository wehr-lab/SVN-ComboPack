function out=DataGuru(varargin)

% simple module that watches the stimulus and extracts the response
%removing the poststimlength feature, which seemed to break dataguru
%%mw041707
global exper pref shared


if nargin > 0
    if isobject(varargin{1})    % callback function from exper.ai.daq
        action='showstimulus';
    else
        action = lower(varargin{1});
    end
else
    action = lower(get(gcbo,'tag'));
end

switch action
    case 'init'
        ModuleNeeds(me,{'stimulusczar'}); % receives signal from StimulusCzar that a stimulus was sent out
        triggerChannel=GetChannel('ai','triggerchannel');   % let's assume (safely) there's only one trigger channel
        AIChannel=AI('GetChannelIdx',triggerChannel.number);
        InitParam(me,'TriggerChannel','value',AIChannel);
        dataChannels=GetChannel('ai','datachannel');
        AIChannel=AI('GetChannelIdx',[dataChannels.number]);
        InitParam(me,'DataChannels','value',AIChannel);
        InitParam(me,'DataChannelNames','value',{dataChannels.name});
        InitParam(me,'DataChannelColors','value',{dataChannels.color});
        stimuliChannels=GetChannel('ai','stimulichannel');
        AIChannels=AI('GetChannelIdx',[stimuliChannels.number]);
        InitParam(me,'StimuliChannels','value',AIChannels);
        InitParam(me,'StimuliChannelNames','value',{stimuliChannels.name});
        InitParam(me,'StimuliChannelColors','value',{stimuliChannels.color});

        InitializeGUI;

    case 'getready'
        samplerate=AI('GetSampleRate');
        SetParam(me,'AISamplerate',samplerate);

    case 'showstimulus'
        exper.ai.daq.TimerFcn='';
        samplerate=round(GetParam(me,'AISampleRate')/1000);
        stimulus=varargin{3};
        SetSharedParam('CurrentStimulus',stimulus);
        stimlength=stimulus.stimlength; % in ms
        datalength=round((stimlength+1000)*samplerate);        % let's get 1000ms more, just in case
        %datalength=round((stimlength+0)*samplerate);        % mw 071610
        
        if exper.ai.daq.SamplesAvailable>datalength     % extract data
            %data=peekdata(exper.ai.daq,datalength); 
            %Message(me, 'peeked data')
            data=getdata(exper.ai.daq,datalength); %mw 072610
            Message(me, 'got data')
        else
            a=fix(clock);Message(me, sprintf('%d SamplesAvailable=%d', a(6), exper.ai.daq.SamplesAvailable)); %clock just to reveal multiple messages, mw 062606
            %        a=fix(clock);Message(me, sprintf('%d SamplesAvailable=%d', a(6), exper.ai.daq.SamplesAvailable), 'append'); %clock just to reveal multiple messages, mw 062606
            return;
        end
        dataLength=size(data,1);
        

        dataChannels=GetParam(me,'DataChannels');
        stimuliChannels=GetParam(me,'StimuliChannels');
        trig=data(:,GetParam(me,'TriggerChannel'))>2; % find the triggers
        trig=find(trig);
        if ~isempty(trig)
            %              triggerPos=trig(1);    % triggered by rising edge of TTL pulse
            %             triggerPos=trig(end);    % triggered by falling edge of TTL pulse
            %note: using trig(end) fails if peekdata managed to capture two triggers.
            % Assuming we want the end of the first one, find it with diff(trig)>1
            % mw 111706
            %another note:
            % sounds on hwtriggered soundmachine are triggered by rising edge of TTL pulse
            % NI AO is triggered by falling edge of TTL pulse
            % here we distinguish between them
            % mw 111706

            stimtype={stimulus.type};
            typeidx=strcmp(pref.stimulitypes(:,1),stimtype);
            typetrg=pref.stimulitypes(typeidx,3);
            typetrg=typetrg{:};
            switch typetrg
                case 'sound'
                    triggerPos=trig(1);    % triggered by rising edge of TTL pulse
                case 'ao'
                    %triggerPos=trig(find(diff(trig)>1));    % triggered by falling edge of first TTL pulse
                    triggerPos=trig(end);    % triggered by falling edge of first TTL pulse
                case 'visual'
                    triggerPos=trig(end);    % not hardware triggered, but falling edge is the better approximation
            end


            if (triggerPos+(stimlength)*samplerate)>dataLength
                data=data(triggerPos:end,:);
            else
                data=data(triggerPos:triggerPos+(stimlength)*samplerate,:);
            end
        else
            data=zeros(size(data));
        end
        dataLength=size(data,1);

        stimuli=data(:,stimuliChannels);                            % separate the stimuli channels
        stimuli=stimuli-repmat(min(stimuli),dataLength,1);          % and normalize them
        stimuli=stimuli./repmat(max(abs(stimuli))+eps,dataLength,1);

        data=data(:,dataChannels);                                  % and keep the data channels
        %     data=data-repmat(min(data),dataLength,1);                 % and normalize them
        %     data=data./repmat(max(abs(data))+eps,dataLength,1);

        if GetParam(me,'Watch')
            xData=1/samplerate:1/samplerate:dataLength/samplerate;
            stimulusLines=GetParam(me,'StimulusLines');
            dataLines=GetParam(me,'DataLines');
            for channel=1:length(stimuliChannels)
                set(stimulusLines(channel),'XData',xData,'YData',stimuli(:,channel)+channel-1);
            end
            for channel=1:length(dataChannels)
                set(dataLines(channel),'XData',xData,'YData',data(:,channel));
                %             set(dataLines(channel),'XData',xData,'YData',data(:,channel)+channel-1);
            end
            try
                set(GetParam(me,'StimulusAxes'),'XLim',[0 xData(end)]);
                set(GetParam(me,'DataAxes'),'XLim',[0 xData(end)]);
                drawnow;
            catch
            end
        end

        spikes=zeros(dataLength,size(data,2));
        if GetParam(me,'ExtractSpikes')
            spike_thresh=getparam(me, 'spikethresh');
            for channel=1:length(dataChannels)
                %            [spikes(:,channel), filtered]=ExtractSpikes(data(:,channel),spike_thresh,1);
                [spikes(:,channel), filtered]=ExtractSpikes(data(:,channel),spike_thresh,0);
            end
            if GetParam(me,'Watch')
                dataLineSX=GetParam(me,'dataLineSX'); %mw 062606
                set(dataLineSX,'XData',xData,'YData',filtered);
                threshLineSX=GetParam(me,'threshLineSX'); %mw 062606
                set(threshLineSX,'XData',xData,'YData',spike_thresh.*ones(size(xData)));
                spikeLineSX=GetParam(me,'SpikeLineSX'); %mw 062606
                set(spikeLineSX,'XData',xData,'YData',-spikes);
            end
        end
        data=[data spikes];

        try
            SetSharedParam('CurrentData',data);
        catch
            return;
        end
        SendEvent('edataavailable','CurrentData',me);


    case 'watch'
        if GetParam(me,'Watch');
            SetParamUI(me,'Watch','background',[0 0.9 0.9],'String','Watching...');
        else
            SetParamUI(me,'Watch','background',[0 0.9 0],'String','Watch');
        end

    case 'extractspikes'
        if GetParam(me,'ExtractSpikes');
            SetParamUI(me,'ExtractSpikes','background',[0 0.9 0.9],'String','Extracting...');
            if GetParam(me,'Watch')
                dataLineSX=getparam(me, 'dataLineSX');
                set(dataLineSX, 'visible', 'on');
                threshLineSX=getparam(me, 'threshLineSX');
                set(threshLineSX, 'visible', 'on');
                spikeLineSX=getparam(me, 'spikeLineSX');
                set(spikeLineSX, 'visible', 'on');
            end
        else
            SetParamUI(me,'ExtractSpikes','background',[0 0.9 0],'String','Extract spikes');
            dataLineSX=getparam(me, 'dataLineSX');
            set(dataLineSX, 'visible', 'off');
            threshLineSX=getparam(me, 'threshLineSX');
            set(threshLineSX, 'visible', 'off');
            spikeLineSX=getparam(me, 'spikeLineSX');
            set(spikeLineSX, 'visible', 'off');
        end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function InitializeGUI
fig = ModuleFigure(me);
set(fig,'doublebuffer','on');

dataChannelNames=GetParam(me,'DataChannelNames');
dataChannelColors=GetParam(me,'DataChannelColors');
nDataChannels=length(dataChannelNames);
stimuliChannelNames=GetParam(me,'StimuliChannelNames');
stimuliChannelColors=GetParam(me,'StimuliChannelColors');
nStimuliChannels=length(stimuliChannelNames);

dataLines=zeros(1,nDataChannels);
dataLineSX=0; %mw 062606
stimulusLines=zeros(1,nStimuliChannels);

stimulusAxes=axes('units','normal','position',[0.05 0.6 0.9 0.37]);
set(stimulusAxes,'YLimMode','manual','YLim',[0 nStimuliChannels],'XTickLabel',[]);
for pos=1:nStimuliChannels
    stimulusLines(pos)=line([0 1],[pos-0.5 pos-0.5],'Color',stimuliChannelColors{pos});
    text(pos-0.99,0.05,stimuliChannelNames{pos},'FontSize',8,'Units','normalized','Color',stimuliChannelColors{pos});
end
InitParam(me,'StimulusAxes','value',stimulusAxes);
InitParam(me,'StimulusLines','value',stimulusLines);

dataAxes=axes('units','normal','position',[0.05 0.2 0.9 0.37]);
set(dataAxes,'NextPlot','Add');
for pos=1:nDataChannels
    dataLines(pos)=line([0 1],[pos-0.5 pos-0.5],'Color',dataChannelColors{pos});
    text(pos-0.99,0.05,dataChannelNames{pos},'FontSize',8,'Units','normalized','Color',dataChannelColors{pos});
end
dataLineSX=line([0 1],[pos-0.5 pos-0.5],'Color','m');%mw 062606
threshLineSX=line([0 1],[pos-0.5 pos-0.5],'Color',[1 .5 1], 'linestyle', '--');%mw 062606
spikeLineSX=line([0 0],[pos-0.5 pos-0.5],'Color','r');%mw 062606
InitParam(me,'DataAxes','value',dataAxes);
InitParam(me,'DataLines','value',dataLines);
InitParam(me,'DataLineSX','value',dataLineSX);
InitParam(me,'DataLineSX','value',dataLineSX);
InitParam(me,'ThreshLineSX','value',threshLineSX);
InitParam(me,'SpikeLineSX','value',spikeLineSX);

samplerate=AI('GetSampleRate');
InitParam(me,'AISamplerate','value',samplerate);

SetSharedParam('CurrentData',0);    % CurrentData is a shared parameter


% Watch button.
InitParam(me,'Watch','value',0,'ui','togglebutton','pref',0,'units','normal','pos',[0.05 0.02 0.2 0.12]);
SetParamUI(me,'Watch','string','Watch','backgroundcolor',[0 0.9 0],'label','');
% ExtractSpikes button.
InitParam(me,'ExtractSpikes','value',0,'ui','togglebutton','pref',0,'units','normal','pos',[0.25 0.02 0.2 0.12]);
SetParamUI(me,'ExtractSpikes','string','Extract spikes','backgroundcolor',[0 0.9 0],'label','');
%spike threshold
InitParam(me,'SpikeThresh',	'value',.2,	'ui','edit','pos',[270 20 50 20]);


% message box
uicontrol(fig,'tag','message','style','edit',...
    'enable','inact','horiz','left','units','normal','pos',[0.7 0.01 0.39 0.1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out=me
% Simple function for getting the name of this m-file.
out=lower(mfilename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [spike_vector, filtswpvec]=ExtractSpikes(raw_sweep,threshold,remove_downward_spikes)
% This code takes a raw voltage sweep, hipass filters, thresholds for spikes,
% culls "fake" spikes due to downward "spikes" in raw trace, create spike
% vector which is 1 for the times of all spikes, and zero elsewhere.
%
% function spike_vector = E2ExtractSpikes(raw_sweep,threshold,remove_downward_spikes)
%
% inputs:
%  raw_sweep is the actual voltage data to find the spikes in
%  threshold is the voltage threshold for spike height as measured relative to voltage just prior to the spike
%  if remove_downward_spikes == 1, then do not include "spikes" which are predominantly downward going;
%     I usually set this to one to avoid misidentifying downward electrical noise spikes as action potentials
%
% output: spike_vector, same size as sweep, which is a vector of ones for spikes, and zeros eslewhere
%

if nargin<3
    remove_downward_spikes=1;
end

if nargin<2
    threshold=1;
end

window_half_width = 10; %half-width of window for excluding downward "spikes" in raw data from appearing in spike_vector
sweep_spike_heights = zeros(size(raw_sweep));
% High Pass filter the sweep:
%Tony provided a useful high-pass filter he made with the Filter analysis tool:
%equiripple, minimum order, Fs=4000; Fstop =20 ; Fpass=500; astop=60; apass=1;
Den = 1;
Num=[-2.9419,-7.7633,-16.2976,-28.7498,-44.7001,-62.8034,-80.9099,-96.4457,-106.9520,889.3317,...
    -106.9520,-96.4457,-80.9099,-62.8034,-44.7001,-28.7498,-16.2976,-7.7633,-2.9419]/1000;


if length(raw_sweep)>60
    filtswpvec=filtfilt(Num, Den, raw_sweep);
else
    spike_vector=zeros(size(raw_sweep));
    filtswpvec=zeros(size(raw_sweep));
    return;
end

%filtswpvec=filtswpvec./max(abs(filtswpvec)); %mw 060806
filtswpvec=abs(filtswpvec);

% try to estimate the threshold
% threshold=max([(max(filtswpvec)*0.66) 1]);

high_points = find(filtswpvec > threshold); % includes all points above filtspikethresh
sweep_spike_heights = zeros(size(raw_sweep));

% Now get single spike time for each spike even if several points are above threshold per spike
if ~isempty(high_points)
    high_point_count = length(high_points);
    if high_point_count == 1 %if only one spike which is only one point wide
        sweep_spike_heights(high_points) = filtswpvec(high_points);
    else %if more than one spike, or if more than one point width to one spike
        for k = 1:(high_point_count + 1)
            if k == 1 % for the first hight point
                current_max_point = high_points(1);
                current_max = filtswpvec(high_points(1));
            elseif k == high_point_count + 1  % no more high points to consider
                sweep_spike_heights(current_max_point) = current_max;
            elseif high_points(k) == (high_points(k-1)+1) %if still looking at the same bump
                if filtswpvec(high_points(k)) > current_max %update max point if we're higher than last max for this bump
                    current_max_point = high_points(k);
                    current_max = filtswpvec(high_points(k));
                end
            else % if looking at a new bump  %MODIFIED THIS TO REMOVE BUG ON 06/29/01
                sweep_spike_heights(current_max_point) = current_max; %create spike height from last bump
                current_max = filtswpvec(high_points(k));
                current_max_point = high_points(k);
            end
        end
    end

    %NOW REMOVE SPURIOUS SPIKES ARISING FROM DOWNWARD ELECTRICAL NOISE "SPIKES" IN UNFILTERED TRACE
    if remove_downward_spikes == 1
        filtspkpoints = find(sweep_spike_heights(:));
        for j = 1:length(filtspkpoints)
            if min(filtswpvec(max([filtspkpoints(j)-window_half_width,1]):...
                    min([filtspkpoints(j)+window_half_width,length(raw_sweep)]))) < ...
                    -sweep_spike_heights(filtspkpoints(j))
                sweep_spike_heights(filtspkpoints(j)) = 0;
            end
        end
    end
end

spike_vector = ceil(sweep_spike_heights/1000);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
