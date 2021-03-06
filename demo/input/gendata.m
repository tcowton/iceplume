% This script generates the input files for a trial MITgcm simulation using
% the 'IcePlume' package

% Cowton T, D Slater, A Sole, D Goldberg, P Nienow (2015). Modeling the
% impact of glacial runoff on fjord circulation and submarine melt rate
% using a new subgrid-scale parameterization for glacial plumes. Journal
% of Geophysical Research - Oceans.

% It is also necessary to complete the appropriate 'data' files etc.

% Tom Cowton, February 2015

%% Initial settings

% Accuracy of binary files
acc = 'real*8';

% Number of time levels for time varying forcing
nt = 1;

%% Gridding

% Dimensions of grid
nx=50;
ny=11;
nz=50;

% Cell resolution (m)
deltaX = 200;
deltaY = 200;
deltaZ = 10;

% x scale
delx = zeros(1,nx);
delx(:) = deltaX;
fid=fopen('delx.bin','w','b'); fwrite(fid,delx,acc);fclose(fid);

% y scale
dely = zeros(1,ny);
dely(:) = deltaY;
fid=fopen('dely.bin','w','b'); fwrite(fid,dely,acc);fclose(fid);


%% Bathymetry

% Vertical cell spacing (for T and S profiles)
zprof = -((0.5*deltaZ):deltaZ:((nz*deltaZ)-(0.5*deltaZ)));

% Bathymetry
bathymetry = zeros(nx,ny);
bathymetry(:) = -deltaZ*nz;
bathymetry(1,:) = 0; % glacier front
bathymetry(:,[1 end]) = 0; % fjord walls

% write bathymetry
fid=fopen('bathymetry.bin','w','b'); fwrite(fid,bathymetry,acc);fclose(fid);
%% Temperature and salinity profiles
% These are used to write initial conditions, boundary conditions etc

% Profiles are an idealised version of a Greenland fjord profile
z = -[0 100 350 400 500];
t1 = [0.2 0.2 1.7 1.5 1.1];
t(:,1) = interp1(z,t1,zprof,'cubic');

z = -[0 100 200 300 400 500];
s1 = [32 33.8 34.2 34.3 34.4 34.5];
s(:,1) = interp1(z,s1,zprof,'cubic');

%% Initial conditions

saltini = zeros(nx,ny,nz);
tempini = zeros(nx,ny,nz);

for i = 1:nz
    saltini(:,:,i) = s(i);
    tempini(:,:,i) = t(i);
end

fid=fopen('saltini.bin','w','b'); fwrite(fid,saltini,acc);fclose(fid);
fid=fopen('tempini.bin','w','b'); fwrite(fid,tempini,acc);fclose(fid);

%% Subglacial runoff

% Where (in the along fjord direction) is the glacier front?
icefront = 2;

% Define the velocity (m/s) of subglacial runoff as it enters the fjord.
% 1 m/s seems a reasonable value (results not sensitive to this value).
wsg = 1;

% Templates
runoffVel   = zeros(nx,ny);
runoffRad   = zeros(nx,ny);
plumeMask   = zeros(nx,ny);

%%% Define plume-type mask %%%
% 1 = ice but no plume (melting only)
% 2 = sheet plume (Jenkins 2011)
% 3 = half-conical plume (Cowton et al 2015)
% 4 = both sheet plume and half-conical plume (NOT YET IMPLEMENTED)
% 5 = detaching conical plume (Goldberg)

% POSITIVE values indicate ice front is orientated north-south
% NEGATIVE values indicate ice front is orientated east-west

% Define melting along the glacier front (located at fjord head)
plumeMask(icefront,2:(end-1)) = 1;

% The plume will be located in the fjord centre at the glacier
% front
plumeMask(icefront,6) = 3;

% Specify runoff (m^3/s)
runoff = 50;

% Define runoff velocity in each location (as specified above)
runoffVel(icefront,6) = wsg;

% Calculate channel radius to give runoff at velocity
runoffRad(icefront,6) = sqrt(2*runoff/(pi*wsg));

% Write files.
fid=fopen('runoffVel.bin','w','b'); fwrite(fid,runoffVel,acc);fclose(fid);
fid=fopen('runoffRad.bin','w','b'); fwrite(fid,runoffRad,acc);fclose(fid);
fid=fopen('plumeMask.bin','w','b'); fwrite(fid,plumeMask,acc);fclose(fid);

%% Boundary conditions

% Eastern boundary conditions (other boundaries closed in this example)

EBCu = zeros(ny,nz);
EBCs = zeros(ny,nz);
EBCt = zeros(ny,nz);

for i = 1:length(t)
        EBCt(:,i) = t(i);
        EBCs(:,i) = s(i);
end

% Apply barotropic velocity to balance input of runoff

fjordMouthCrossSection = -sum(bathymetry(end,:))*deltaY;
fjordMouthVelocity = runoff/fjordMouthCrossSection;

% Out-of-domain velocity is positive at eastern boundary
EBCu(:) = fjordMouthVelocity;

fid=fopen('EBCu.bin','w','b'); fwrite(fid,EBCu,acc);fclose(fid);
fid=fopen('EBCs.bin','w','b'); fwrite(fid,EBCs,acc);fclose(fid);
fid=fopen('EBCt.bin','w','b'); fwrite(fid,EBCt,acc);fclose(fid);

