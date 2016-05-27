function plotGeneralizationSurface(phoMat,csvDir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plots a 2d MDS of the chosen similarity matrices from phoMat
% in the x-y plane, and a kernel density estimation of % correct in the z
% axis. Used to assess whether the similarity matrix is a good fit for the
% generalization data
%
%
% Arguments:
% phoMat - phoMat created by makeCVSpeechStruct
% csvDir - directory of compiled trial record csv's as made by
% cleanPermanentRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%What sim matrix?
simtype = input('What similarity matrix would you like to use? \n1)Waveform \n2)Energy \n3)Energy Entropy \n4)Spectral Centroid \n5)Spectral Entropy \n\n   >');
switch simtype
    case 1
        for i = 1:length(phoMat)
            simmat(1:length(phoMat),i) = phoMat(i).similarAbs;
        end
    case 2
        for i = 1:length(phoMat)
            simmat(1:length(phoMat),i) = phoMat(i).similarNRG;
        end        
    case 3
        for i = 1:length(phoMat)
            simmat(1:length(phoMat),i) = phoMat(i).similarNRGEnt;
        end        
    case 4
        for i = 1:length(phoMat)
            simmat(1:length(phoMat),i) = phoMat(i).similarSpecCent;
        end        
    case 5
        for i = 1:length(phoMat)
            simmat(1:length(phoMat),i) = phoMat(i).similarSpecEnt;
        end        
end

%turn into dissimilarity matrix
simmat = 1-simmat;

%MDS
fprintf('Performing MDS with 3 replicates\n');
tic
[MDmat,stress,dispar] = mdscale(simmat,2,'Criterion','sstress','Replicates',3);
fprintf('MDS Complete in %.1f seconds\n',toc);

%Get vectorform stim ID
phoVects = scalarToPhoVect(phoMat);



