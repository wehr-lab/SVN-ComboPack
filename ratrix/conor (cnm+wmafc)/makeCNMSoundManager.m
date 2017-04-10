function sm=makeCNMSoundManager()
% this is a manager for auditory intensity discrimination
% where we want tight control over sounds

sm=soundManager({soundClip('correctSound','allOctaves',[500],20000), ...
            soundClip('keepGoingSound','empty'), ...
            soundClip('trySomethingElseSound','empty'), ...
            soundClip('wrongSound','empty'),... 
            soundClip('earlywrongSound','gaussianWhiteNoise'),...
            soundClip('trialStartSound','empty')});