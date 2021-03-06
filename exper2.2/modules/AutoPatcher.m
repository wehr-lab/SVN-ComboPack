function AutoPatcher(varargin)
%travel is in microns
%speed and velocity are in microns per second

global exper pref
persistent ai2 ao2 dio2 DataCh GainCh ModeCh ph pw samples fig curaxes curline curpoint s
persistent RunningH RsH RtH MP285posH aoSampleRate deltaRH baselineRH



if nargin > 0
    if isobject(varargin{1})
        action = 'freerun';
    else
        action = lower(varargin{1});
    end
else
    action = lower(get(gcbo,'tag'));
    if isempty(action)
        action = 'freerun';
    end
end

% fprintf('\n%s', action)
set(fig, 'name', ['AutoPatcher: ', action])


switch action
    case 'init'
        ModuleNeeds(me,{'ai','ao','patchpreprocess'});
        SetParam(me,'priority','value', GetParam('patchpreprocess','priority')+1);
        
        fig = ModuleFigure(me);
        set(fig,'DoubleBuffer','on','Position',[360 400 800 600]);
        
        
        v_height=-10;
        InitParam(me,'v_height','value',v_height,...
            'ui','edit','units','normal','pos',[0.1 0.002 0.08 0.04]);
        v_width=30;
        InitParam(me,'v_width','value',v_width,'range',[26 Inf],...
            'ui','edit','units','normal','pos',[0.28 0.002 0.08 0.04],'save',1);
        
        i_height=-100;
        InitParam(me,'i_height','value',i_height,...
            'ui','edit','units','normal','pos',[0.1 0.042 0.08 0.04]);
        i_width=30;
        InitParam(me,'i_width','value',i_width,'range',[26 Inf],...
            'ui','edit','units','normal','pos',[0.28 0.042 0.08 0.04],'save',1);
        
        
        uicontrol('parent',fig,'string','in','tag','zoomin','fontname','Arial',...
            'fontsize',12,'fontweight','bold',...
            'units','normal','position',[0.6 0.08 0.1 0.123],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        
        uicontrol('parent',fig,'string','out','tag','zoomout','fontname','Arial',...
            'fontsize',12,'fontweight','bold',...
            'units','normal','position',[0.7 0.08 0.1 0.123],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        
        uicontrol('parent',fig,'string','center','tag','center','fontname','Arial',...
            'fontsize',12,'fontweight','bold',...
            'units','normal','position',[0.8 0.08 0.1 0.123],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        
        % Boxes for displaying the resistance.
        fontweight='bold'; %trying to save room compared to bold
        hp=0; %horizontal position of ui
        w=.04; %width of ui
        hsp=0.01; %horizontal spacing between uis
        hp=hp+w;
        
        uicontrol(fig,'tag','Rt text','style','text','fontsize',12,'fontweight',fontweight,...
            'string','Rt ','FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        hp=hp+w;
        w=.12;
        RtH=uicontrol(fig,'tag','Rt','style','text','fontsize',12,'fontweight',fontweight,...
            'string',0,'FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        hp=hp+w+hsp;
        w=.04;
        uicontrol(fig,'tag','Rs text','style','text','fontsize',12,'fontweight',fontweight,...
            'string','Rs ','FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        hp=hp+w;
        w=.12;
        RsH=uicontrol(fig,'tag','Rs','style','text','fontsize',12,'fontweight',fontweight,...
            'string',0,'FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        hp=hp+w+hsp;
        w=.10;
        uicontrol(fig,'tag','baseline R text','style','text','fontsize',12,'fontweight',fontweight,...
            'string', {'BaselineR', 'dR(t-1)'},'FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        hp=hp+w;
        w=.12;
        baselineRH=uicontrol(fig,'tag','baselineR','style','text','fontsize',12,'fontweight',fontweight,...
            'string',0,'FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        hp=hp+w+hsp;
        w=.07;
        uicontrol(fig,'tag','deltaR text','style','text','fontsize',12,'fontweight',fontweight,...
            'string','DeltaR','FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        hp=hp+w;
        w=.10;
        deltaRH=uicontrol(fig,'tag','deltaR','style','text','fontsize',12,'fontweight',fontweight,...
            'string',0,'FontName','Arial',...
            'units','normal','pos',[hp 0.92 w 0.06]);
        
        % Boxes for displaying the MP285 position.
        v=1; %vertical position of ui
        h=0.04; %height of ui
        sp=0.01; %vertical spacing between uis
        v=v-h-sp;
        h=uicontrol(fig,'tag','MP285pos text','style','text','fontsize',12,'fontweight','bold',...
            'string','MP285 pos','FontName','Arial',...
            'units','normal','pos',[0.8 v 0.18 h]);
        h=.12;
        v=v-h-sp;
        MP285posH=uicontrol(fig,'tag','MP285pos','style','text','fontsize',12,'fontweight','bold',...
            'string','','HorizontalAlignment', 'right', 'FontName','Arial',...
            'units','normal','pos',[0.8 v 0.18 h]);
        
        %robot parameters and controls
        vel=100;
        h=.04;
        v=v-h-sp;
        InitParam(me,'velocity','value',vel,...
            'ui','edit','units','normal','pos',[0.8 v 0.08 h]);
        step=2;
        h=.04;
        v=v-h-sp;
        InitParam(me,'stepsize','value',step,...
            'ui','edit','units','normal','pos',[0.8 v 0.08 h]);
        h=.04;
        v=v-h-sp;
        InitParam(me,'axis','value',1,'string', 'x|y|z',...
            'ui','popupmenu','units','normal','pos',[0.8 v 0.08 h]);
        numpulses=10;
        h=.04;
        v=v-h-sp;
        InitParam(me,'npulses','value',numpulses,...
            'ui','edit','units','normal','pos',[0.8 v 0.08 h]);
        maxtravel=1000; %abort if robot travels this far
        h=.04;
        v=v-h-sp;
        InitParam(me,'maxtravel','value',maxtravel,...
            'ui','edit','units','normal','pos',[0.8 v 0.08 h]);
        dRthreshold=.250; %MOhm, neuron hunting pipette resistance increase threshold
        h=.04;
        v=v-h-sp;
        InitParam(me,'dRthresh','value',dRthreshold,...
            'ui','edit','units','normal','pos',[0.8 v 0.08 h]);
        
        h=.09;
        v=v-h-sp;
        uicontrol('parent',fig,'string','start','tag','start','fontname','Arial',...
            'fontsize',12,'fontweight','bold',...
            'units','normal','position',[0.8 v 0.1 h],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        h=.09;
        v=v-h-sp;
        uicontrol('parent',fig,'string','stop','tag','stop','fontname','Arial',...
            'fontsize',12,'fontweight','bold',...
            'units','normal','position',[0.8 v 0.1 h],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        InitParam(me,'abort','value',0)
        
        %ignoreMP285?
        uicontrol('parent',fig,'string','ignoreMP285','tag','ignoreMP285','fontname','Arial',...
            'fontsize',8,'value', 0, ...
            'units','normal','position',[0.62 0.01 0.13 .05],'enable','on',...
            'style','checkbox');%,'callback',[me ';']);
        InitParam(me,'ignoreMP285','value',0)
        
        %"just move" parameters and controls
        %(these are for just robotic motion, no feedback or R testing_
        h=.04;
        v2=v-.1
        v2=v2-h;
        uicontrol('parent',fig,'string','just move:', 'units','normal',...
            'position',[0.9 v2 0.08 h/2],'enable','inact',...
            'backgroundcolor',[0.8 0.8 0.8],...
            'style','text');
        v2=v2-h-sp;
        InitParam(me,'speed','value',100,...
            'ui','edit','units','normal','pos',[0.9 v2 0.04 h]);
        v2=v2-h-sp;
        InitParam(me,'travel','value',100,...
            'ui','edit','units','normal','pos',[0.9 v2 0.04 h]);
        h=.07;
        v2=v2-h-sp;
        uicontrol('parent',fig,'string','move','tag','move','fontname','Arial',...
            'fontsize',12,'fontweight','bold',...
            'units','normal','position',[0.9 v2 0.1 h],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        
        
        % message box
        h=.1;
        v=v-h-sp;
        uicontrol('parent',fig,'tag','message','style','text',...
            'enable','inact','horiz','left','units','normal', ...
            'pos',[0.8 v .2 h]);
        
        Message(me, 'message box')
        
        s=open_MP285_connection;
        [x,y,z]=get_current_position(s);
        set(MP285posH,'string',sprintf('%.2f x\n%.2f y\n%.2f z\ntravel 0', x/25, y/25, z/25));
        
        %create grid checkbox
        n=2;
        InitParam(me,'Grid','string','Grid','value',0,'ui','togglebutton','pref',0,'label',0,'units','normal',...
            'backgroundcolor',[0.2 0.3 0.8],'foregroundcolor',[1 1 1],'fontweight','bold','pos',[0.45 0.002 0.15 0.08]);
        if getparam(me,'grid')
            grid on;
        end
        
        %create autoscale checkbox
        n=1;
        InitParam(me,'Autoscale','string','Autoscale','value',1,'ui','togglebutton','pref',0,'label',0,'units','normal',...
            'backgroundcolor',[0 1 1],'foregroundcolor',[0 0 1],'fontname','Arial','fontsize',12,'fontweight','bold','pos',[0.45 0.082 0.15 0.123]);
        
        %do not create whitenoise checkbox
        %InitParam(me,'Whitenoise','string','Whitenoise','value',0,'ui','togglebutton','pref',0,'label',0,'units','normal','enable','off',...
        %    'backgroundcolor',[0.2 0.3 0.8],'foregroundcolor',[1 1 1],'fontweight','bold','pos',[0.60 0.002 0.15 0.08]);
        
        % Now get all channels we need
        % NOTE: related channels should correspond to the same indices in
        % related variables, ie DataChannels(1), ModeChannels(1),
        % GainChannels(1), CommandChannels(1), etc.
        % get all the data channels
        dataChannels=GetChannel('ai','datachannel-patch');
        InitParam(me,'DataChannels','value',[dataChannels.number]);
        InitParam(me,'DataChannelNames','value',{dataChannels.name});
        dataChannelColors={dataChannels.color};
        InitParam(me,'DataChannelColors','value',dataChannelColors);
        nChannels=length(dataChannels);
        InitParam(me,'nChannels','value',nChannels);
        modeChannels=GetChannel('ai','modechannel');
        InitParam(me,'ModeChannels','value',[modeChannels.number]);
        gainChannels=GetChannel('ai','gainchannel');
        InitParam(me,'GainChannels','value',[gainChannels.number]);
        
        % get the command channels
        commandChannels=GetChannel('ao','commandchannel');
        InitParam(me,'CommandChannels','value',[commandChannels.number]);
        
        % Initialize some DAQ objects for freely running mode.
        oldai=daqfind('type','Analog Input','tag',me);
        if isempty(oldai)
            ai2=InitDAQAI;
        else
            ai2=oldai{1};
        end
        set(ai2,'tag',me);
        
        oldao=daqfind('type','Analog Output','tag',me);
        if isempty(oldao)
            ao2=InitDAQAO;
        else
            ao2=oldao{1};
        end
        set(ao2,'tag',me);
        
        olddio=daqfind('type','Digital IO','tag',me);
        if isempty(olddio)
            dio2=InitDAQDIO;
        else
            dio2=olddio{1};
        end
        set(dio2,'tag',me);
        
        % Axes
        curaxes=axes('units','normal','position',[0.05 0.3 0.7 0.6]);
        ylabel('Response');
        xlabel('Time');
        
        fig = findobj('type','figure','tag',me);
        h=plot(0,0);
        if getparam(me,'grid')
            grid on;
        end
        
        curline=zeros(1,nChannels);
        hold on;
        for channel=1:nChannels
            curline(channel)=line([0 1],[0 0],'Color',dataChannelColors{channel},'Parent',curaxes,'Visible','off','LineWidth',1);
            set(curline(channel),'ButtonDownFcn',[me '(''axesbuttondown'');']);
        end
        set(curline(1),'Visible','on');
        
        % create the run button based on number of channels
        if nChannels>1
            RunningH = uicontrol('style','togglebutton','string','Run',...
                'callback',[me ';'],'tag','run','fontname','Arial',...
                'fontsize',14,'fontweight','bold','backgroundcolor',[0 1 0],...
                'units','normal','pos',[0.1 0.082 0.35 0.123]);
            channelButtons=zeros(1,nChannels);
            bSize=0.35/nChannels;
            for channel=1:nChannels
                bPos=0.1+(channel-1)*bSize;
                channelButtons(channel)=uicontrol('Style','togglebutton','units','normal','tag','channelbutton',...
                    'value',0,'backgroundcolor',dataChannelColors{channel},'pos',[bPos 0.205 bSize 0.04],...
                    'ForegroundColor',[1 1 1],'CallBack',[me '(''channelbutton'');'],'FontWeight','bold');
            end
            set(channelButtons(1),'value',1,'String','On');
            for channel=1:nChannels
                cButtons=channelButtons;
                cButtons(channel)=[];
                set(channelButtons(channel),'userdata',cButtons);
            end
            InitParam(me,'ChannelButtons','value',channelButtons);
        else
            RunningH = uicontrol('style','togglebutton','string','Run',...
                'callback',[me ';'],'tag','run','fontname','Arial',...
                'fontsize',14,'fontweight','bold','backgroundcolor',[0 1 0],...
                'units','normal','pos',[0.1 0.082 0.35 0.123]);
        end
        
        set(curaxes,'ButtonDownFcn',[me '(''axesbuttondown'');']);
        
        
    case 'reset'
        Mode=GetParam('patchpreprocess','mode');
        
        commandChannels=GetParam(me,'CommandChannels');
        commandChannels=commandChannels(:)';    % make it a row vector
        AOSampleRate=AO('getsamplerate')/1000;
        
        for oneChannel=1:length(commandChannels)
            switch Mode{oneChannel}
                case {'Track','V-Clamp'}
                    % Because 20 mV/V, divide by 20.
                    ph=GetParam(me,'v_height');
                    pw=GetParam(me,'v_width');
                    phScaled=ph/20;
                case {'I=0','I-Clamp Normal','I-Clamp Fast'}
                    % Because 2/beta nA/V = 2000/beta pA/V, scale.
                    % Assumes beta = 1. Figure out what I should do.
                    ph=GetParam(me,'i_height');
                    pw=GetParam(me,'i_width');
                    phScaled=ph/(2000);
            end
            
            % Create and send step waveform.
            %     CommandCh=GetChannel('ao','commandchannel');
            %     CommandCh=CommandCh.number;
            
            % 20041124 - isn't needed anymore
            %         CommandCh=daqfind(exper.ao.daq, 'hwchannel', commandChannels(oneChannel));
            %         CommandCh=CommandCh{1}.Index;
            %         samples=zeros(size(exper.ao.data{1}(:,CommandCh)));
            %         pulseinds=ceil([0.5 1.5]*pw*AOSampleRate);
            %         samples(pulseinds(1):pulseinds(2))=phScaled;
            %         AO('setchandata',CommandCh,samples);
        end
        
    case 'close'
        if exist('ao2','var') & ~isempty(ao2)
            stop(ao2);
            delete(ao2);
        end
        if exist('ai2','var') & ~isempty(ai2)
            stop(ai2);
            delete(ai2);
        end
        if exist('dio2','var') & ~isempty(dio2)       %modified by Lung-Hao Tai
            stop(dio2);
            delete(dio2);
        end
        SendEvent('esealtestoff',[],me,'all');
        clear ai2 ao2 dio2 DataCh GainCh ModeCh samples ph pw fig curaxes curline RunningH RsH RtH
        
    case 'getready'
        fig=findobj('type','figure','name',me);
        set(findobj('type','uicontrol','tag','run','parent',fig),'enable','off');
        set(findobj('type','uicontrol','tag','channelbutton','parent',fig),'enable','off');
        
    case 'trialend'
        fig=findobj('type','figure','name',me);
        set(findobj('type','uicontrol','tag','run','parent',fig),'enable','on');
        set(findobj('type','uicontrol','tag','channelbutton','parent',fig),'enable','on');
        
        % Now for its own modes.
    case 'start'
        %start autopatch robot run
        setparam(me, 'abort', 0);
        SendEvent('esealteston',[],me,'all');
        %set(RunningH,'backgroundcolor',[1 0 0]);
        set(RunningH,'enable','off');
        moveax=getparam(me, 'axis');
        stepsize=getparam(me, 'stepsize'); %in microns
        create_step_waveform
        first_run
        set(ai2, 'StopFcn', [])
        %         pause(5)
        baselineR=sealtest(getparam(me, 'npulses'));
        set(baselineRH,'String',baselineR);
        deltaR=0;
        R=baselineR;
        [startpos(1),startpos(2),startpos(3)]=get_current_position(s); %in msteps
        travel=0;
        stepnum=1;
        got_cell=0;
        while ~got_cell
            stepnum=stepnum+1;
            %move step loop
            if getparam(me, 'abort')
                Message(me, 'robot run aborted', 'append')
                set(deltaRH,'String','');
                break
            end
            if travel/25>getparam(me, 'maxtravel')
                Message(me, 'max travel reached. stopping robot.', 'append')
                break
            end
            %move
            [x,y,z]=get_current_position(s); %in msteps
            switch moveax
                case 1
                    mx=x+25*stepsize;my=y;mz=z;
                case 2
                    mx=x;my=y+25*stepsize;mz=z;
                case 3
                    mx=x;my=y;mz=z+25*stepsize;
            end
            Message(me, ['robot step ', int2str(stepnum)])
            fprintf(s, '%s', 'm');
            fwrite(s, [mx my mz], 'int32');
            fprintf(s,'');
            %wait for "move complete' reply
            tic
            while s.bytesavailable==0
                pause(.01)
                if toc>10
                    fprintf('\ntime out')
                    break
                end
            end
            fgets(s); %read CR reply
            
            Rt=sealtest(getparam(me, 'npulses'));
            R(stepnum)=Rt;
            deltaR(stepnum)=Rt-R(stepnum-1);
            set(deltaRH,'String',sprintf('%.2f', deltaR(stepnum)));
            if stepnum>2
                set(baselineRH,'String',sprintf('%.2f\n%.2f', baselineR, deltaR(stepnum-1)));
            end
            %             fprintf('\n')
            %             fprintf('\t%.1f', R)
            %             fprintf('\n')
            %             fprintf('\t%.1f', deltaR)
            
            % this is the neuron-hunting algorithm
            if stepnum>3
                if deltaR(stepnum)>0 & ...
                        deltaR(stepnum-1)>0 & ...
                        deltaR(stepnum-2)>0 & ...
                        deltaR(stepnum-2)+deltaR(stepnum-1)+deltaR(stepnum)>getparam(me, 'dRthresh')
                    got_cell=1;
                end
            end
            
            [x,y,z]=get_current_position(s);
            travel=sum([x,y,z]-startpos); %distance travelled
            %this assumes travel along only a single axis
            
            
            % Display parameters
            set(RsH,'String',sprintf('%.2f', Rs));
            set(RtH,'string',sprintf('%.2f', Rt));
            set(MP285posH,'string',sprintf('%.2f x\n%.2f y\n%.2f z\ntravel %.2f', x/25, y/25, z/25, travel/25));
            
        end %step loop
        
        if got_cell %i.e. if we didn't get here from a break
            beep
            Message(me, 'You have a cell', 'error')
        end
        SendEvent('esealtestoff',[],me,'all');
        set(RunningH,'enable','on');
        set(RunningH,'string','Run');
        set(RunningH,'backgroundcolor',[0 1 0]);
        
        
    case 'stop'
        %abort autopatch robot run
        %set(RunningH,'backgroundcolor',[1 0 0]);
        SetParam(me, 'abort', 1);
        Message(me, 'aborting...')
        pause(.1)
        if exist('ao2','var') & ~isempty(ao2)
            stop(ao2);
        end
        if exist('ai2','var') & ~isempty(ai2)
            stop(ai2);
        end
        ai('reset');
        ao('really_reset');
        
        SendEvent('esealtestoff',[],me,'all');
        set(RunningH,'enable','on');
        set(RunningH,'string','Run');
        set(RunningH,'backgroundcolor',[0 1 0]);
        
        set(deltaRH,'String','');
        set(baselineRH,'String','');
        
        fprintf(s, 'r'); %reset MP285
        fprintf(s, 'n'); %refresh MP285 VFD
        %         fclose(s)
        %         delete(s)
        %         clear s
        
    case 'move'
        %just move feature: moves MP285 a fixed travel at a fixed speed
        %no resistance checking or cell-getting
        %this is for pulling out slowly, or perhaps advancing a tungsten
        %electrode
        
        setparam(me, 'abort', 0);
        moveax=getparam(me, 'axis');
        speed=getparam(me, 'speed');
        travel=getparam(me, 'travel');
        moveH=findobj('tag', 'move', 'type', 'uicontrol');
        set(moveH, 'enable', 'off')
        set_velocity(s, speed);
        [x,y,z]=get_current_position(s); %in msteps
        switch moveax
            case 1
                mx=x+25*travel;my=y;mz=z;
            case 2
                mx=x;my=y+25*travel;mz=z;
            case 3
                mx=x;my=y;mz=z+25*travel;
        end
        Message(me, ['starting move ', int2str(travel), ' microns'])
        fprintf(s, '%s', 'm');
        fwrite(s, [mx my mz], 'int32');
        fprintf(s,'');
        
        expected_duration=abs(travel/speed);
        Message(me, ['expected duration: ', int2str(round(expected_duration)), 's'], 'append')
        %wait for "move complete' reply
        tic
        timeout=0;
        while s.bytesavailable==0
            pause(.01)
            if toc> max(10, 2*expected_duration)
                Message(me, 'time out', 'append')
                timeout=1;
                break
            end
        end
        fgets(s); %read CR reply
        if ~timeout
            Message(me, ['move ', int2str(travel), ' completed'], 'append')
            set(moveH, 'enable', 'on')
        end
        % Display new location
        [x,y,z]=get_current_position(s);
        set(MP285posH,'string',sprintf('%.2f x\n%.2f y\n%.2f z', x/25, y/25, z/25));
        
    case 'run'
        % Set the button to red or green to indicate whether running.
        %     RunningH=findobj('type','uicontrol','tag','run');
        
        Running=get(RunningH,'value');
        if Running
            %First Run
            create_step_waveform
            first_run
            
        else % ~Running
            set(RunningH,'enable','off');
            set(RunningH,'string','Run');
            set(RunningH,'backgroundcolor',[0 1 0]);
            
            pause(.1)
            if exist('ao2','var') & ~isempty(ao2)
                stop(ao2);
            end
            if exist('ai2','var') & ~isempty(ai2)
                stop(ai2);
            end
            ai('reset');
            ao('really_reset');
            
            SendEvent('esealtestoff',[],me,'all');
            set(RunningH,'enable','on');
        end
        
    case 'freerun'
        
        if (ai2.SamplesAvailable>0) % we might have some data available
            
            wait(ai2,5);   %            wait(ai2,1);
            wait(ao2,5);   %            wait(ao2,1);
            
            [data,time]=getdata(ai2);
            really_running=get(RunningH,'value');
            if really_running
                send_step_waveform
            end
            
            [ScaledData, activeChannel] = scale_data; %these are all nested functions
            get_mode
            display_trace
            Rt=measure_resistance;
            % Display Rs
            set(RsH,'String',Rs);
            set(RtH,'string',Rt);
            
            ignoreMP285H=findobj('tag', 'ignoreMP285', 'type', 'uicontrol');
            ignoreMP285=get(ignoreMP285H,'value');
            if ~ignoreMP285
                [x,y,z]=get_current_position(s);
                
                %Display current position
                set(MP285posH,'string',sprintf('%.2f x\n%.2f y\n%.2f z', x/25, y/25, z/25));
            end
        end %% if (ai2.SamplesAvailable>0) % we might have some data available
        
        
        
        % Parameter callbacks.
        
    case 'autoscale'
        if  GetParam(me,'autoscale')
            SetParamUI(me,'Autoscale','backgroundcolor',[0 1 1],'foregroundcolor',[0 0 1]);
            SetParam(me,'zoom',0);
            set(curaxes, 'tag', 'first-autoscale');
        else
            SetParamUI(me,'Autoscale','backgroundcolor',[0.2 0.3 0.8],'foregroundcolor',[1 1 1]);
            SetParam(me,'zoom',1);
        end
        
    case 'grid'
        if  GetParam(me,'grid')
            SetParamUI(me,'Grid','backgroundcolor',[0 1 1],'foregroundcolor',[0 0 1]);
            grid on;
        else
            SetParamUI(me,'Grid','backgroundcolor',[0.2 0.3 0.8],'foregroundcolor',[1 1 1]);
            grid off;
        end
        
    case 'zoomin'
        ylim=get(curaxes,'YLim');
        set(curaxes,'YLim',0.8*ylim);
        
    case 'zoomout'
        ylim=get(curaxes,'YLim');
        set(curaxes,'YLim',1.2*ylim);
        
    case 'center'
        visible=get(curline,'Visible');
        visible=find(strcmpi(visible,'on'));
        if ~isempty(visible)
            ydata=get(curline(visible),'YData');     % gets y-range of values for all lines
            if iscell(ydata)        % we have more lines
                ydata=[ydata{:}];
            end
            ylim=get(curaxes,'YLim');
            center=mean(ydata);
            range=(ylim(2)-ylim(1))/2;
            set(curaxes,'YLim',[center-range center+range]);
        end
        
    case 'axesbuttondown'
        curpoint=get(curaxes,'CurrentPoint');
        set(fig,'WindowButtonUpFcn',[me '(''axesbuttonup'');']);
        set(fig,'WindowButtonMotionFcn',[me '(''axesbuttonmotion'');']);
        
    case 'axesbuttonmotion'
        newpoint=get(curaxes,'CurrentPoint');
        delta=curpoint-newpoint;
        delta=delta(2,2);       % we're interested only in y-axis changes
        ylim=get(curaxes,'YLim');
        curpoint=newpoint;
        set(curaxes,'YLim',[ylim(1)+delta ylim(2)+delta]);
        
    case 'axesbuttonup'
        set(fig,'WindowButtonMotionFcn','');
        set(fig,'WindowButtonUpFcn','');
        
    case 'channelbutton'
        activeButton=gco;
        channelButtons=GetParam(me,'ChannelButtons');
        set(get(activeButton,'UserData'),'Value',0,'String','');
        set(activeButton,'Value',1,'String','On');
        values=get(channelButtons,'Value');
        set(curline(logical([values{:}])),'visible','on');
        set(curline(logical(1-[values{:}])),'visible','off');
        
end


    function  [ScaledData, activeChannel] = scale_data %nested function
        %scales data by axopatch gain setting
        
        % find out which channel we're plotting
        if GetParam(me,'nChannels')>1
            channelButtons=get(GetParam(me,'ChannelButtons'),'Value');
            activeChannel=find([channelButtons{:}]);
            activeChannel=activeChannel(1);         % just in case we just switched the channels
        else
            activeChannel=1;
        end
        
        % Scale data.
        RawData=data(:,DataCh(activeChannel));
        GainData=data(:,GainCh(activeChannel));
        ScaledData=1000*RawData./AxonGain(GainData);
    end

    function get_mode %nested function
        ModeData=data(:,ModeCh(activeChannel));
        Mode=AxonMode(ModeData);
        if iscell(Mode)
            Mode=Mode{end};
        end
    end

    function display_trace %nested function
        set(curline(activeChannel),'XData',time,'YData',ScaledData);
        % autoscaling now handled here
        % scale axes to nearest power of two
        if GetParam(me,'autoscale')
            axlims=[0 length(ScaledData)/GetParam('ai','samplerate') get(findobj(fig,'type','axes'),'ylim')];
            if isempty(get(findobj(fig,'type','axes'),'ylim'))
                axlims=[axlims(1:2) 0 1];
            end
            if ( max(abs(ScaledData)) == 0 ) | (isempty(axlims(4))) | ( axlims(4) == NaN ) | ...
                    ( axlims(4) == Inf ) | ( axlims(4) == 0 )
                axlims(4)=1;
            end
            
            % if this is the first time autoscale runs
            if  strcmp(get(curaxes, 'tag'), 'first-autoscale');
                set(curaxes, 'tag', '');
                max2base = abs(max(ScaledData));
                min2base = abs(min(ScaledData));
                bs2maxlm = 2^ceil(log2( max2base ));
                bs2minlm = 2^ceil(log2( min2base ));
                axlims(4)=   bs2maxlm + bs2minlm/8 ;
                axlims(3)= - bs2minlm - bs2maxlm/8  ;
                
                % if the range of the trace exceeds the current axis
            elseif max(ScaledData)> axlims(4) | min(ScaledData) < axlims(3)
                max2base = abs(max(ScaledData));
                min2base = abs(min(ScaledData));
                bs2maxlm = 2^ceil(log2( max2base ));
                bs2minlm = 2^ceil(log2( min2base ));
                axlims(4)=   bs2maxlm + bs2minlm/8 ;
                axlims(3)= - bs2minlm - bs2maxlm/8 ;
                
                % if the range of the trace is smaller than 1 fourth (2^-2 = 1/4) of the axis
            elseif (max(ScaledData)-min(ScaledData))*4 < axlims(4)-axlims(3) & ...
                    min([abs(max(ScaledData)),abs(min(ScaledData))])*2 < max(ScaledData)-min(ScaledData)
                max2base = abs(max(ScaledData));
                min2base = abs(min(ScaledData));
                bs2maxlm = 2^ceil(log2( max2base )-1);
                bs2minlm = 2^ceil(log2( min2base )-1);
                axlims(4)=   bs2maxlm + bs2minlm/8 ;
                axlims(3)= - bs2minlm - bs2maxlm/8 ;
            end
            set(findobj(fig,'type','axes'),'xlim',axlims(1:2));
            set(findobj(fig,'type','axes'),'ylim',axlims(3:4));
        end
        
        fig = findobj('type','figure','tag',me);
        curaxes = findobj(fig,'type','axes');
        ylh=get(curaxes, 'ylabel');
        xlh=get(curaxes, 'xlabel');
        set(xlh, 'string', 'Time (s)');
        
        switch Mode
            case {'Track','V-Clamp'}
                set(ylh, 'string', 'Current (pA)');
            case {'I=0','I-Clamp Normal','I-Clamp Fast'}
                set(ylh, 'string', 'Voltage (mV)');
        end
    end

    function Rt=measure_resistance %nested function
        baseline_region=find(time<(0.45*pw(activeChannel)/1000));
        Baseline=mean(ScaledData(baseline_region));
        
        switch Mode
            case {'Track','V-Clamp'}
                phTemp=GetParam(me,'v_height');
                pwTemp=GetParam(me,'v_width');
                % Look for peak in +/- 1 ms around pulse onset.
                peak_region = find( ( time > ((0.5*pwTemp - 1) * (1e-3)) ) & ...
                    ( time < ((0.5*pwTemp + 1) * (1e-3)) ) );
                Peak = sign(phTemp) * max( sign(phTemp) * ScaledData( peak_region ) );
                Peak = Peak - Baseline;
                % Look for tail in last 1 ms of pulse.
                tail_region = find( ( time > ((1.5*pwTemp - 1) * 1e-3) ) & ...
                    ( time < (1.5*pwTemp * 1e-3) ) );
                Tail=mean(ScaledData(tail_region));
                Tail = Tail - Baseline;
                % ph in mV, current in pA and resistance in MOhm.
                if (Peak~=0) & (Tail~=0)
                    Rs=(phTemp * 1e-3)/( Peak * 1e-12) / (1e6);
                    Rt=(phTemp * 1e-3)/( Tail * 1e-12) / (1e6);
                    Rin=Rt-Rs;
                else
                    Rs=inf;Rt=inf;Rin=inf;
                end
                
            case {'I=0','I-Clamp Normal','I-Clamp Fast'}
                phTemp=GetParam(me,'i_height');
                pwTemp=GetParam(me,'i_width');
                % Find time index that pulse started and look +/- 1 ms for steepness.
                start_region = find( ( time > ((0.5*pwTemp - 1) * (1e-3)) ) & ...
                    ( time < ((0.5*pwTemp + 1) * (1e-3)) ) );
                [dum,onset_index]=max( sign(phTemp)*diff( ScaledData( start_region ) ) );
                Onset=ScaledData( onset_index + 1 );
                Onset = Onset - Baseline;
                % Look for peak charging in +/- 1 ms around pulse termination.
                peak_region = find( ( time > ((1.5*pwTemp - 1) * (1e-3)) ) & ...
                    ( time < ((1.5*pwTemp + 1) * (1e-3)) ) );
                Peak = sign(phTemp) * max( sign(phTemp) * ScaledData( peak_region ) );
                Peak = Peak - Baseline;
                if phTemp~=0
                    Rs=( Onset * (1e-3 ) ) / ( phTemp * (1e-12) ) / (1e6);
                    Rt=( Peak * (1e-3) ) / ( phTemp * (1e-12) ) / (1e6);
                    Rin=Rt-Rs;
                else
                    Rs=inf;Rt=inf;Rin=inf;
                end
        end
    end

    function first_run
        vel=GetParam(me, 'velocity');
        set_velocity(s, vel);
        
        eval([ me '(''reset'');' ]);
        set(RunningH,'backgroundcolor',[1 0 0]);
        SendEvent('esealteston',[],me,'all');
        %         if ~isempty(gcbo) & (gcbo==RunningH) ...
        % This run is the first one. Set up some parameters.
        set(RunningH,'string','Running...');
        % Stop other modules.
        ai('pause');
        ao('pause');
        
        ai2.Channel(:).InputRange=[-10 10];
        ai2.Channel(:).SensorRange=[-10 10];
        ai2.Channel(:).UnitsRange=[-10 10];
        %             ai2.TriggerType = 'HwDigital';
        set(ai2,'TriggerType','HwDigital');
        % Copy the sample rate from the other module.
        %             ai2.SampleRate = GetParam('ai','samplerate');
        set(ai2,'SampleRate',GetParam('ai','samplerate'));
        % Do not let ai use interrupts if DMA is possible.
        % Get possible transfer modes.
        possibs=set(ai2,'TransferMode');
        % Set transfer mode to DualDMA if possible and SingleDMA as alternate.
        if sum(strcmp(possibs,'DualDMA'))
            %                 ai2.TransferMode='DualDMA';
            set(ai2,'TransferMode','DualDMA');
        elseif sum(strcmp(possibs,'SingleDMA'))
            %                 ai2.TransferMode='SingleDMA';
            set(ai2,'TransferMode','SingleDMA');
        end
        % Call this file at the end.
        set(ai2,'StopFcn',[me]); %I think this is how sealtest keeps freerunning
        ao2.Channel(:).OutputRange=[-10 10];
        ao2.Channel(:).UnitsRange=[-10 10];
        % Set trigger.
        set(ao2,'TriggerType','HwDigital');
        set(ao2,'SampleRate',GetParam('ao','samplerate'));
        
        set(ai2,'TriggerType','Immediate'); % find out gain and mode of Axopatch
        set(ai2,'TriggerType','HwDigital');
        
        % create_step_waveform
        
        % Send step waveform.
        putdata(ao2,samples);
        % Trigger.
        start(ai2);
        start(ao2);
        % Flip dio bit to trigger.
        putvalue(dio2,1);
        pause(.02)
        putvalue(dio2,0);
    end

    function create_step_waveform %nested function
        dataChannels=GetParam(me,'DataChannels');
        gainChannels=GetParam(me,'GainChannels');
        modeChannels=GetParam(me,'ModeChannels');
        nChannels=GetParam(me,'nChannels');
        
        Samp=getsample(ai2);
        
        pw=zeros(1,nChannels);
        ph=zeros(1,nChannels);
        phScaled=zeros(1,nChannels);
        DataCh=zeros(1,nChannels);
        GainCh=zeros(1,nChannels);
        ModeCh=zeros(1,nChannels);
        
        for channel=1:nChannels
            DCh=daqfind(ai2,'HwChannel',dataChannels(channel));
            DataCh(channel)=DCh{1}.Index;
            GCh=daqfind(ai2,'HwChannel',gainChannels(channel));
            GainCh(channel)=GCh{1}.Index;
            MCh=daqfind(ai2,'HwChannel',modeChannels(channel));
            ModeCh(channel)=MCh{1}.Index;
            
            Mode=AxonMode(Samp(ModeCh(channel)));
            
            % Scale for the amplification.
            if iscell(Mode)
                Mode=Mode{end};
            end
            switch Mode
                case {'Track','V-Clamp'}
                    ph(channel)=GetParam(me,'v_height');
                    pw(channel)=GetParam(me,'v_width');
                    % Because 20 mV/V, divide by 20.
                    phScaled(channel)=ph(channel)/20;
                case {'I=0','I-Clamp Normal','I-Clamp Fast'}
                    ph(channel)=GetParam(me,'i_height');
                    pw(channel)=GetParam(me,'i_width');
                    % Because 2/beta nA/V = 2000/beta pA/V, get gain and scale.
                    % Assumes beta = 1. Figure out what I should do.
                    phScaled(channel)=ph(channel)/(2000);
            end
        end
        
        pwMax=max(pw);
        sampleLength=2*pwMax;   % sample length in ms
        ao2SampleRate=ao2.SampleRate/1000; %for ms
        ai2SampleRate=ai2.SampleRate/1000;
        samples=zeros(ceil(sampleLength*ao2SampleRate),nChannels);
        set(ai2,'SamplesPerTrigger',ceil(sampleLength*ai2SampleRate));
        for channel=1:nChannels
            pulseinds=ceil([0.5 1.5]*pw(channel)*ao2SampleRate);
            samples(pulseinds(1):pulseinds(2),channel)=phScaled(channel);
        end
    end

    function send_step_waveform %nested function
        putdata(ao2,samples);
        % Trigger.
        start(ai2);
        start(ao2);
        
        % Flip dio bit to trigger.
        putvalue(dio2,1);
        pause(.02)
        putvalue(dio2,0);
    end

    function Rt=sealtest(npulses); %nested function
        % runs npulses of sealtest and returns mean Rs
        for i=1:npulses
            wait(ai2,5);   %            wait(ai2,1);
            wait(ao2,5);   %            wait(ao2,1);
            [data,time]=getdata(ai2);
            send_step_waveform
            [ScaledData, activeChannel] = scale_data; %these are all nested functions
            get_mode
            display_trace
            Rt(i)=measure_resistance;
        end
        Rt=mean(Rt);
    end

end %main function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newao=InitDAQAO
global exper pref

stopandstartao=isfield(exper,'ao') & isfield(exper.ao,'daq') & isobject(exper.ao.daq) & ...
    strcmp(get(exper.ao.daq,'Running'),'On');
% If the 'main' AO is running, first stop it...
if stopandstartao
    stop(exper.ao.daq);
end

CommandCh=GetParam(me,'CommandChannels');

boardn=daqhwinfo('nidaq', 'BoardNames');
v=ver('daq'); %daq toolbox version number
%mw 08.28.08  new version of matlab refers to devices differently
if str2num(v.Version) >= 2.12
    newao=analogoutput('nidaq','Dev1'); %mw 12.16.05
else %assume old version of matlab
    switch boardn{1} %mw 04.18.06
        case 'PCI-6052E'
            newao=analogoutput('nidaq',1);
        case 'PCI-6289'
            newao=analogoutput('nidaq','Dev1'); %mw 12.16.05
    end
end

addchannel(newao,[CommandCh]);
newao.Channel(:).OutputRange=[-10 10];
newao.Channel(:).UnitsRange=[-10 10];
% Set trigger.
newao.TriggerType = 'HwDigital'; %%mw 12.16.05
% Set sample rate.
newao.SampleRate = GetParam('ao','samplerate');

% ...and then refresh it
if stopandstartao
    ao('putdata');
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newai=InitDAQAI
global exper pref

stopandstartai=isfield(exper,'ai') & isfield(exper.ai,'daq') & isobject(exper.ai.daq) & ...
    strcmp(get(exper.ai.daq,'Running'),'On');
if stopandstartai
    stop(exper.ai.daq);
end

RawCh=GetParam(me,'DataChannels');
GainCh=GetParam(me,'GainChannels');
ModeCh=GetParam(me,'ModeChannels');
% Create ai.
boardn=daqhwinfo('nidaq', 'BoardNames');

v=ver('daq'); %daq toolbox version number
%mw 08.28.08  new version of matlab refers to devices differently
if str2num(v.Version) >= 2.12
    newai=analoginput('nidaq','Dev1');
else %assume old version of matlab
    switch boardn{1} %mw 04.18.06
        case 'PCI-6052E'
            newai=analoginput('nidaq',1);
        case 'PCI-6289'
            newai=analoginput('nidaq','Dev1'); %mw 12.16.05
    end
end

% NOTE: originally sealtest used differential inputs for nidaq, which,
% in our case meant up to 8 channels. With single ended inputs, as in
% case of AI, we can use 16 channels
%get the type of input types the board likes
% 	inputs=propinfo(newai,'InputType');
%if its possible to set the InputType to SingleEnded, then do it
% 2004/11/10 - foma - I talked to Mike Wehr, and decided to switch to
% differential
% We're going to use differential inputs
% see also open_ai above
% 	if ~isempty(find(strcmpi(inputs.ConstraintValue, 'SingleEnded')))
% 		ai.InputType='SingleEnded';
% 	end

addchannel(newai,[RawCh GainCh ModeCh]);
newai.Channel(:).InputRange=[-10 10];
newai.Channel(:).SensorRange=[-10 10];
newai.Channel(:).UnitsRange=[-10 10];
% Set trigger.
newai.TriggerType='HwDigital';
% Copy the sample rate from the other module.
newai.SampleRate=GetParam('ai','samplerate');
% Set length to be twice the pulse length.
newai.SamplesPerTrigger=ceil(newai.SampleRate);
% Call this file at the end.

if stopandstartai
    start(exper.ai.daq);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newdio=InitDAQDIO
boardn=daqhwinfo('nidaq', 'BoardNames');

v=ver('daq'); %daq toolbox version number
%mw 08.28.08  new version of matlab refers to devices differently
if str2num(v.Version) >= 2.12
    newdio=digitalio('nidaq','Dev1');
else %assume old version of matlab
    switch boardn{1} %mw 04.18.06
        case 'PCI-6052E'
            newdio=digitalio('nidaq',1);
        case 'PCI-6289'
            newdio=digitalio('nidaq','Dev1'); %mw 12.16.05
    end
end
trigchan=GetParam('dio','trigchan');
if ischar(trigchan)
    trigchan=str2double(trigchan);
end
addline(newdio,trigchan,'out');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Mode = AxonMode(Readings)
% Discover the operating mode of the Axon 200B.
% Modes
% 1		Track
% 2		V-Clamp
% 3		I=0
% 4		I-Clamp Normal
% 6		I-Clamp Fast

% Preserve input matrix size for output later.
sizeout=size(Readings);

PossibleReadings=[1 2 3 4 6];
PossibleModes={'I-Clamp Fast','I-Clamp Normal','I=0','Track','V-Clamp'};

% To get look up indices, make ndgrid of readings and possible readings.
% The find minimum differences and use them to index the possible gains.
[Readings,PossibleReadings]=ndgrid(Readings,PossibleReadings);
[dum,inds]=min(abs(Readings-PossibleReadings),[],2);

% If all modes/indices were the same, return a single string.
if (prod(size(unique(inds)))==1)
    Mode=PossibleModes(inds(1));
else
    % Otherwise, reshape to match the input matrix shape.
    Mode=PossibleModes(inds);
    Mode=reshape(Mode,sizeout);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Gain=AxonGain(Readings)
% Discover the gain setting of the Axon 200B.
%	Telegraph Reading (V):		0.5		1	1.5	2.0	2.5	3.0	3.5	4.0	4.5	5.0	5.5	6.0	6.5
%	Gain (mV/mV) or (mV/pA):	0.05	0.1	0.2	0.5	1	2	5	10	20	50	100	200	500

% Preserve input matrix size for output later.
sizeout=size(Readings);

% Make matrices of the possible telegraph readings and corresponding gains.
PossibleReadings=[0.5:0.5:6.5];
PossibleGains=[0.05 0.1 0.2 0.5 1 2 5 10 20 50 100 200 500];

% To get look up indices, make ndgrid of readings and possible readings.
% The find minimum differences and use them to index the possible gains.
[Readings,PossibleReadings]=ndgrid(Readings,PossibleReadings);
[dum,inds]=min(abs(Readings-PossibleReadings),[],2);
Gain=PossibleGains(inds);

% Reshape to match the input matrix shape.
Gain=reshape(Gain,sizeout);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return the name of this file/module.
function out=me
out=lower(mfilename);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s=open_MP285_connection
close_all_serial_ports
s = serial('COM1');
set(s,'BaudRate',9600);
set(s, 'databits', 8);
set(s, 'parity', 'none');
set(s, 'stopbits', 1);
set(s, 'terminator', 'CR');
set(s, 'timeout', .5);
fopen(s);

%I need some way to check the connection. Will use get_current_position for
%now.
clear_read_buffer(s)
fprintf(s,'c');
tic
while s.bytesavailable==0 %wait for reply
    pause(.01)
    if toc>10
        Message(me, 'no answer from MP285!', 'error')
        break
    end
end

end

function close_all_serial_ports
%if serial port got left open, this finds and closes it
ports=instrfind;
if ~isempty(ports)
    fclose(ports)
end
end

function clear_read_buffer(s)
while s.bytesavailable>0
    tline=fgets(s); %read CR
end
end

function set_velocity(s, vel)
commandval=bitor(vel, 2^15); %to indicate fine resolution
% commandval=bitor(vel, 0); %to indicate coarse

fprintf(s, '%s', 'V');
fwrite(s, commandval, 'uint16');
fprintf(s,'');

while s.bytesavailable>0
    tline=fgets(s); %read CR
end
Message(me, ['set velocity ' int2str(round(vel))], 'append')
end

function [x,y,z]=get_current_position(s)
%         returns current xyz position of MP285 in microsteps
clear_read_buffer(s)
fprintf(s,'c');
tic
while s.bytesavailable==0 %wait for reply
    pause(.001)
    if toc>2
        Message(me, 'gcp time out', 'append')
        break
    end
end

x = fread(s, 1,'int32');
y = fread(s, 1,'int32');
z = fread(s, 1,'int32');
fgets(s); %read CR
end


