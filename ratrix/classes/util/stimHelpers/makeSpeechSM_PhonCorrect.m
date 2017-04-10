function sm=makeSpeechSM_PhonCorrect(speechparams,noiseparams)
% this is a manager for auditory intensity discrimination
% where we want tight control over sounds

sm=soundManager({setAmp(soundClip('correctSound','speechWav',speechparams),speechparams.amp), ...
            soundClip('keepGoingSound','empty'), ...
            soundClip('trySomethingElseSound','empty'), ...
            soundClip('wrongSound','pulseAndNoise',noiseparams),... 
            soundClip('earlywrongSound','pulseAndNoise',noiseparams),...
            soundClip('trialStartSound','empty')});
        
      