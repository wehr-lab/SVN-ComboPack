function [V, spiketimes] = IFg( Ge, Gi, Gl, I, C,dt, Th)
% conductance based integrate-and-fire model
% example: try running IFscript
%
%NOTE: conductance is specified in 1/Mohm (e-6, note nS is e-9)
% divide nS by 1000 to get 1/Mohm
%
% usage: [V, spiketimes] = IF( Ge, Gi, Gl, I, C,dt, Th)
% integrate-and-fire, with time varying Ge and G
% INPUT:
%   Ge     vector of excitatory conductance vs. time (1/Mohm)
%   Gi     vector of inhibitory conductance vs. time (1/Mohm)
%   Gl     leak conductance (1/Mohm) note that: C/G = nF*Mohm = msec
%   I      vector of current injection vs. time (nA?) 
%   C      capacitance (nF)
%   dt     time step (in msec)
%   Th     threshold
%   Tmax   final time (msec)
% OUTPUT
%   V      vector of V vs. N
%   spike_count - number of threshold crossings 
        
if length(Ge)~=length(Gi) | length(Ge)~= length(I)
    error('Ge, Gi, I should all be vectors of the same length')
end

El = 0; % leak conductance
Ei = -15; % inhibitory battery
Ee = 60; %excitatory battery

N = length(Ge);

V = zeros(N,1);
spiketimes=[];
for i = 2: (N-1)
	if V(i-1)>Th 
        V(i-1)=60;
		V(i)=0;       
		spiketimes=[spiketimes i*dt];
	end    
	% forward Euler:
	V(i+1) = -(dt/C)* ...
		((V(i)-Ee)*Ge(i) + ...
		 (V(i)-Ei)*Gi(i) + ...
		 (V(i)-El)*Gl-I(i)) ...
		 + V(i);
		
end



%%suggested starting parameters
%  N=2000; 
%  Ge=.001*poissrnd(2,N,1);
%  Gi=.001*poissrnd(2,N,1); 
%  Gl=1/50; 
%  C=1;
%  dt=.1;
%  Th=.4;
