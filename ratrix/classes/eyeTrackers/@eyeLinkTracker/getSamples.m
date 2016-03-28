function [gazes samples]=getSamples(et)
%returning samples as a matrix requires that everything is a single
%space could be saved by converting appropriate fields to smaller ints and giving them dedicated matrices
%
% int16:
% sample.type
% sample.htype
% sample.hdata
%
% uint16:
% sample.flags
% sample.status
% sample.input
% sample.buttons
%
% uint32 (same size as single):
% raw.pupil_area
% raw.cr_area
% raw.pupil_dimension
% raw.cr_dimension
% raw.window_position
% raw.cr_area2

el=getConstants(et);

if ~ismember(et.eyeUsed,[el.LEFT_EYE el.RIGHT_EYE])
    et.eyeUsed
    Eyelink('EyeAvailable')
    error('bad eye')
end

gazes=[]; %initialize in case all samples are lost data

justGetLatestSample=false;

if justGetLatestSample
    newOrOld = Eyelink('NewFloatSampleAvailable');
    switch newOrOld
        case -1
            error('NewFloatSampleAvailable returned -1')
        case 0
            error('NewFloatSampleAvailable returned 0')
        case 1
            [sample, raw] = Eyelink('NewestFloatSampleRaw',et.eyeUsed);
        otherwise
            newOrOld
            error('NewFloatSampleAvailable returned unexpected value')
    end

    gazes=getGazeEstimate(et,raw.raw_cr,raw.raw_pupil); %this can have nans in it if some of the raw values are the MISSING_DATA code

    index=et.eyeUsed+1;

    samples=[...
        sample.time;...
        sample.type;...
        sample.flags;...
        sample.px(index);...
        sample.py(index);...
        sample.hx(index);...
        sample.hy(index);...
        sample.pa(index);...
        sample.gx(index);...
        sample.gy(index);...
        sample.rx;...
        sample.ry;...
        sample.status;...
        sample.input;...
        sample.buttons;...
        sample.htype;...
        sample.hdata(1);...
        sample.hdata(2);...
        sample.hdata(3);...
        sample.hdata(4);...
        sample.hdata(5);...
        sample.hdata(6);...
        sample.hdata(7);...
        sample.hdata(8);...
        raw.raw_pupil(1);...
        raw.raw_pupil(2);...
        raw.raw_cr(1);...
        raw.raw_cr(2);...
        raw.pupil_area;...
        raw.cr_area;...
        raw.pupil_dimension(1);...
        raw.pupil_dimension(2);...
        raw.cr_dimension(1);...
        raw.cr_dimension(2);...
        raw.window_position(1);...
        raw.window_position(2);...
        raw.pupil_cr(1);...
        raw.pupil_cr(2);...
        raw.cr_area2;...
        raw.raw_cr2(1);...
        raw.raw_cr2(2);...
        GetSecs;...
        now... %edf: 'now' is useless and slow -- why does pmm want it?  it is less accurate than GetSecs and takes 4x longer -- minimum 30us per call, often takes 100us and peaks at 5ms!!!
        ]';
else

    [samples events]=Eyelink('GetQueuedData',et.eyeUsed);
    if ~isempty(events)
        for i=events(2,:)
            fprintf('got event type: %s\n',geteventtype(el, i))
        end
    end

    if ~isempty(samples)
        losts=samples(2,:)==el.LOSTDATAEVENT;
        numGood=sum(~losts);
        if sum(losts)>0
            fprintf('got %d lost data events\n',sum(losts))
        end

        gazes=getGazeEstimate(et,samples([34 35],~losts)',samples([32 33],~losts)'); %this can have nans in it if some of the raw values are the MISSING_DATA code
        
        if numGood>0
            switch et.eyeUsed
                case el.LEFT_EYE
                    badsOffset=1; %remove right eye values
                case el.RIGHT_EYE
                    badsOffset=0; %remove left eye values
                otherwise
                    error('bad eye')
            end
            badFields=(4:2:16)+badsOffset;
            goodFields=~ismember((1:size(samples,1)),badFields);

            samples=[samples(goodFields,~losts)' GetSecs*ones(numGood,1) now*ones(numGood,1)];
            %edf: 'now' is useless and slow -- why does pmm want it?  it is less accurate than GetSecs and takes 4x longer -- minimum 30us per call, often takes 100us and peaks at 5ms!!!
            %pmm notes its easier to relate to trial start time
            %edf says everything should be kept in the GetSecs scale, except the trialrecord gross time/date stamp.  if you care about accurate time since trial start, you need the trial's first GetSecs.
        else
            samples=[];
        end
    end
end

end