function ok=test_E01_current_layers()
%TEST_E01_CURRENT_LAYERS Explicit, fast numerical smoke test.
% Creates exactly ONE layered figure; not called by build_E01_simulink().
r=E01_current_layers(11);
v=r.current_uA;
assert(isequal(size(v),[11 2 5]), ...
    'Expected 11 Omega samples x two sources x five physical cases.');
assert(all(isfinite(v),'all')&&all(v>=0,'all'), ...
    'Averaged detector current must be finite and nonnegative.');
assert(numel(r.lines)==10 && isgraphics(r.figure,'figure'), ...
    'Missing interactive current layers.');
assert(isfile(r.csv) && isfile(r.figure_file), ...
    'Missing CSV or editable MATLAB figure.');
% Same power and nearly equal central wavelength -> similar ideal current.
assert(max(abs(v(:,1,1)-v(:,2,1)))<0.5, ...
    'Ideal LASER and ASE unexpectedly have different mean currents.');
% For DEMO default 1 ps, coherent LASER reflection is stronger than ASE.
i0=6; % -30..30, 11 points => 0 deg/s at index 6
dLaser=abs(v(i0,1,2)-v(i0,1,1));
dASE=abs(v(i0,2,2)-v(i0,2,1));
assert(dLaser>2*dASE, ...
    'Reflection suppression differs from default source coherence model.');
fprintf('PASS: 10 warstw i jeden wykres sredniego fotopradu I(Omega).\n');
fprintf('Skutki odbicia przy 0 deg/s: LASER %.5g uA, ASE %.5g uA.\n', ...
    dLaser,dASE);
ok=true;
end
