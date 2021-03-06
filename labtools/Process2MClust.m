function Process2MClust(expdate, session, filenum, varargin)
% Extracts spike waveforms from tetrode data into a file that can be read
% by MClust using the WehrlabLoadingEngine.
% Hard-coded for 4 channels!
%
%
% Usage: Process2MClust(expdate, session, filenum, [monitor], [thresh])
% (thresh is optional, default is thresh = 3std)
% Thresh can the same value for all channels...
    % -- One thresh (5 std) for all channels:
    % (expdate, session, filenum, [monitor], 5)
    % -- One absolute voltage thresh (0.1mV) for all channels:
    % (expdate, session, filenum, [monitor], [-1 0.1])

% ...or four different values for each channel:
% -- Different std for all channels:
    % (expdate, session, filenum, [monitor], [1 2 3 4])

%  to use a different absolute voltage threshold for each
% channel (1-4).
%  thresh is in number of standard deviations
%  to use an absolute threshold (in mV) pass [-1 mV] as the thresh
%  argument, where mV is the desired threshold
% mw 12-18-2011
%note mw 051012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

monitor=1; %0=off; 1=on
if nargin==0
    fprintf('\nno input');
    return;
elseif nargin==3
    nstd=3;
elseif nargin==4
    nstd=3;
    monitor=varargin{1};
    if isempty(monitor) monitor=1;end
elseif nargin==5
    nstd=varargin{2};
    monitor=varargin{1};
    if isempty(nstd) nstd=3;end
    if isempty(monitor) monitor=1;end
else
    error('wrong number of arguments');
end

lostat=-1;%2.4918e+006; %discard data after this position (in samples), -1 to skip

[T1 T2 T3 T4 AO E S]=GoGetTetrodeData(expdate,session,filenum);

event=E.event;
if isempty(event) fprintf('\nno tones\n'); end
user=whoami;

%scale traces
scaledtrace1=T1.nativeScaling*double(T1.trace)+ T1.nativeOffset;
scaledtrace2=T2.nativeScaling*double(T2.trace)+ T2.nativeOffset;
scaledtrace3=T3.nativeScaling*double(T3.trace)+ T3.nativeOffset;
scaledtrace4=T4.nativeScaling*double(T4.trace)+ T4.nativeOffset;

clear T1 T2 T3 T4 AO E S


fprintf('\nextracting spike waveforms');

samprate=1e4;
if lostat==-1 lostat=length(scaledtrace1);end

high_pass_cutoff=300; %Hz
fprintf('\nhigh-pass filtering at %d Hz', high_pass_cutoff);
[b,a]=butter(1, high_pass_cutoff/(samprate/2), 'high');
filteredtrace1=filtfilt(b,a,scaledtrace1);
filteredtrace2=filtfilt(b,a,scaledtrace2);
filteredtrace3=filtfilt(b,a,scaledtrace3);
filteredtrace4=filtfilt(b,a,scaledtrace4);
if length(nstd)==2
    if nstd(1)==-1
        thresh1=nstd(2);
        thresh2=nstd(2);
        thresh3=nstd(2);
        thresh4=nstd(2);
        
        %nstd=thresh/std(filteredtrace);
        %fprintf('\nusing absolute spike detection threshold of %.1f mV (%.1f sd)', thresh, nstd);
    end
    
elseif length(nstd)==1
    thresh1=nstd*std(filteredtrace1);
    thresh2=nstd*std(filteredtrace2);
    thresh3=nstd*std(filteredtrace3);
    thresh4=nstd*std(filteredtrace4);
    fprintf('\nusing spike detection threshold of %.4f mV', [thresh1 thresh2 thresh3 thresh4 ]);
    fprintf('\nwhich is %g sd', nstd);
elseif length(nstd)==4
    thresh1=nstd(1)*std(filteredtrace1);
    thresh2=nstd(2)*std(filteredtrace2);
    thresh3=nstd(3)*std(filteredtrace3);
    thresh4=nstd(4)*std(filteredtrace4);
    fprintf('\nusing spike detection threshold of %.4f mV', [thresh1 thresh2 thresh3 thresh4 ]);
        fprintf('\nwhich is %g sd', nstd);
elseif length(nstd)==5
    if nstd(1)==-1
        thresh1=nstd(2);
        thresh2=nstd(3);
        thresh3=nstd(4);
        thresh4=nstd(5);
        fprintf('\nusing spike detection threshold of %.4f mV', [thresh1 thresh2 thresh3 thresh4 ]);
    else
        error('bad threshold request')
    end
