function varargout = SoundPlayer( varargin )

% exper 2 module that plays a collection of sounds that you can modify with
% a GUI. It's meant to work like TonePlayer, but extended to play more than
% just simple tones (e.g. can play FM/AM tones, etc) and also
% plays arrays of sounds rather than just a single tone. Importantly, it
% works by sending stimulus structures to StimulusCzar, so if you are
% recording data you should get the events and thus the ability to analyze
% the data just as if you had used StimulusProtocol to play a tuning curve.

global exper pref SoundPlayerTimer SoundPlayerTimerDelay

%StimulusCzar should take care of soundmethod now
%StimulusCzar should take care of calibration too

%note: I am eliminating PlayLoop, a continuous looping feature that
%TonePLayer has, because it doesn't seem compatible with the features of
%this module
%also eliminating tonetimer, I don't think it's relevant without looping

%last updated 01-20-2012 mw

varargout{1} = lower(mfilename);
if nargin > 0
    action = lower(varargin{1});
else
    action = lower(get(gcbo,'tag'));
end

switch action
    case 'init'
        %ModuleNeeds(me,{'ao','ai'});
        %SetParam(me,'priority','value',GetParam('ai','priority')+1);
        CreateGUI; %local function that creates ui controls and initializes ui variables
        SoundPlayerTimer=timer('TimerFcn',[me '(''next_stimulus'');'],'StopFcn',[me '(''restart_timer'');'],'ExecutionMode','singleShot');
        
    case 'reset'
        Stop;
        SetParam(me,'CurrentStim','value',0);
        SetParam(me,'nrepeats','value',0);
        MakeStimuli
        SetParam(me, 'description', '');
        
    case 'trialready'
        
    case 'trialend'
        
    case 'makestimuli'
        MakeStimuli;
        
    case 'play'
        Play;
        
        
    case 'next_stimulus'
        NextStimulus;
        
    case 'restart_timer'
        if SoundPlayerTimerDelay>-1
            SoundPlayerTimerDelay= round(1000*SoundPlayerTimerDelay)/1000;
            %hack to stop that annoying Warning: StartDelay property is
            %limited to 1 millisecond precision.  Sub-millisecond precision
            %will be ignored. mw053007
            set(SoundPlayerTimer,'StartDelay',SoundPlayerTimerDelay);
            start(SoundPlayerTimer);
        else
            stop(SoundPlayerTimer);
            set(SoundPlayerTimer,'StartDelay',0);    % next time we push the Play button, it will start immediately
        end
        
    case 'stop'
        Stop;
        
    case 'repeat'
        r=getparam(me, 'repeat')
        if ~r
            SetParam(me, 'repeat', 'value', 0, 'string', 'Repeat is Off');
        else
            SetParam(me, 'repeat', 'value', 1, 'string', 'Repeat is On');
        end
        
    case 'include_wn'
        r=getparam(me, 'include_WN')
        if ~r
            SetParam(me, 'include_WN', 'value', 0, 'string', 'WN not included');
        else
            SetParam(me, 'include_WN', 'value', 1, 'string', 'WN included');
        end
        SoundPlayer('reset')
        
    case 'single_freq'
        r=getparam(me, 'single_freq')
        if ~r
            SetParam(me, 'single_freq', 'value', 0, 'string', 'Multiple Freqs');
            SetParam(me, 'maxfreq', 'enable','on')
            SetParam(me, 'freqperoct', 'enable','on')
        else
            SetParam(me, 'single_freq', 'value', 1, 'string', 'Single Freq');
            SetParam(me, 'maxfreq', 'enable','off')
            SetParam(me, 'freqperoct', 'enable','off')
        end
        SoundPlayer('reset')
        
    case 'modmenu'
        switch getparam(me, 'ModMenu')
            case 1 %Mod Off
                SetParam(me, 'ModFreq', 'enable','off')
                SetParam(me, 'ModDepth', 'enable','off')
            case {2,3} %SinFM or SinAM
                SetParam(me, 'ModFreq', 'enable','on')
                SetParam(me, 'ModDepth', 'enable','on')
        end
        SoundPlayer('reset')
        
    case 'shuffle'
        r=getparam(me, 'shuffle')
        if ~r
            SetParam(me, 'shuffle', 'value', 0, 'string', 'Shuffle is Off');
            SetParam(me, 'filereps', 'value', 1);
        else
            SetParam(me, 'shuffle', 'value', 1, 'string', 'Shuffle is On');
            SetParam(me, 'filereps', 'value', 10);
        end
        SoundPlayer('reset')
        
    case 'help'
        helpstr={...
            'Soundplayer is an online sound array player. If you are recording data,',...
            'the stimuli are recorded and you can plot the tuning curves afterwards.', ...
            '', ...
            'Buttons automatically refresh the tone array. For text entry boxes, ',...
            'pressing enter or tab or clicking outside the box will refresh the ',...
            'tone array. The ''Reset'' button refreshes the tone array, stops playback, ',...
            'resets nrepeats to 0, and resets playback to start of tone array.', ...
            '', ...
            '', ...
            '''Write file'' writes the current tone array to a conventional stimulus', ...
            'protocol file in /protocols/Soundplayer Protocols, and you can then load', ...
            'these with the StimulusProtocol module.', ...
            'filereps determines how many repeats in the file, which is important if', ...
            'shuffle is on (so each repeat in the file is re-shuffled).', ...
            '', ...
            'Sinusoidal FM uses tone array frequencies as carrier frequencies.', ...
            'Modulation Frequency is in Hz, (e.g. 4 Hz)', ...
            'Modulation Depth is in octaves. It is symmetrical in Hz, but asymmetrical in octaves. The Hz change is given by the lower (smaller) octave direction.', ...
            'Sinusoidal AM uses tone array frequencies as carrier frequencies, including WN if selected.', ...
            'Modulation Frequency is in Hz, (e.g. 4 Hz)', ...
            'Modulation Depth is 0-100% (e.g. 100%)', ...
            '', ...
            'If you think of anything else that should go into this helpfile, you', ...
            'could let Mike know (or edit the file directly)', ...
            };
        h = helpdlg(helpstr,'SoundPlayer Help');
        
    case 'writefile'
        WriteFile
        
    case {'minfreq', 'isi', 'ramp', 'duration', 'numamps', 'maxamp', 'minamp',...
            'freqperoct', 'maxfreq', 'minfreq', 'modfreq', 'moddepth'}
        %reset and re-make stimuli if data is entered
        SoundPlayer('reset')
        
    case 'close'
        delete(SoundPlayerTimer);
        clear SoundPlayerTimer
        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MakeStimuli
try
    duration=getparam(me, 'Duration');
    param.duration=duration;
    param.ramp=getparam(me, 'Ramp');
    
    param.next=getparam(me, 'ISI');
    shuffle=GetParam(me, 'Shuffle');
    include_whitenoise=GetParam(me, 'include_WN');
    
    %assuming I do not need the stimuli(1) name/description etc that is in a protocol
    minfreq=GetParam(me, 'MinFreq');
    maxfreq=GetParam(me, 'MaxFreq');
    
    %error checking
    if    minfreq>maxfreq
        Message(me, 'maxfreq must be greater than minfreq');
        error
    end
    if minfreq==maxfreq
            SetParam(me, 'single_freq', 'value', 1, 'string', 'Single Freq');
            SetParam(me, 'maxfreq', 'enable','off', 'value', inf', 'string', '')
            SetParam(me, 'freqperoct', 'enable','off')
    end
if ~GetParam(me, 'Single_Freq') & maxfreq==Inf
    Message(me, 'specify max freq')
    error
end
    %if SingleFreq is enabled, just use a single frequency = minfreq
       if GetParam(me, 'Single_Freq') 
           logspacedfreqs=minfreq;
           freqsperoctave=0;
           numoctaves=0;
       else
 freqsperoctave=GetParam(me, 'FreqPerOct');
    numoctaves=log2(maxfreq/minfreq);
    logspacedfreqs=minfreq*2.^([0:(1/freqsperoctave):numoctaves]);
       end    
    newmaxfreq=logspacedfreqs(end);
    numfreqs=length(logspacedfreqs);
    if include_whitenoise==1
        logspacedfreqs=[logspacedfreqs -1]; %add whitenoise as extra freq=-1
        numfreqs=numfreqs+1;
    end
    
    SetParam(me, 'NumFreqs', numfreqs);
    numstim=numfreqs;
    h=getparam(me, 'Frequencies', 'h');
    pos=get(h, 'pos');
    pos(3)=21*numfreqs;
    set(h, 'pos', pos);
    SetParam(me, 'Frequencies', 'string',sprintf('%.1f ', logspacedfreqs/1000));
    g=findobj('parent', gcf, 'string', 'frequencies');
    posg=get(g, 'pos');
    posg(1)=pos(1)+pos(3);
    set(g, 'pos', posg);
    
    minamp=GetParam(me, 'MinAmp');
    maxamp=GetParam(me, 'MaxAmp');
        %error checking
    if    minamp>maxamp
        Message(me, 'maxamp must be greater than minamp');
        error
    elseif minamp==maxamp
        numamps=1;
        SetParam(me, 'NumAmps', 1);
    end
    numamps=GetParam(me, 'NumAmps');
    if numamps==1  
        SetParam(me, 'minamp', 'enable','off');
        SetParam(me, 'minamp', 'value', -Inf, 'string', '');
    else
         SetParam(me, 'minamp', 'enable','on');
    end
    if numamps>1 & minamp==-Inf
        Message(me, 'specify min amp')
        error
    end

    linspacedamplitudes= linspace( minamp, maxamp, numamps);
    h=getparam(me, 'amplitudes', 'h');
    pos=get(h, 'pos');
    pos(3)=20*numamps;
    set(h, 'pos', pos);
    SetParam(me, 'Amplitudes', round(linspacedamplitudes));
    g=findobj('parent', gcf, 'string', 'amplitudes');
    posg=get(g, 'pos');
    posg(1)=pos(1)+pos(3);
    set(g, 'pos', posg);
    
    durations=duration; %single duration for now
    numdurations=length(durations);
    numstim=numamps*numfreqs*numdurations;
    totaltime=numstim*(param.duration+param.next)/1000;
    
    if shuffle
        [Amplitudes,Freqs, Durations]=meshgrid( linspacedamplitudes , logspacedfreqs, durations );
        neworder=randperm( numfreqs * numamps * numdurations);
        amplitudes=zeros(size(neworder));
        freqs=zeros(size(neworder));
        durs=zeros(size(neworder));
        
        amplitudes( (1:prod(size(Amplitudes))) ) = Amplitudes( neworder );
        freqs( (1:prod(size(Freqs))) ) = Freqs( neworder );
        durs( (1:prod(size(Durations))) ) = Durations( neworder );
        
        GetParam(me, 'ModMenu'); %1=off, 2=SinFM, 3=SinAM
        for n=1:length(amplitudes)
            if freqs(n)==-1 & (GetParam(me, 'ModMenu')==1 | GetParam(me, 'ModMenu')==2) %whitenoise
                stimuli(n).type='whitenoise';
                param.frequency=-1;
            elseif freqs(n)~=-1 & GetParam(me, 'ModMenu')==2 %FM tone
                %   carrier_phase - fixed at 0
                %   modulation_frequency (in Hz)
                %   modulation_phase - fixed at 0
                %   modulation_index  -   frequency deviation in Hz
                stimuli(n).type='fmtone';
                param.carrier_frequency=freqs(n);
                param.frequency=freqs(n); %not used except for description
                param.carrier_phase=0;
                param.modulation_phase=0;
                param.modulation_frequency= GetParam(me,'ModFreq');
                    ModDepthOctaves=GetParam(me,'ModDepth');
                    fc=param.carrier_frequency;
                    param.modulation_index=fc-fc/(2^ModDepthOctaves);
            elseif freqs(n)~=-1 & GetParam(me, 'ModMenu')==3 %AM tone
                stimuli(n).type='amtone';
                param.carrier_frequency=freqs(n);
                param.frequency=freqs(n); %not used except for description
                param.carrier_phase=0;
                param.modulation_phase=0;
                param.modulation_frequency= GetParam(me,'ModFreq');
                param.modulation_depth=.01*GetParam(me,'ModDepth');
            elseif freqs(n)==-1 & GetParam(me, 'ModMenu')==3 %AM noise
                stimuli(n).type='amnoise';
                param.frequency=freqs(n); %not used except for description
                param.carrier_phase=0;
                param.modulation_phase=0;
                param.modulation_frequency= GetParam(me,'ModFreq');
                param.modulation_depth=.01*GetParam(me,'ModDepth');
            elseif GetParam(me, 'ModMenu')==1 %pure tone
                stimuli(n).type='tone';
                param.frequency=freqs(n);
            else
                error('WTF?')
            end
            param.amplitude=amplitudes(n);
            stimuli(n).param=param;
            stimuli(n).description=sprintf('%s %.1fkHz %ddB', stimuli(n).type, param.frequency/1000, param.amplitude);
            
        end
        
    else %not shuffle
        n=0;
        for aindex=1:numamps
            for findex=1:numfreqs
                n=n+1;
                if logspacedfreqs(findex)==-1 & (GetParam(me, 'ModMenu')==1 | GetParam(me, 'ModMenu')==2) %whitenoise
                    stimuli(n).type='whitenoise';
                    param.frequency=-1;
                elseif logspacedfreqs(findex)~=-1 & GetParam(me, 'ModMenu')==2 %FM tone
                    %   carrier_phase - fixed at 0
                    %   modulation_frequency (in Hz)
                    %   modulation_phase - fixed at 0
                    %   modulation_index  -   frequency deviation in Hz
                    stimuli(n).type='fmtone';
                    param.carrier_frequency=logspacedfreqs(findex);
                    param.frequency=logspacedfreqs(findex); %not used except for description
                    param.carrier_phase=0;
                    param.modulation_phase=0;
                    param.modulation_frequency= GetParam(me,'ModFreq');
                    ModDepthOctaves=GetParam(me,'ModDepth');
                    fc=param.carrier_frequency;
                    param.modulation_index=fc-fc/(2^ModDepthOctaves);
                elseif logspacedfreqs(findex)~=-1 & GetParam(me, 'ModMenu')==3 %AM tone
                    stimuli(n).type='amtone';
                    param.carrier_frequency=logspacedfreqs(findex);
                    param.frequency=logspacedfreqs(findex); %not used except for description
                    param.carrier_phase=0;
                    param.modulation_phase=0;
                    param.modulation_frequency= GetParam(me,'ModFreq');
                    param.modulation_depth=.01*GetParam(me,'ModDepth');
                elseif logspacedfreqs(findex)==-1 & GetParam(me, 'ModMenu')==3 %AM noise
                    stimuli(n).type='amnoise';
                    param.frequency=logspacedfreqs(findex); %not used except for description
                    param.carrier_phase=0;
                    param.modulation_phase=0;
                    param.modulation_frequency= GetParam(me,'ModFreq');
                    param.modulation_depth=.01*GetParam(me,'ModDepth');
                elseif GetParam(me, 'ModMenu')==1 %pure tone
                    stimuli(n).type='tone';
                    param.frequency=logspacedfreqs(findex);
                end
                param.amplitude=linspacedamplitudes(aindex);
                stimuli(n).param=param;
                stimuli(n).description=sprintf('%s %.1fkHz %ddB', stimuli(n).type, param.frequency/1000, param.amplitude);
                
            end
        end
    end
    SetParam(me, 'Stimuli', stimuli);
    SetParam(me, 'NStimuli', numstim);
    SetParam(me, 'TotalTime', totaltime);
    
    
    Message(me, 'Generated Stimuli.', 'append');
    SetParam(me, 'StimOK', 1);
catch
    Message(me, 'Failed to generate stimuli.', 'append');
    SetParam(me, 'StimOK', 0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Play
global SoundPlayerTimer

MakeStimuli;

if GetParam(me, 'StimOK')
    Message(me, 'sound playing...', 'append');
    start(SoundPlayerTimer);
else
    Message(me, 'Can''t play sounds', 'append')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function NextStimulus
global SoundPlayerTimer SoundPlayerTimerDelay
current=GetParam(me,'CurrentStim');
nstimuli=GetParam(me,'NStimuli');
if current==nstimuli % we played everything
    current=0;                % so let's start from the beginning;
    SetParam(me,'NRepeats', GetParam(me, 'NRepeats')+1);
    if  ~GetParam(me,'Repeat')           % if we don't want to repeat,
        SoundPlayerTimerDelay=-1;          % this will cause the timer to stop
        SetParam(me,'Run',0);
        SetParam(me,'CurrentStim',current);
        Message(me, 'finished playing sounds...', 'append');
        
        return;
    else
    MakeStimuli; %to reshuffle for each array repeat       
    end
end
current=current+1;
SetParam(me,'CurrentStim',current);
stimuli=GetParam(me, 'Stimuli');
stimulus=stimuli(current);
SetParam(me, 'description', stimulus.description);
if isfield(stimulus.param,'next')
    iti=stimulus.param.next/1000;
else
    iti=0.5;    % set fixed iti for now to 500ms;
end

delay=0;  % 0.25s is the min. delay imposed by SoundLoad
delay=max(delay,0);
if ~isfield(stimulus.param, 'duration')
    error('Improperly designed stimulus: no duration field. ')
end
SoundPlayerTimerDelay=stimulus.param.duration/1000+iti-delay; % next time I should also check whether iti-delay>0

%fprintf('\nSoundPlayerTimerDelay %.1f', SoundPlayerTimerDelay)
SendStimulus(stimulus);
% Message(me,[num2str(current(protocol)) '/' num2str(nstimuli(protocol))]);
Message(me,[num2str(current) '/' num2str(nstimuli) ', ' num2str(GetParam(me, 'NRepeats')) ' repeats' ], 'append');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SendStimulus(stimulus)
%global exper pref
StimulusCzar('send',stimulus);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Stop
global SoundPlayerTimer SoundPlayerTimerDelay
%SetParamUI(me,'Play','backgroundcolor',[0 0.9 0],'String','Play');
SoundPlayerTimerDelay=-1;
stop(SoundPlayerTimer);

Message(me, 'sound stopped.', 'append');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function WriteFile
global pref
cd(pref.stimuli)
if ~exist('SoundPlayer Protocols','dir')
    mkdir('SoundPlayer Protocols')
end
cd('SoundPlayer Protocols')
stim=GetParam(me, 'Stimuli');
if GetParam(me, 'shuffle')    %reshuffle each repeat
    for n=1:GetParam(me, 'filereps')
        %Message(me, sprintf('%d:%d',2+(n-1)*length(stim),n*length(stim)+1), 'append')
        neworder=randperm(length(stim));
        stimuli(2+(n-1)*length(stim):n*length(stim)+1)=stim(neworder);
    end
else %don't shuffle
    for n=1:GetParam(me, 'filereps')
        stimuli(2+(n-1)*length(stim):n*length(stim)+1)=stim;
    end
    
end
% generate filename
filename='';
filename=sprintf('%s', filename);
if GetParam(me, 'single_freq')
    filename=sprintf('%s%.1fkHz', filename, .001*GetParam(me, 'minfreq'));
else
filename=sprintf('%s%dfpo', filename, GetParam(me, 'freqperoct'));
    filename=sprintf('%s%.1f-%.1fkHz', filename, .001*GetParam(me, 'minfreq'), .001*GetParam(me, 'maxfreq'));
end
if GetParam(me, 'include_wn')==1
    filename=sprintf('%s+WN', filename);
end
if GetParam(me, 'numamps')==1
    filename=sprintf('%s%ddB', filename, GetParam(me, 'maxamp'));
else
    filename=sprintf('%s_%d-%ddB', filename, GetParam(me, 'minamp'), GetParam(me, 'maxamp'));
end
if GetParam(me, 'ModMenu')==2
    filename=sprintf('%s_fm%dhz-%d%%', filename, GetParam(me, 'modfreq'), GetParam(me, 'moddepth'));
elseif GetParam(me, 'ModMenu')==3
    filename=sprintf('%s_am%dhz-%d%%', filename, GetParam(me, 'modfreq'), GetParam(me, 'moddepth'));
end
    filename=sprintf('%s_isi%dms', filename, GetParam(me, 'isi'));
    filename=sprintf('%s_dur%dms', filename, GetParam(me, 'duration'));
    if GetParam(me, 'shuffle')   
        filename=sprintf('%s_sh', filename);
    end
    filename=sprintf('%s_n%d', filename, GetParam(me, 'filereps'));
stimuli(1).type='exper2 stimulus protocol';
stimuli(1).param.name= sprintf('SoundPlayer_TC%s', filename);
stimuli(1).param.description=sprintf('SoundPlayer_TC%s', filename);

filename=sprintf('%s.mat', filename)
save(filename, 'stimuli')
Message(me, 'wrote file:', 'append')
Message(me, filename, 'append')
Message(me, sprintf('in directory %s', pwd), 'append')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CreateGUI
global  pref
% this creates all the ui controls for this module
fig = ModuleFigure(me,'visible','off');

% GUI positioning factors
hs = 60;
h = 5;
vs = 20;
n = 1;


%Defaults
Duration=100; %ms
MinFrequency=2e3; %Hz
MaxFrequency=8e3; %Hz
FreqPerOctave=4; %Hz
minamp=60; %dBSPL
maxamp=80; %dBSPL
numamps=3;
Ramp=10; %ms
ISI=500;

%panel containers
%DO NOT work well with exper uiparams
   hpfreq = uipanel('Title','Frequencies', 'backgroundcolor', [.8 .8 .8],...
       'Position',[.005 .01 .9 .2]);
   hpamp = uipanel('Title','Amplitudes', 'backgroundcolor', [.8 .8 .8],...
       'Position',[.005 .22 .65 .12]);



InitParam(me,'MinFreq', ...
    'value',MinFrequency,...
    'ui','edit','pos',[h n*vs hs vs]); 
InitParam(me,'MaxFreq',...
    'value',MaxFrequency,...
    'ui','edit','pos',[h+2*hs n*vs hs vs]); n=n+1;
InitParam(me,'FreqPerOct',...
    'value',FreqPerOctave,...
    'ui','edit','pos',[h n*vs hs vs]); n=n+1;
InitParam(me,'Include_WN',...
    'string','WN included','value',1,'ui','togglebutton',...
    'pos',[h n*vs 1.5*hs vs]);n=n+1;
InitParam(me,'Single_Freq',...
    'string','Multiple Freqs','value',0,'ui','togglebutton',...
    'pos',[h n*vs 1.5*hs vs]);n=n+1;

%h+3*hs for right column
InitParam(me,'NumFreqs',...
    'value',0,...
    'ui','disp','pos',[h n*vs hs vs]); n=n+1;
InitParam(me,'Frequencies','value',0,'pref', 0, ...
    'ui','disp','pos',[h n*vs hs vs]); n=n+1;

%Modulation panel - using combined FM/AM params since they are the same
n=16;
ModType={'Mod Off', 'sinFM', 'sinAM'};
InitParam(me,'ModType','value',ModType);
InitParam(me,'ModMenu','value',1,...
    'ui','popupmenu','pos',[h+3*hs n*vs 1.5*hs vs]);n=n-1;
SetParamUI(me,'ModMenu','String',ModType,'value',1);

InitParam(me,'ModFreq',...
    'enable', 'off', 'value',4,'ui','edit',...
    'pos',[h+3*hs n*vs 1.5*hs vs]);n=n-1;
InitParam(me,'ModDepth',...
    'enable', 'off', 'value',100,'ui','edit',...
    'pos',[h+3*hs n*vs 1.5*hs vs]);n=n-1;

%Amplitude Panel
n=8;
n=n+1;
InitParam(me,'MinAmp',...
    'value',minamp,...
    'ui','edit','pos',[h n*vs hs vs]);
InitParam(me,'MaxAmp',...
    'value',maxamp,...
    'ui','edit','pos',[h+2*hs n*vs hs vs]); n=n+1;
InitParam(me,'NumAmps',...
    'value',numamps,...
    'ui','edit','pos',[h n*vs hs vs]); n=n+1;
InitParam(me,'Amplitudes',...
    'value',0,...
    'ui','disp','pref', 0, 'pos',[h n*vs hs vs]); n=n+1;

n=n+1;

InitParam(me,'Duration',...
    'value',Duration,...
    'ui','edit','pos',[h n*vs hs vs]); n=n+1;

InitParam(me,'Ramp',...
    'value',Ramp,...
    'ui','edit','pos',[h n*vs hs vs]); n=n+1;

InitParam(me,'ISI',...
    'value',ISI,...
    'ui','edit','pos',[h n*vs hs vs]); n=n+1;


InitParam(me,'CurrentStim','value',0, ...
    'ui','disp','pos',[h n*vs hs vs]); n=n+1;

InitParam(me,'NStimuli','value',[], ...
    'ui','disp','pos',[h n*vs hs vs]); n=n+1;

InitParam(me,'TotalTime','value',0, ...
    'ui','disp','pos',[h n*vs hs vs]); n=n+1;

InitParam(me,'NRepeats','value',0, ... %accumulates number of repeats played %mw101806
    'ui','disp','pos',[h n*vs hs vs]); n=n+1;

InitParam(me,'Repeat',...
    'string','Repeat is On','value',1,'ui','togglebutton',...
    'pos',[h n*vs 1.5*hs vs]);n=n+1;

InitParam(me,'Shuffle',...
    'string','Shuffle is Off','value',0,'ui','togglebutton',...
    'pos',[h n*vs 1.5*hs vs]);n=n+1;

% pushbuttons are little different
uicontrol('parent',fig,'string','Play','tag','Play',...
    'position',[h n*vs hs vs],...
    'style','pushbutton','callback',[me ';']); n=n+1;

InitParam(me,'Run','value',0);



uicontrol('parent',fig,'string','Stop','tag','Stop',...
    'position',[h n*vs hs vs],...
    'style','pushbutton','callback',[me ';']); n=n+1;



uicontrol('parent',fig,'string','Reset','tag','Reset',...
    'position',[h (n)*vs hs vs],...
    'style','pushbutton','callback',[me ';']); n=n+1;

InitParam(me,'Description','string','', 'ui','disp','pos',[h n*vs 3*hs vs], 'pref', 0); n=n+1;
n=n+1;
%MakeStimuli

% message box panel container ?
hpmsg = uipanel('Title','Messages', 'Position',[.05 .75 .8 .25]);

% message box
hmsg=uicontrol('parent', hpmsg,'tag','message','style','text',...
    'backgroundcolor', [.9 .9 .9],...
    'enable','inact','horiz','left',...
    'units', 'normalized', 'pos',[0 0 1 1]); n = n+1; %[h n*vs 3*hs vs]
% uicontrol(fig,'parent', hpmsg,'tag','message','style','text',...
%     'backgroundcolor', [.9 .9 .9],...
%     'enable','inact','horiz','left','pos',[h n*vs hs*2 vs*10]); n = n+1;

n=n-5;


n=n-1;
n=n-1;
uicontrol('parent',fig,'string','Help','tag','Help',...
    'position',[h+3*hs (n)*vs hs vs],...
    'style','pushbutton','callback',[me ';']); n=n-1;

n=n-1;
uicontrol('parent',fig,'string','Write File','tag','WriteFile',...
    'position',[h+3*hs (n)*vs hs vs],...
    'style','pushbutton','callback',[me ';']); 

InitParam(me,'filereps',...
    'value',1,...
    'ui','edit','pos',[h+4.5*hs n*vs .6*hs vs]); n=n-1;


InitParam(me,'Stimuli','value',[]);
InitParam(me, 'StimOK', 'value', 0); %MakeStimuli sets to 1 upon success


set(fig,'pos',[1190         274         400         760]);
% Make figure visible again.
set(fig,'visible','on');
MakeStimuli
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return the name of this file/module.
function out = me
out = lower(mfilename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%