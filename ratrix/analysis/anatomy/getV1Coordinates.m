function x=getV1Coordinates(plotOn)
% returns 3d points of the surface of an "V1" volume


 %some eye-balled points from paxinos and watson
           %     AP   ML   Z
           x=[ -5.6 -3.4 -0.6;
               -5.6 -4.2 -0.8;
               -5.6 -4.8 -1.0;
               -5.6 -4.5 -2.0;
               -5.6 -4.2 -2.6;
               -5.6 -3.8 -2.4;
               -5.6 -3.2 -2.2;
               -5.6 -3.3 -1.5;
               -5.8 -3.0 -0.6;
               -5.8 -3.8 -0.8;
               -5.8 -4.6 -1.0;
               -5.8 -5.6 -1.4;
               -5.8 -5.1 -2.0;
               -5.8 -4.8 -2.9;
               -5.8 -4.4 -2.6;
               -5.8 -3.2 -2.2;
               -5.8 -2.8 -2.0;
               -5.8 -2.9 -1.5;
               -6.0 -3.1 -0.6;
               -6.0 -4.2 -0.9;
               -6.0 -5.4 -1.4;
               -6.0 -5.0 -2.0;
               -6.0 -4.6 -2.8;
               -6.0 -3.6 -2.6;
               -6.0 -2.6 -2.4;
               -6.0 -2.9 -1.5;
               -6.3 -2.6 -0.4;
               -6.3 -3.8 -0.6;
               -6.3 -5.2 -1.0;
               -6.3 -4.6 -2.0;
               -6.3 -4.4 -2.6;
               -6.3 -2.3 -1.8;
               -6.3 -2.4 -1.2;
               -6.7 -2.3 -0.4;
               -6.7 -3.8 -0.6;
               -6.7 -5.0 -1.2;
               -6.7 -4.5 -2.0;
               -6.7 -4.1 -2.6;
               -6.7 -3.2 -2.2;
               -6.7 -2.0 -1.8;
               -6.7 -2.2 -1.2;
               -6.8 -2.0 -0.6;
               -6.8 -3.7 -0.7;
               -6.8 -5.2 -1.4;
               -6.8 -4.8 -2.0;
               -6.8 -4.2 -3.0;
               -6.8 -3.0 -2.4;
               -6.8 -2.0 -2.0;
               -6.8 -2.0 -1.5;
               -7.3 -1.7 -0.6;
               -7.3 -3.0 -0.6;
               -7.3 -4.1 -0.8;
               -7.3 -5.6 -1.6;
               -7.3 -4.8 -2.4;
               -7.3 -4.4 -3.0;
               -7.3 -3.4 -2.2;
               -7.3 -2.0 -1.8;
               -7.3 -1.8 -1.1;
               -7.6 -2.0 -0.7;
               -7.6 -4.0 -1.0;
               -7.6 -5.4 -1.7;
               -7.6 -4.8 -2.4;
               -7.6 -4.2 -3.2;
               -7.6 -3.2 -2.4;
               -7.6 -2.2 -2.0;
               -7.6 -2.1 -1.5;
               -8.0 -1.4 -1.0;
               -8.0 -2.0 -0.9;
               -8.0 -3.2 -1.0;
               -8.0 -5.2 -1.8;
               -8.0 -4.4 -2.6;
               -8.0 -4.0 -3.0;
               -8.0 -3.0 -2.4;
               -8.0 -2.8 -2.4;
               -8.0 -2.0 -1.6;
               -8.3 -1.0 -1.2;
               -8.3 -2.0 -0.8;
               -8.3 -3.3 -0.9;
               -8.3 -4.6 -1.6;
               -8.3 -4.0 -2.4;
               -8.3 -3.6 -3.0;
               -8.3 -2.8 -2.4;
               -8.3 -2.0 -1.8;
               -8.3 -1.4 -1.4;
               -8.7 -0.4 -1.9;
               -8.7 -1.0 -1.4;
               -8.7 -2.0 -1.2;
               -8.7 -3.8 -1.4;
               -8.7 -3.4 -2.0;
               -8.7 -3.0 -2.8;
               -8.7 -2.0 -2.3;
               -8.7 -1.0 -1.8;
               -8.8 -1.0 -2.5;
               -8.8 -0.4 -2.0;
               -8.8 -1.0 -1.5;
               -8.8 -2.4 -1.1;
               -8.8 -4.2 -1.6;
               -8.8 -3.6 -2.2;
               -8.8 -3.0 -2.8;
               -8.8 -2.2 -2.4;
               -8.8 -1.6 -2.3;
               -9.2 -1.6 -2.4;
               -9.2 -1.0 -1.8;
               -9.2 -2.5 -1.1;
               -9.2 -4.4 -1.7;
               -9.2 -4.2 -2.0;
               -9.2 -3.4 -2.8;
               -9.2 -2.7 -2.5];