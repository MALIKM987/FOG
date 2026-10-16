function ok = test_E01_simulink()
%TEST_E01_SIMULINK Compile, simulate and check the actual block model.
% Run from MATLAB R2023b (requires Simulink):
%   addpath('research/E01_basic_FOG/simulations/matlab');
%   assert(test_E01_simulink())
%
% This test runs LOCALLY in MATLAB. It does not test the real instrument.
here=fileparts(mfilename('fullpath'));
addpath(here);
model='FOG_E01_SIMULINK';

if ~bdIsLoaded(model)
    build_E01_simulink();
end
switchPath=[model '/WYBOR ZRODLA - kliknij 2x'];
previousSource=get_param(switchPath,'sw');
straySwitch=[model '/Odbicie 0=wyl 1=wl'];
hasStray=(getSimulinkBlockHandle(straySwitch)~=-1);
if hasStray
    previousStray=get_param(straySwitch,'Value');
    restore=onCleanup(@()restoreModes( ...
        switchPath,previousSource,straySwitch,previousStray));
    % Noise test MUST isolate source RIN from parasitic coherent field.
    set_param(straySwitch,'Value','0');
else
    restore=onCleanup(@()set_param(switchPath,'sw',previousSource));
end
extraEffects=E01_disable_effects_for_test(model,false);
assert(~isempty(find_system(model,'SearchDepth',1, ...
    'Name','Cewka SMF - CW i CCW')), ...
    'One shared coil subsystem missing.');
assert(~isempty(find_system(model,'SearchDepth',1, ...
    'Name','Sprzegacz 2x2 - powrot')), ...
    'Return coupler subsystem missing.');

% Model compile verifies library blocks, data types and port connections.
set_param(model,'SimulationCommand','update');

% Manual Switch: '1' upper input LASER; '0' lower input ASE.
set_param(switchPath,'sw','1');
laser=sim(model);
set_param(switchPath,'sw','0');
ase=sim(model);

pdLaser=laser.get('E01_prad_fotodiody');
pdAse=ase.get('E01_prad_fotodiody');
vLaser=pdLaser.signals.values(:);
vAse=pdAse.signals.values(:);
assert(numel(vLaser)>100 && numel(vLaser)==numel(vAse), ...
    'Incorrect photodiode sample count.');
assert(all(isfinite(vLaser)) && all(isfinite(vAse)), ...
    'Detected nonfinite photodiode values.');
assert(all(vLaser>=-1e-12) && all(vAse>=-1e-12), ...
    'Photodiode detected negative optical power.');
assert(max(abs(vLaser-vAse))>1e-9, ...
    'Source switch did not alter source-specific detector waveform.');

% The diagnostic subtracts the noiseless Sagnac current. In the given
% DEMO parameters the ASE optical-beat RIN creates greater fluctuations
% than the illustrative laser RIN. Exact values are NOT lab predictions.
rLaser=laser.get('E01_fluktuacje_fotodiody_uA');
rAse=ase.get('E01_fluktuacje_fotodiody_uA');
rl=rLaser.signals.values(:);
ra=rAse.signals.values(:);
assert(all(isfinite(rl)) && all(isfinite(ra)), ...
    'Source-noise diagnostic contains nonfinite samples.');
rmsLaser=sqrt(mean(rl.^2));
rmsAse=sqrt(mean(ra.^2));
assert(rmsAse>5*rmsLaser, ...
    'Expected ASE source-noise RMS to exceed LASER for DEMO RIN.');
fprintf('RMS fluktuacji fotodiody: LASER %.6g uA, ASE %.6g uA.\n', ...
    rmsLaser,rmsAse);

rateLaser=laser.get('E01_predkosc');
rateAse=ase.get('E01_predkosc');
assert(all(isfinite(rateLaser.signals.values(:))) && ...
       all(isfinite(rateAse.signals.values(:))), ...
       'Lock-in output contains invalid samples.');

% Restore the existing schematic state, WITHOUT saving our test settings.
clear restore
fprintf('PASS: model Simulink kompiluje sie i symuluje LASER oraz ASE.\n');
fprintf('Test RIN wykonano przy wylaczonym odbiciu pasozytniczym.\n');
fprintf('Wyniki to przyblizenie obwiedni, nie pomiar.\n');
ok=true;
end

function restoreModes(sw,oldSource,stray,oldStray)
set_param(sw,'sw',oldSource);
set_param(stray,'Value',oldStray);
end
