function MP285robot(varargin)
%this module controls the MP285 over the serial port.
% unlike the autopatcher, here we only move the manipulator and make
% no attempt to read resistance or find a cell.
%
%There are two modes: Stepper and Single Move.
%In Stepper mode, you set a stepsize (in microns) and a number of steps,
%and the amount of time (in seconds) to pause at each step. In this way you
%can advance the electrode at a known rate. The robot will halt after
%numsteps or if it reaches maxtravel. Stop should halt it immediately.
%Stepsize can be negative to withdraw the electrode, although sometimes the
%MP285 doesn't seem to respond to negative steps, in which case try a
%different stepsize (e.g. -3 instead of -2) and try again. It usually will
%work with a bit of trial and error.
%
%In Single Move mode, you specify the speed and travel and it moves in one
%ballistic step. This seems to work on rig2 but not on rig3, and probably
%has something to do with the velocity not being set correctly on rig3.
%Again, travel can be positive or negative.

%travel is in microns
%speed and velocity are in microns per second
%motion is only along a single axis defined by the axis pull-down menu.

global exper pref

varargout{1} = lower(mfilename);
if nargin > 0
    action = lower(varargin{1});
else
    action = lower(get(gcbo,'tag'));
end

switch action
    case 'init'
        SetParam(me,'priority','value', GetParam('patchpreprocess','priority')+1);
        
        fig = ModuleFigure(me);
        set(fig,'Position',[1254 666  287  339]);
        
        fs=10;
        fs2=12;
        fontweight='normal'; %trying to save room compared to bold
         hp=0.001; %horizontal position of ui
         w=.04; %width of ui
         hsp=0.01; %horizontal spacing between uis

        
        % Boxes for displaying the MP285 position.
        v=1; %vertical position of ui
        sp=0.01; %vertical spacing between uis
        w=.4;
        h=.2;
        v=v-h-sp;
        MP285posH=uicontrol(fig,'tag','MP285pos','style','text','fontsize',fs,'fontweight',fontweight,...
            'string','','HorizontalAlignment', 'right', 'FontName','Arial',...
            'units','normal','pos',[hp v w h]);
        
        %robot parameters and controls
        vel=100;
        h=.06;
        w=.2;
        v=1;
        v=v-h-sp;
        hp=.5;
        InitParam(me,'velocity','value',vel,...
            'ui','edit','units','normal','pos',[hp v w h]);
        v=v-h-sp;
        InitParam(me,'axis','value',1,'string', 'x|y|z',...
            'ui','popupmenu','units','normal','pos',[hp v w h]);
        v=v-h-sp;

        %panels
        hpan1 = uipanel('Title','Stepper','FontSize',fs,...
                'Position',[.001 .2 .45 .6]);
        hpan1 = uipanel('Title','Single Move','FontSize',fs,...
                'Position',[.5 .2 .45 .6]);

        step=2;
        hp=.05;
        vp=.7;
        InitParam(me,'stepsize','value',step,...
            'ui','edit','units','normal','pos',[hp vp w h]);
        numsteps=10;
        vp=vp-h-sp;
        InitParam(me,'numsteps','value',numsteps,...
            'ui','edit','units','normal','pos',[hp vp w h]);
        vp=vp-h-sp;
        InitParam(me,'pause','value',1,...
            'ui','edit','units','normal','pos',[hp vp w h]);
        vp=vp-h-sp;
        maxtravel=100;
        InitParam(me,'maxtravel','value',maxtravel,...
            'ui','edit','units','normal','pos',[hp vp w h]);
        h=.09;
        vp=vp-h-sp;
        uicontrol('parent',fig,'string','start','tag','start','fontname','Arial',...
            'fontsize',fs2,'fontweight','bold',...
            'units','normal','position',[hp vp w h],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        h=.09;
        vp=vp-h-sp;
        uicontrol('parent',fig,'string','stop','tag','stop','fontname','Arial',...
            'fontsize',fs2,'fontweight','bold',...
            'units','normal','position',[hp vp w h],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        InitParam(me,'abort','value',0)
        
        
        %"just move" parameters and controls
        %(these are for just robotic motion, no feedback or R testing_
        hp=.55;
        h=.06;
        v2=.7;
        v2=v2-h-sp;
        InitParam(me,'speed','value',100,...
            'ui','edit','units','normal','pos',[hp v2 w h]);
        v2=v2-h-sp;
        InitParam(me,'travel','value',100,...
            'ui','edit','units','normal','pos',[hp v2 w h]);
        h=.09;
        v2=v2-h-sp;
        uicontrol('parent',fig,'string','move','tag','move','fontname','Arial',...
            'fontsize',fs2,'fontweight','bold',...
            'units','normal','position',[hp v2 w h],'enable','on',...
            'style','pushbutton','callback',[me ';']);
        
        
        % message box across bottom
        hp=.001;
        vp=.001;
        h=.15;
        w=.9;
        g=uicontrol('parent',fig,'tag','message','style','text',...
            'enable','inact','horiz','left','units','normal', ...
            'pos',[hp vp w h]);
        
        Message(me, 'message box', 'blue')
        
        s=open_MP285_connection;
        [x,y,z]=get_current_position(s);
        set(MP285posH,'string',sprintf('MP285 pos\n%.2f x\n%.2f y\n%.2f z\ntravel 0', x/25, y/25, z/25));
        InitParam(me, 'serialobj', 'value',s);
        
        
        
    case 'reset'
        
        
    case 'close'
        
    case 'getready'
        fig=findobj('type','figure','name',me);
        set(findobj('type','uicontrol','tag','start','parent',fig),'enable','off');
        set(findobj('type','uicontrol','tag','move','parent',fig),'enable','off');
        
    case 'trialend'
        fig=findobj('type','figure','name',me);
        set(findobj('type','uicontrol','tag','start','parent',fig),'enable','on');
        set(findobj('type','uicontrol','tag','move','parent',fig),'enable','on');
        
        % Now for its own modes.
    case 'start'
        %start  robot run
        s=GetParam(me, 'serialobj');
        setparam(me, 'abort', 0);
        fig=findobj('type','figure','name',me);
        set(findobj('type','uicontrol','tag','start','parent',fig),'enable','off');
        moveax=getparam(me, 'axis');
        stepsize=getparam(me, 'stepsize'); %in microns
        numsteps=getparam(me, 'numsteps'); %in microns
        pausedur=getparam(me, 'pause'); %in microns
        
        [startpos(1),startpos(2),startpos(3)]=get_current_position(s); %in msteps
        x=startpos(1);
        y=startpos(2);
        z=startpos(3);
        travel=0;
        for stepnum=1:numsteps
            %move step loop
            if getparam(me, 'abort')
                Message(me, 'robot run aborted', 'append')
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
                    Message(me, 'time out')
                    fprintf('\ntime out')
                    break
                end
            end
            fgets(s); %read CR reply
            
%             x=x+mx; y=y+my; z=z+mz;
            [x,y,z]=get_current_position(s);

            travel=sum([x,y,z]-startpos); %distance travelled
            %this assumes travel along only a single axis
            
            
            % Display parameters
            MP285posH=findobj('type','uicontrol','tag','MP285pos','parent',fig);
            set(MP285posH,'string',sprintf('%.2f x\n%.2f y\n%.2f z\ntravel %.2f', x/25, y/25, z/25, travel/25));
            pause(pausedur)
        end %step loop
        if ~getparam(me, 'abort')
            Message(me, 'completed stepper run')
        end
        set(findobj('type','uicontrol','tag','start','parent',fig),'enable','on');
        
        
    case 'stop'
        %abort autopatch robot run
        %set(RunningH,'backgroundcolor',[1 0 0]);
        SetParam(me, 'abort', 1);
        Message(me, 'aborting...')
        pause(.1)
        
        fig=findobj('type','figure','name',me);
        set(findobj('type','uicontrol','tag','start','parent',fig),'enable','on');
        
        s=GetParam(me, 'serialobj');
        fprintf(s, 'r'); %reset MP285
        fprintf(s, 'n'); %refresh MP285 VFD
                Message(me, 'ready', 'append')

        
    case 'move'
        %just move feature: moves MP285 a fixed travel at a fixed speed
        %no resistance checking or cell-getting
        %this is for pulling out slowly, or perhaps advancing a tungsten
        %electrode
                s=GetParam(me, 'serialobj');

        setparam(me, 'abort', 0);
        moveax=getparam(me, 'axis');
        speed=getparam(me, 'speed');
        travel=getparam(me, 'travel');
        moveH=findobj('tag', 'move', 'type', 'uicontrol');
        set(moveH, 'enable', 'off')
        set_velocity(s, speed);
        [x,y,z]=get_current_position(s); %in msteps
        %get_status(s)
        
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
            if toc> max(20, 2*expected_duration)
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
                    MP285posH=findobj('type','uicontrol','tag','MP285pos','parent',fig);
        set(MP285posH,'string',sprintf('%.2f x\n%.2f y\n%.2f z', x/25, y/25, z/25));
        
        % Parameter callbacks:
        %(none)

end %switch action

end %main function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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
%commandval=vel;

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

function outstr = word2str(bytePair)
val = 2^8*bytePair(2) + bytePair(1); %value comes in little-endian
outstr = num2str(val);
end


function get_status(s)
fprintf('\nbytes available %d', s.bytesavailable')
fgets(s); %read CR
fprintf(s, 's\n')
pause(.1)
fprintf('\nbytes available %d', s.bytesavailable')
%32 bytes (8 x int32, which are 4 bytes each)
status = fread(s, 32,'uint8');

%Parsing pertinent values based on status return data table in MP-285 manual
statusStruct.invertCoordinates = [status(2) status(3) status(4)] - [0 2 4];
statusStruct.infoHardware = word2str(status(31:32));

flags = dec2bin(uint8(status(1)),8);
flags2 = dec2bin(uint8(status(16)),8);

if str2double(flags(2))
    statusStruct.manualMoveMode = 'continuous';
else
    statusStruct.manualMoveMode = 'pulse';
end

if str2double(flags(3))
    statusStruct.displayMode = 'relative'; %NOTE: This is reversed in the documentation (rev 3.13)
else
    statusStruct.displayMode = 'absolute'; %NOTE: This is reversed in the documentation (rev 3.13)
end

if str2double(flags2(6));
    statusStruct.inputDeviceResolutionMode = 'fine';
else
    statusStruct.inputDeviceResolutionMode = 'coarse';
end

speedval = 2^8*status(30) + status(29);
if speedval >= 2^15
    statusStruct.resolutionMode = 'fine';
    speedval = speedval - 2^15;
else
    statusStruct.resolutionMode = 'coarse';
end
statusStruct.resolutionModeVelocity = speedval;

if 1
    disp(['FLAGS: ' num2str(dec2bin(status(1)))]);
    disp(['UDIRX: ' num2str(status(2))]);
    disp(['UDIRY: ' num2str(status(3))]);
    disp(['UDIRZ: ' num2str(status(4))]);
    
    disp(['ROE_VARI: ' word2str(status(5:6))]);
    disp(['UOFFSET: ' word2str(status(7:8))]);
    disp(['URANGE: ' word2str(status(9:10))]);
    disp(['PULSE: ' word2str(status(11:12))]);
    disp(['USPEED: ' word2str(status(13:14))]);
    
    disp(['INDEVICE: ' num2str(status(15))]);
    disp(['FLAGS_2: ' num2str(dec2bin(status(16)))]);
    
    disp(['JUMPSPD: ' word2str(status(17:18))]);
    disp(['HIGHSPD: ' word2str(status(19:20))]);
    disp(['DEAD: ' word2str(status(21:22))]);
    disp(['WATCH_DOG: ' word2str(status(23:24))]);
    disp(['STEP_DIV: ' word2str(status(25:26))]);
    disp(['STEP_MUL: ' word2str(status(27:28))]);
    
    %I'm not sure what happens to byte #28
    
    %Handle the Remote Speed value. Unlike all the rest...it's big-endian.
    speedval = 2^8*status(30) + status(29);
    if strcmpi(statusStruct.resolutionMode,'coarse')
        disp('XSPEED RES: COARSE');
    else
        disp('XSPEED RES: FINE');
    end
    disp(['XSPEED: ' num2str(speedval)]);
    
    disp(['VERSION: ' word2str(status(31:32))]);
end
end