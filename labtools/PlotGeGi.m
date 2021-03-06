function PlotGeGi(varargin)
%usage:     PlotGeGi('expdate', 'session', 'filenum')
%           PlotGeGi('expdate', 'session', 'filenum', [xlimits])
%           PlotGeGi(out)
% E2 tuning curve script
%plot ge and gi tuning curve
%looks for an outfile data structure generated by ProcessGeGi
if nargin==0
    fprintf('\nno input');
    return
elseif nargin==1
    in=varargin{1};
%     dur=max(in.durs);
    xlimits=[-50 250]; %x limits for axis
elseif nargin==3
    expdate=varargin{1};
    session=varargin{2};
    filenum=varargin{3};
    godatadir(expdate, session, filenum)
    outfile=sprintf('out%s-%s-%s.mat', expdate, session, filenum);
    if exist(outfile)==2
        load(outfile)
        if ~isfield(out, 'GE')
            error('could not find gegi data in outfile. Please run ProcessGeGi')
        end
    else
        error('could not find outfile. Please run ProcessGeGi')
    end
    in=out;
    xlimits=[-50 250]; %x limits for axis
elseif nargin==4
    expdate=varargin{1};
    session=varargin{2};
    filenum=varargin{3};
    godatadir(expdate, session, filenum)
    outfile=sprintf('out%s-%s-%s.mat', expdate, session, filenum);
    load(outfile)
    if exist(outfile)==2
        load(outfile)
        if ~isfield(out, 'GE')
            error('could not find gegi data in outfile. Please run ProcessGeGi')
        end
    else
        error('could not find outfile. Please run ProcessGeGi')
    end
    in=out;
    xlimits=varargin{4};
else
    error('\nPlotGeGi: wrong number of arguments');
end


M1=in.M1;
mM1=in.mM1;
expdate=in.expdate;
session=in.session;
filenum=in.filenum;
freqs=in.freqs;
amps=in.amps;
durs=in.durs
potentials=in.potentials;
samprate=in.samprate;
numamps=length(amps);
numfreqs=length(freqs);
numpotentials=length(potentials);
numdurs=length(durs);

%find optimal axis limits
axmax=[0 0];
for dindex=1:numdurs
    for aindex=[numamps:-1:1]
        for findex=1:numfreqs
            ge=squeeze(in.GE(findex, aindex,  dindex, :));
            gi=squeeze(in.GI(findex, aindex,  dindex, :));
            %gsyn=squeeze(in.GSYN(findex, aindex, 1, :));
            %        if findex==3 & aindex==6 trace2=0*trace2;end %exclude this trace from axis optimatization
            %         if min([gsyn])<axmax(1) axmax(1)=min([gsyn]);end
            %         if max([gsyn])>axmax(2) axmax(2)=max([gsyn]);end
            if min([ge; gi])<axmax(1) axmax(1)=min([ge; gi]);end
            if max([ge; gi])>axmax(2) axmax(2)=max([ge; gi]);end
        end
    end
end

%axmax(2)=10;

%plot the mean tuning curve
for dindex=1:numdurs
    figure

    p=0;
    subplot1( numamps,numfreqs)

    for aindex=[numamps:-1:1]
        for findex=1:numfreqs
            p=p+1;
            subplot1( p)

            ge=squeeze(in.GE(findex, aindex, dindex,  :));
            gi=squeeze(in.GI(findex, aindex, dindex,  :));
            gsyn=squeeze(in.GSYN(findex, aindex, dindex, 1, :));
            gsynconf1=squeeze(in.GSYNconf(findex, aindex, dindex, :,1));
            gsynconf2=squeeze(in.GSYNconf(findex, aindex, dindex, :,2));
            if isfield(in, 'M1stim')
                stimtrace=squeeze(in.M1stim(findex, aindex, dindex, 1, 2, :));
                stimtrace=stimtrace-mean(stimtrace(1:100));
                stimtrace=stimtrace./max(abs(stimtrace));
                stimtrace=stimtrace*.1*diff(axmax);
                stimtrace=stimtrace+axmax(1);
            else
                stimtrace=0*ge;
            end
            t=1:length(ge);
            t=t/10;
            plot(t, gi, 'r', t, ge, 'g', t, stimtrace, 'm')
            %plot(t, ge, 'g', t, gi, 'r', t, gsyn, 'k')
            %plot(t, ge, 'g', t, gi, 'r')
            %plot(t, ge, 'g', t, gi, 'r', t, gsyn, 'k')
            ylim(axmax)
           if exist('xlimits') xlim(xlimits); end
            %line(in.baseline+[0 durs(dindex)], axmax(1)*[1 1], 'linewidth', 2, 'color', [.3 .3 .3])
            axis off

        end
    end
    subplot1(1)
    title(sprintf('%s-%s-%s dur:%dms', expdate,session, filenum, in.durs(dindex)), 'horizontala', 'right')

    %label amps and freqs
    p=0;
    for aindex=[numamps:-1:1]
        for findex=1:numfreqs
            p=p+1;
            subplot1(p)
            if findex==1
                text(-400, mean(axmax), int2str(amps(aindex)))
            end
            if aindex==1
                if mod(findex,2) %odd freq
                    vpos=axmax(1)-.2*mean(axmax);
                else
                    vpos=axmax(1)-.2*mean(axmax);
                end
                text(0, vpos, sprintf('%d\n%.1f', findex, freqs(findex)/1000))
            end
        end
    end
end