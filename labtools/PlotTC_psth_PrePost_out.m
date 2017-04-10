function PlotTC_psth_PrePost_out(out, varargin)
% plots two single-channel psth tuning curves (a pre and a post) 
% usage: PlotTC_psth_PrePost_out(out, [xlimits], [ylimits], [binwidth])
% (xlimits, ylimits, binwidth are optional)
%
% mw 092702
% last updated 111208
%this function uses an outfile generated by AnalyzePrePostTC
%use PlotTC_psth_PrePost to operate directly on the data (not on an
%outfile)
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==0 
    fprintf('\nno input');
    return;
elseif nargin==1
    ylimits=-1;
    durs=getdurs(out.expdate1, out.session1, out.filenum1);
    dur=max([durs 100]);
    xlimits=[-.5*dur 1.5*dur]; %x limits for axis
    binwidth=50;
elseif nargin==2
    xlimits=varargin{1};
    if isempty(xlimits)
        durs=getdurs(out.expdate1, out.session1, out.filenum1);
        dur=max([durs 100]);
        xlimits=[-.5*dur 1.5*dur]; %x limits for axis
    end
    ylimits=-1;
    binwidth=50;
elseif nargin==3
    xlimits=varargin{1};
    if isempty(xlimits)
        durs=getdurs(out.expdate1, out.session1, out.filenum1);
        dur=max([durs 100]);
        xlimits=[-.5*dur 1.5*dur]; %x limits for axis
    end
    ylimits=varargin{2};
    if isempty(ylimits)
        ylimits=-1;
    end
    binwidth=50;
elseif nargin==4
    xlimits=varargin{1};
    if isempty(xlimits)
        durs=getdurs(out.expdate1, out.session1, out.filenum1);
        dur=max([durs 100]);
        xlimits=[-.5*dur 1.5*dur]; %x limits for axis
    end
    ylimits=varargin{2};
    if isempty(ylimits)
        ylimits=-1;
    end
    binwidth=varargin{3};
end
tracelength=diff(xlimits); %in ms
if xlimits(1)<0
    baseline=abs(xlimits(1));
else
    baseline=0;
end

fs=8;
dindex=1;

%find axis limits
if ylimits==-1
    ylimits=[-2 -2];
for aindex=[length(out.amps):-1:1]
    for findex=1:length(out.freqs)
            spiketimes1=out.mMST1(findex, aindex).spiketimes;
            spiketimes2=out.mMST2(findex, aindex).spiketimes;
            X=-baseline:binwidth:tracelength; %specify bin centers
            [n1, x1]=hist(spiketimes1, X);
            [n2, x2]=hist(spiketimes2, X);

            ylimits(2)=max(ylimits(2), max([n1 n2]));
        end
    end
end

%plot files
figure
p=0;
subplot1( length(out.amps),length(out.freqs))
for aindex=[length(out.amps):-1:1]
    for findex=1:length(out.freqs)
        p=p+1;
        subplot1( p)
        spiketimes1=out.mMST1(findex, aindex).spiketimes;
        spiketimes2=out.mMST2(findex, aindex).spiketimes;
        %         %use this code to plot curves
        X=-baseline:binwidth:tracelength; %specify bin centers
        [n1, x1]=hist(spiketimes1, X);
        [n2, x2]=hist(spiketimes2, X);
         r=plot(x1, n1, 'b', x2, n2, 'r');
         set(r(1), 'linewidth', 2.5)
         set(r(2), 'linewidth', 1.5)
        %use this code to plot histograms
%        hist(spiketimes1, numbins);
        
        ylim(ylimits)
        xlim(xlimits)
        %xlim([200 400])
        %xlim([400 600])
%     axis off
%set(gca, 'xtick', [0:20:tracelength])
%grid on
    set(gca, 'fontsize', fs)

    end
end


%label amps and freqs
p=0;
for aindex=[length(out.amps):-1:1]
    for findex=1:length(out.freqs)
        p=p+1;
        subplot1(p)
        if findex==1
            text(xlimits(1)-2*tracelength, mean(ylimits), int2str(out.amps(aindex)))
        else
            set(gca, 'xtick', [])
        end
        if aindex==1
                vpos=ylimits(1)-.5*diff(ylimits);
            text(0, vpos, sprintf('%.1f', out.freqs(findex)/1000))
        end
    end
end
subplot1(1)
T=title(sprintf('%s-%s-%s, %s-%s-%s, nstd=%d, %dms bins',out.expdate1,out.session1, out.filenum1,out.expdate2,out.session2, out.filenum2, out.nstd,binwidth));
set(T, 'horizontalalign', 'left')





