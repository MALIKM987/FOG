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

rateLaser=laser.get('E01_predkosc');
rateAse=ase.get('E01_predkosc');
assert(all(isfinite(rateLaser.signals.values(:))) && ...
       all(isfinite(rateAse.signals.values(:))), ...
       'Lock-in output contains invalid samples.');

% Leave the saved model selecting LASER after the test.
set_param(switchPath,'sw','1');
save_system(model);
fprintf('PASS: model Simulink kompiluje sie i symuluje LASER oraz ASE.\n');
fprintf('Wyniki to przyblizenie obwiedni, nie pomiar.\n');
ok=true;
end
