function out = openTermk(t,Tw,te,alphaa,omgg,k)
out = imag(exp(1i*omgg*t).*openI5(t,Tw,te,alphaa,omgg,k) ...
    -exp(-1i*omgg*t).*openI5(t,Tw,te,alphaa,-omgg,k)).*exp(alphaa*t)/2;