else
error('thresh should be 1, 2, or 4 elements')
end
refract=5;
fprintf('\nusing refractory period of %.1f ms (%d samples)', 1000*refract/samprate,refract );
spikes1=find(filteredtrace1>thresh1);
dspikes1=spikes1(1+find(diff(spikes1)>refract));
spikes2=find(filteredtrace2>thresh2);
dspikes2=spikes2(1+find(diff(spikes2)>refract));
spikes3=find(filteredtrace3>thresh3);
dspikes3=spikes3(1+find(diff(spikes3)>refract));
spikes4=find(filteredtrace4>thresh4);
dspikes4=spikes4(1+find(diff(spikes4)>refract));
try
    dspikes1=[spikes1(1) dspikes1(:)'];
    dspikes2=[spikes2(1) dspikes2(:)'];
    dspikes3=[spikes3(1) dspikes3(:)'];
    dspikes4=[spikes4(1) dspikes4(:)'];
    % %convert to ms
    % dspikes1= dspikes1*1000/samprate;
    % dspikes2= dspikes2*1000/samprate;
    % dspikes3= dspikes3*1000/samprate;
    % dspikes4= dspikes4*1000/samprate;
    
catch
    fprintf('\n\ndspikes is empty on at least one channel; either cell never spiked or the nstd is set too high\n');
end

%collect waveforms into matrix
%winsize=32; length of waveform window in samples
% Make n x 4 x npoints matrix, where n is number of spikes and npoints is number of samples per spike.

dspikes1=reshape(dspikes1, 1, prod(size(dspikes1)));
dspikes2=reshape(dspikes2, 1, prod(size(dspikes2)));
dspikes3=reshape(dspikes3, 1, prod(size(dspikes3)));
dspikes4=reshape(dspikes4, 1, prod(size(dspikes4)));
allspikes=sort([dspikes1 dspikes2 dspikes3 dspikes4]);

%%%%%%%%%%%%%%%%%%
%visually check thresholds before extraction
if (monitor)
region=1:10*1e4; %10 seconds
    offset=range(filteredtrace1(region));
    figure
    dt=1:length(filteredtrace1(region)); %in samples
    plot(dt, filteredtrace1(region),dt, filteredtrace2(region)+1*offset,dt, filteredtrace3(region)+2*offset, dt, filteredtrace4(region)+3*offset)
    hold on
    plot(dspikes1, thresh1*ones(size(dspikes1)), 'm*')
    L1=line(xlim, thresh1*[1 1]);
    L2=line(xlim, thresh1*[-1 -1]);
    set([L1 L2], 'color', 'g');
    text(-15e3, 0*offset, 'Ch 1')
    
    plot(dspikes2, 1*offset+thresh2*ones(size(dspikes2)), 'm*')
    L1=line(xlim, 1*offset+thresh2*[1 1]);
    L2=line(xlim, 1*offset+thresh2*[-1 -1]);
    set([L1 L2], 'color', 'g');
    text(-15e3, 1*offset, 'Ch 2')
    
    plot(dspikes3, 2*offset+thresh3*ones(size(dspikes3)), 'm*')
    L1=line(xlim, 2*offset+thresh3*[1 1]);
    L2=line(xlim, 2*offset+thresh3*[-1 -1]);
    set([L1 L2], 'color', 'g');
        text(-15e3, 2*offset, 'Ch 3')

    plot(dspikes4, 3*offset+thresh4*ones(size(dspikes4)), 'm*')
    L1=line(xlim, 3*offset+thresh4*[1 1]);
    L2=line(xlim, 3*offset+thresh4*[-1 -1]);
    set([L1 L2], 'color', 'g');
        text(-15e3, 3*offset, 'Ch 4')

    xlim([ 0 region(end)])
    pos=get(gcf, 'pos');
    pos(1)=pos(1)-pos(3);
    set(gcf, 'pos', pos);
       ButtonName = nonmodalquestdlg('Are thresholds OK?', ...
                         'Thresh Check', ...
                         'OK', 'Cancel', 'OK');
   switch ButtonName,
     case 'Cancel',
      disp('Aborting extraction.');
      return
   end % switch

end   %%%%%%%%%%%%%%%%%%
fprintf('\nnumber of events to scan: %d', length(allspikes))

% % % tic
% % % wb = waitbar(0,'extracting spike waveforms');
% % % j=0;
% % % for i=1:length(allspikes)
% % %     waitbar(i/length(allspikes), wb)
% % %     pos=allspikes(i);
% % % %     retrigger_time=22; 
% % %     retrigger_time=1; 
% % %     %retrigger_time (in samples) determines how long to skip after a spike before
% % % %looking for another spike. If it is set to 22, the waveform snippets will
% % % %never overlap, and no spike will ever appear in 2 separate records.
% % % %HOwever, spikes occurring <22 samples will be missed. If set to 1 you can
% % % %detect rapidly occuring spikes but they will cause overlap.  
% % % %     http://neuralynx.com/faq/why_does_cheetah_capture_multiple_spikes_in_a_single_spike_record
% % %     if i>1
% % %         f=pos>(allspikes(i-1)+retrigger_time); %this excludes events within the previous waveform snippet
% % %     else f=1;
% % %     end
% % %     if f & pos>9 & pos<length(scaledtrace1)-22 %need pre and post-spike window space
% % %         j=j+1; %j separate index because some spikes are excluded (if picked up on multiple channels)
% % %         t(j)=pos/10;
% % %         wf(j,1,:)=scaledtrace1((pos-9):(pos+22));
% % %         wf(j,2,:)=scaledtrace2((pos-9):(pos+22));
% % %         wf(j,3,:)=scaledtrace3((pos-9):(pos+22));
% % %         wf(j,4,:)=scaledtrace4((pos-9):(pos+22));
% % %         uniquespiketimes(j)=pos;
% % %     end
% % % end
% % % numspikes=j;
% % % close(wb)
% % % toc
%%%%%%%%%%%%%%%%%%%
%trying to vectorize the above algorithm, duplicating it here to check for
%agreement
tic
wb = waitbar(0,'extracting spike waveforms (vector)');
     retrigger_time=22;
%retrigger_time=1;
%retrigger_time (in samples) determines how long to skip after a spike before
%looking for another spike. If it is set to 22, the waveform snippets will
%never overlap, and no spike will ever appear in 2 separate records.
%HOwever, spikes occurring <22 samples will be missed. If set to 1 you can
%detect rapidly occuring spikes but they will cause overlap.
%     http://neuralynx.com/faq/why_does_cheetah_capture_multiple_spikes_in_a_single_spike_record


%need pre and post-spike window space
allspikesv=allspikes; %copy to test vectorization
allspikesv=allspikesv(allspikesv>9);
allspikesv=allspikesv(allspikesv<length(scaledtrace1)-22);

%         remove spikes occurring within retrigger_time (handling same as
%         refractory period above)
dallspikesv=allspikesv(1+find(diff(allspikesv)>retrigger_time));
dallspikesv=[allspikesv(1) dallspikesv(:)'];

t=allspikesv/10;

wfv(:,1,:)=[scaledtrace1(allspikesv-9) scaledtrace1(allspikesv-8) scaledtrace1(allspikesv-7) scaledtrace1(allspikesv-6) ...
scaledtrace1(allspikesv-5) scaledtrace1(allspikesv-4) scaledtrace1(allspikesv-3) scaledtrace1(allspikesv-2)...
scaledtrace1(allspikesv-1) scaledtrace1(allspikesv-0) scaledtrace1(allspikesv+1) scaledtrace1(allspikesv+2)...
scaledtrace1(allspikesv+3) scaledtrace1(allspikesv+4) scaledtrace1(allspikesv+5) scaledtrace1(allspikesv+6)...
scaledtrace1(allspikesv+7) scaledtrace1(allspikesv+8) scaledtrace1(allspikesv+9) scaledtrace1(allspikesv+10)...
scaledtrace1(allspikesv+11) scaledtrace1(allspikesv+12) scaledtrace1(allspikesv+13) scaledtrace1(allspikesv+14)...
scaledtrace1(allspikesv+15) scaledtrace1(allspikesv+16) scaledtrace1(allspikesv+17) scaledtrace1(allspikesv+18)...
scaledtrace1(allspikesv+19) scaledtrace1(allspikesv+20) scaledtrace1(allspikesv+21) scaledtrace1(allspikesv+22)];

wfv(:,2,:)=[scaledtrace2(allspikesv-9) scaledtrace2(allspikesv-8) scaledtrace2(allspikesv-7) scaledtrace2(allspikesv-6) ...
scaledtrace2(allspikesv-5) scaledtrace2(allspikesv-4) scaledtrace2(allspikesv-3) scaledtrace2(allspikesv-2)...
scaledtrace2(allspikesv-1) scaledtrace2(allspikesv-0) scaledtrace2(allspikesv+1) scaledtrace2(allspikesv+2)...
scaledtrace2(allspikesv+3) scaledtrace2(allspikesv+4) scaledtrace2(allspikesv+5) scaledtrace2(allspikesv+6)...
scaledtrace2(allspikesv+7) scaledtrace2(allspikesv+8) scaledtrace2(allspikesv+9) scaledtrace2(allspikesv+10)...
scaledtrace2(allspikesv+11) scaledtrace2(allspikesv+12) scaledtrace2(allspikesv+13) scaledtrace2(allspikesv+14)...
scaledtrace2(allspikesv+15) scaledtrace2(allspikesv+16) scaledtrace2(allspikesv+17) scaledtrace2(allspikesv+18)...
scaledtrace2(allspikesv+19) scaledtrace2(allspikesv+20) scaledtrace2(allspikesv+21) scaledtrace2(allspikesv+22)];

wfv(:,3,:)=[scaledtrace3(allspikesv-9) scaledtrace3(allspikesv-8) scaledtrace3(allspikesv-7) scaledtrace3(allspikesv-6) ...
scaledtrace3(allspikesv-5) scaledtrace3(allspikesv-4) scaledtrace3(allspikesv-3) scaledtrace3(allspikesv-2)...
scaledtrace3(allspikesv-1) scaledtrace3(allspikesv-0) scaledtrace3(allspikesv+1) scaledtrace3(allspikesv+2)...
scaledtrace3(allspikesv+3) scaledtrace3(allspikesv+4) scaledtrace3(allspikesv+5) scaledtrace3(allspikesv+6)...
scaledtrace3(allspikesv+7) scaledtrace3(allspikesv+8) scaledtrace3(allspikesv+9) scaledtrace3(allspikesv+10)...
scaledtrace3(allspikesv+11) scaledtrace3(allspikesv+12) scaledtrace3(allspikesv+13) scaledtrace3(allspikesv+14)...
scaledtrace3(allspikesv+15) scaledtrace3(allspikesv+16) scaledtrace3(allspikesv+17) scaledtrace3(allspikesv+18)...
scaledtrace3(allspikesv+19) scaledtrace3(allspikesv+20) scaledtrace3(allspikesv+21) scaledtrace3(allspikesv+22)];

wfv(:,4,:)=[scaledtrace4(allspikesv-9) scaledtrace4(allspikesv-8) scaledtrace4(allspikesv-7) scaledtrace4(allspikesv-6) ...
scaledtrace4(allspikesv-5) scaledtrace4(allspikesv-4) scaledtrace4(allspikesv-3) scaledtrace4(allspikesv-2)...
scaledtrace4(allspikesv-1) scaledtrace4(allspikesv-0) scaledtrace4(allspikesv+1) scaledtrace4(allspikesv+2)...
scaledtrace4(allspikesv+3) scaledtrace4(allspikesv+4) scaledtrace4(allspikesv+5) scaledtrace4(allspikesv+6)...
scaledtrace4(allspikesv+7) scaledtrace4(allspikesv+8) scaledtrace4(allspikesv+9) scaledtrace4(allspikesv+10)...
scaledtrace4(allspikesv+11) scaledtrace4(allspikesv+12) scaledtrace4(allspikesv+13) scaledtrace4(allspikesv+14)...
scaledtrace4(allspikesv+15) scaledtrace4(allspikesv+16) scaledtrace4(allspikesv+17) scaledtrace4(allspikesv+18)...
scaledtrace4(allspikesv+19) scaledtrace4(allspikesv+20) scaledtrace4(allspikesv+21) scaledtrace4(allspikesv+22)];

numspikesv=size(wfv,1);
close(wb)
fprintf('\ntotal num spikes (vector): %d', numspikesv)
toc
%%%%%%%%
wf=wfv;
allspikes=allspikesv;
numspikes=numspikesv;
uniquespiketimes=allspikes;
%note: the number of uniques spikes for the two methods does not match
%exactly, so I must not be excluding overlaps quite right

fprintf('\ntotal num spikes: %d', numspikes)
if numspikes==0
    error('no spikes detected. no waveform file written')
end
% write data into a .mat file
outfilenamem=sprintf('%s-%s-%s-wf.mat', expdate,session,filenum);
save(outfilenamem, 'wf', 't')

%write a binary .tt file in neuralynx format (hopefully)
%each record is 176 bytes: 8 for timestamp, 40 for params, 128 for waveform
%(4x32?)
% outfilename=sprintf('%s-%s-%s-wf.tt', expdate,session,filenum);
% fid=fopen(outfilename, 'wb');
% for i=1:length(t)
%     fwrite(fid, t(i), 'uint8');
%     fwrite(fid, 1:5, 'uint8'); %dummy param
%     fwrite(fid, wf(i,:,:), 'uint8');
% end
% fclose(fid);
%there's no way this is going to work

fprintf('\nwrote output file\n%s\n', outfilenamem)

if (monitor)
    region=1:length(filteredtrace1);
    offset=range(filteredtrace1(region));
    figure
    dt=1:length(filteredtrace1(region)); %in samples
    plot(dt, filteredtrace1(region),dt, filteredtrace2(region)+1*offset,dt, filteredtrace3(region)+2*offset, dt, filteredtrace4(region)+3*offset)
    hold on
    plot(uniquespiketimes, thresh1*ones(size(uniquespiketimes)), 'r*')
    L1=line(xlim, thresh1*[1 1]);
    L2=line(xlim, thresh1*[-1 -1]);
    set([L1 L2], 'color', 'g');
    
    plot(uniquespiketimes, 1*offset+thresh2*ones(size(uniquespiketimes)), 'r*')
    L1=line(xlim, 1*offset+thresh2*[1 1]);
    L2=line(xlim, 1*offset+thresh2*[-1 -1]);
    set([L1 L2], 'color', 'g');
    
    plot(uniquespiketimes, 2*offset+thresh3*ones(size(uniquespiketimes)), 'r*')
    L1=line(xlim, 2*offset+thresh3*[1 1]);
    L2=line(xlim, 2*offset+thresh3*[-1 -1]);
    set([L1 L2], 'color', 'g');
    
    plot(uniquespiketimes, 3*offset+thresh4*ones(size(uniquespiketimes)), 'r*')
    L1=line(xlim, 3*offset+thresh4*[1 1]);
    L2=line(xlim, 3*offset+thresh4*[-1 -1]);
    set([L1 L2], 'color', 'g');
    xlim([ 0 region(end)])
    pos=get(gcf, 'pos');
    pos(1)=pos(1)-pos(3);
    set(gcf, 'pos', pos);
    
    figure
    c=get(gca, 'colororder');
    subplot1(4, 4)
    for i=1:16 subplot1(i); axis off;end
    subplot1([4 1])
    h=plot(mean(squeeze(wf(:,1,:))));
    set(h, 'color', c(1,:))
    ylabel('Ch 1')
    axis on
    
    subplot1([3 1])
    h=plot(mean(squeeze(wf(:,2,:))));
    set(h, 'color', c(2,:))
    ylabel('Ch 2')
    axis on
    
    subplot1([2 1])
    h=plot(mean(squeeze(wf(:,3,:))));
    set(h, 'color', c(3,:))
    ylabel('Ch 3')
    axis on
    
    subplot1([1 1])
    h=plot(mean(squeeze(wf(:,4,:))));
    set(h, 'color', c(4,:))
    ylabel('Ch 4')
    axis on
end
if monitor
    num2plot=100;
    figure
    pos=get(gcf, 'pos');
    pos(1)=pos(1)+pos(3)/2;
    set(gcf, 'pos', pos);
    
    hold on
    %ylim([min(filteredtrace1) max(filteredtrace1)]);
    i=0;
    L1=line([-10 10], thresh1*[1 1]);
    L2=line([-100 100], thresh1*[-1 -1]);
    set([L1 L2], 'color', 'm')
    
    offset=.5*offset;
    for ds=uniquespiketimes(1:min(num2plot, length(uniquespiketimes)))
        xlim([-10 +10])
        region=[ds-100:ds+100];
        if min(region)<1
            region=[1:ds+100];
        end
        t=1:length(region);t=t/10;t=t-10;
        i=i+1;
        h=  plot(t, filteredtrace1(region),t, filteredtrace2(region)+1*offset,t, filteredtrace3(region)+2*offset,t, filteredtrace4(region)+3*offset);
        h1(i,:)=h;
        if ~isempty(dspikes1)
            h2(i)=plot(dspikes1-ds, thresh1*ones(size(dspikes1)), 'r+');
        elseif ~isempty(dspikes2)
            h2(i)=plot(dspikes2-ds, thresh2*ones(size(dspikes2)), 'r+');
        elseif ~isempty(dspikes3)
            h2(i)=plot(dspikes3-ds, thresh3*ones(size(dspikes3)), 'r+');
        elseif ~isempty(dspikes4)
            h2(i)=plot(dspikes4-ds, thresh4*ones(size(dspikes4)), 'r+');
        end
        title(sprintf('spike %d %d', i, ds))
        pause(.05)
        if i>10
            set([h1(i-10,:) h2(i-10) ], 'visible', 'off')
        end
    end
end



