function out=WNTrainResponse(varargin)

global exper pref shared

out = lower(mfilename);
if nargin > 0
	action = lower(varargin{1});
else
	action = lower(get(gcbo,'tag'));
end

switch action
	
case 'init'
    ModuleNeeds(me,{'dataguru','stimulusprotocol'}); % needs data extracted by DataGuru
    
    %%%%%% TEMPORARY: Channel plotted
    InitParam(me,'Channel','value',1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    dataChannels=GetChannel('ai','datachannel');
    AIChannel=AI('GetChannelIdx',[dataChannels.number]);
    InitParam(me,'DataChannels','value',AIChannel);
    nChannels=length(dataChannels);
    InitParam(me,'NChannels','value',nChannels);
%     dataChannels=GetChannel('ai','datachannel');
    InitParam(me,'DataChannels','value',[dataChannels.number]+1);
    SetSharedParam('TraceHandles',[]);
    SetSharedParam('Traces',[]);
    SetSharedParam('NTraces',[]);
    InitParam(me,'XAxis','value',[]);
    InitParam(me,'XAxisLabel','value','');
    InitParam(me,'YAxis','value',[]);
    InitParam(me,'YAxisLabel','value','');
    samplerate=AI('GetSampleRate')/1000;
    InitParam(me,'AISamplerate','value',samplerate);
    SetSharedParam('XPlot',[]);
    %%%%%%%%%%%%%%%%%%%
    % this will become more general
    InitParam(me,'Type','value','clicktrain');

    InitParam(me,'XParam','value','frequency');
    InitParam(me,'YParam','value','amplitude');
    InitParam(me,'DParam','value','isi');
    %%%%%%%%%%%%%%%%%%%
    InitializeGUI;
    if ~isempty(GetSharedParam('StimulusProtocols'))    % no protocols available
        InitializeTraces;
    end
        
case 'getready'
    ClearTraces;
    ClearPlot;
    InitializeTraces;
	DisableParamChange;
		
case 'reset'
	ClearTraces;
	ClearPlot;
	EnableParamChange;
		
case 'tracelength'
	
case 'traceheight'
	
case 'clear'
	ClearTraces;
	ClearPlot;
    InitializeTraces;
	
case 'estimulusprotocolchanged'
    ClearTraces;
    ClearPlot;
    InitializeTraces;
    
case 'watch'
    if GetParam(me,'Watch');
        SetParamUI(me,'Watch','background',[0 0.9 0.9],'String','Watching...');
    else
        SetParamUI(me,'Watch','background',[0 0.9 0],'String','Watch');
    end
    
case 'psth'
    if GetParam(me,'PSTH');
        SetParamUI(me,'PSTH','foregroundcolor',[0 0 1],'backgroundcolor',[0 1 1],'String','PSTH');
    else
        SetParamUI(me,'PSTH','foregroundcolor',[1 1 1],'backgroundcolor',[0.1 0 0.9],'String','PSTH');
    end
	ClearTraces;
	ClearPlot;
    InitializeTraces;    
    
case 'copy'
    disp('copy');
    
case 'edataavailable'
    if GetParam(me,'Watch')
        stimulus=GetSharedParam('CurrentStimulus');
        type=GetParam(me,'Type');
               
        if strcmpi(stimulus.type,type) 
            data=GetSharedParam('CurrentData');
            dataSize=size(data);
            dataChannels=GetParam(me,'DataChannels');
            nChannels=GetParam(me,'NChannels');
            psth=GetParam(me,'PSTH');
            if psth
                data=data(:,nChannels+1:end);   % the extracted spikes are always in the last half (of columns) of data
            else
                data=data(:,1:nChannels); % otherwise we get data from the data channel
                data=data-repmat(data(1,:),dataSize(1),1); % subtract the beginning
            end
            samplerate=GetParam(me,'AISampleRate');
            tracelength=GetParam(me,'TraceLength')*samplerate;
            stimlength=stimulus.stimlength*samplerate;
            stimlength=min([stimlength, tracelength, dataSize(1)]);
%            data=data(1:stimlength,:);
            traces=GetSharedParam('Traces');
            ntraces=GetSharedParam('NTraces');
            tracehandles=GetSharedParam('TraceHandles');
            traceheight=GetParam(me,'TraceHeight');
            

            start=stimulus.param.start;
            isi=stimulus.param.isi;
            nclicks=stimulus.param.nclicks;
            onsets=(start+isi*(0:nclicks-1))*samplerate;
            M=[];
            for i=1:nclicks
                if length(data)>onsets(i)+isi*samplerate
                    M(i,:)=data(onsets(i)+1:onsets(i)+isi*samplerate);
                end
            end
if ~isempty(M)
    meandata=mean(M);
else
    meandata=NaN;
end
            xparam=GetParam(me,'XParam');
            xaxis=GetParam(me,'XAxis');
         
            x=-1;
            
            xpos=find(xaxis==x);
            yparam=GetParam(me,'YParam');
            yaxis=GetParam(me,'YAxis');
            expr=sprintf('stimulus.param.%s',yparam);
            y=eval(expr);
            ypos=find(yaxis==y);
            tracepos=(ypos-1)*length(xaxis)+xpos;
            ntraces(tracepos)=ntraces(tracepos)+1;
            
    

            if psth
                psthbin=GetParam(me,'PSTHBin')*samplerate;
                stimlength=stimlength-rem(stimlength,psthbin);
                % temporary
                    data=data(1:stimlength,:);
                %
                data=sum(reshape(data,psthbin,[]));     % sum the spikes in the bins
                data=repmat(data,psthbin,1);
            end
      if ~isnan(meandata)
            traces(1:length(meandata),tracepos)=traces(1:length(meandata),tracepos)+meandata';
      end            
            if psth
                dataPlot=traces(:,tracepos)/traceheight/10;    % final adjustment: shrink for plotting
            else
                dataPlot=traces(:,tracepos)/ntraces(tracepos)/traceheight;    % final adjustment: average and shrink for plotting
            end
            xplot=GetSharedParam('XPlot');
            set(tracehandles(tracepos),'XData',xpos+xplot,'YData',ypos+dataPlot);
            drawnow;
            SetSharedParam('Traces',traces);
            SetSharedParam('NTraces',ntraces);
        end
    end    
    
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out=me
% Get the name of this module
out=lower(mfilename);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function InitializeGUI
    fig = ModuleFigure(me);
    set(fig,'doublebuffer','on','Position',[300 300 600 400]);

    traceaxes=axes('units','normal','position',[0.1 0.25 0.8 0.7]);    
    InitParam(me,'TraceAxes','value',traceaxes);
    
        % Watch button. 
    InitParam(me,'Watch','value',0,'ui','togglebutton','pref',0,'units','normal','pos',[0.1 0.02 0.2 0.1]);
	SetParamUI(me,'Watch','string','Watch','fontweight','bold','backgroundcolor',[0 0.9 0],'label','');
%     InitParam(me,'Clear','value',0,'ui','togglebutton','pref',0,'units','normal','pos',[0.3 0.02 0.2 0.1]);
% 	SetParamUI(me,'Clear','string','Clear','label','');
    
    % PSTH button. 
    InitParam(me,'PSTH','value',0,'ui','togglebutton','pref',0,'units','normal','pos',[0.3 0.02 0.10 0.1]);
	SetParamUI(me,'PSTH','string','PSTH','fontweight','bold','foregroundcolor',[1 1 1],'backgroundcolor',[0.1 0 0.9],'label','');

        % Clear button. 
    uicontrol('parent',fig,'string','Clear','tag','clear','units','normal',...
		'position',[0.4 0.02 0.10 0.1],'enable','on',...
		'style','pushbutton','callback',[me ';']);
        % Copy button. 
    uicontrol('parent',fig,'string','Copy','tag','copy','units','normal',...
		'position',[0.5 0.02 0.10 0.1],'enable','on',...
		'style','pushbutton','callback',[me ';']);
    
    uicontrol('parent',fig,'string','reset','tag','reset','units','normal',...
		'position',[0.6 0.02 0.10 0.1],'enable','on',...
		'style','pushbutton','callback',[me ';']);
    
    InitParam(me,'PSTHBin','value',10);
    
    InitParam(me,'TraceHeight','value',2,'ui','edit','units','normal','pos',[0.7 0.07 0.1 0.05]);
    InitParam(me,'TraceLength','value',100,'ui','edit','units','normal','pos',[0.7 0.02 0.1 0.05]);
    
    %xlabel
    xlabelhandle=text(0.5,-0.11,'','units','normal','HorizontalAlignment','center');
    InitParam(me,'XLabelHandle','value',xlabelhandle);    
    ylabelhandle=text(-0.09,0.5,'','units','normal','HorizontalAlignment','center','Rotation',90);
    InitParam(me,'YLabelHandle','value',ylabelhandle);    
    
    uicontrol(fig,'tag','message','style','edit','fontweight','bold','units','normal',...
        'enable','inact','horiz','left','pos',[0.1 0.14 0.8 0.05]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function InitializeTraces

    type=GetParam(me,'Type');
    xparam=GetParam(me,'XParam');
    yparam=GetParam(me,'YParam');
    dparam=GetParam(me,'DParam');

    protocol=StimulusProtocol('GetCurrentProtocol');
    allprotocols=GetSharedParam('StimulusProtocols');
    if isempty(allprotocols)
        Message(me, 'no stimulus protocols loaded!')
        return
    end
    stimuli=allprotocols{protocol};
    idx=find(strcmp({stimuli.type},type));
    if isempty(idx)
        return;
    end
    param=[stimuli(idx).param];

    xaxis=-1; %only -1 freq for white noise
    expr=sprintf('unique([param.%s]);',yparam);  % get all the stuff for y axis
    yaxis=eval(expr);
    SetParam(me,'XAxis',xaxis);
    SetParam(me,'XAxisLabel',xparam);
    SetParam(me,'YAxis',yaxis);
    SetParam(me,'YAxisLabel',yparam);
    try
        expr=sprintf('unique([param.%s]);',dparam);  % get the trace length
        duration=eval(expr);
    catch
        duration=100;
    end
    
    %TEMPORARY - plotting all data channels next to each other
    duration=max(duration)*GetParam(me,'NChannels');
    % TEMPORARY
    
    SetParam(me,'TraceLength',duration);
    duration=duration*GetParam(me,'AISampleRate');
    xplot=((1:duration)-(duration/2))/duration/1.2;
    SetSharedParam('XPlot',xplot);
    
    nxaxis=length(xaxis);
    nyaxis=length(yaxis);

    oldfig=gcf;
    traceaxes=GetParam(me,'TraceAxes');
    axes(traceaxes);
    set(traceaxes,'XLim',[0.5 nxaxis+0.5],'YLim',[0.5 nyaxis+0.5]);
    %xaxis
    n=5*(nxaxis>4)+nxaxis*(nxaxis<5);   % x axis
    f=round(linspace(1,nxaxis,n));
    set(traceaxes,'XTick',f,'XTickLabel',round(xaxis(f)));
    set(GetParam(me,'XLabelHandle'),'String',xparam);
    %yaxis
    n=5*(nyaxis>4)+nyaxis*(nyaxis<5);   % y axis
    f=round(linspace(1,nyaxis,n));
    set(traceaxes,'YTick',f,'YTickLabel',round(yaxis(f)));
    set(GetParam(me,'YLabelHandle'),'String',yparam);
    
    % and now the main thing
    traces=zeros(duration,nxaxis*nyaxis);
    xlines=repmat(1:nxaxis,1,nyaxis);
    ylines=1:nyaxis;
    ylines=ylines(ones(1,nxaxis),:);
    ylines=reshape(ylines,1,[]);
%     axes(traceaxes);
    tracehandles=line([xlines;xlines],[ylines;ylines]);
%     set(tracehandles,'Parent',traceaxes);
    set(tracehandles,'Color','b');
    figure(oldfig);
    SetSharedParam('Traces',traces);
    SetSharedParam('TraceHandles',tracehandles);
    SetSharedParam('NTraces',zeros(1,nxaxis*nyaxis));

    yL=get(traceaxes,'YLim');
    line([1.5 1.5], yL, 'color', 'r');
    text(.6, yL(2)+.03*diff(yL), 'WN')
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ClearTraces
    SetSharedParam('Traces',[]);
    SetSharedParam('NTraces',[]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ClearPlot
    handles=GetSharedParam('TraceHandles');
    if ~isempty(handles)
        delete(handles);
        SetSharedParam('TraceHandles',[]);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DisableParamChange
fig=findobj('type','figure','tag',me);
h=findobj(fig,'type','uicontrol','style','edit');
for cnt=1:length(h)
	set(h(cnt),'enable','off')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function EnableParamChange
fig=findobj('type','figure','tag',me);
h=findobj(fig,'type','uicontrol','style','edit');
for cnt=1:length(h)
	set(h(cnt),'enable','on')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
