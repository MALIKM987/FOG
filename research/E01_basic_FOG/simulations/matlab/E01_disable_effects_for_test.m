function restore=E01_disable_effects_for_test(model,includeReflection)
%E01_DISABLE_EFFECTS_FOR_TEST Temporarily disable Rayleigh/Kerr for tests.
% Optional includeReflection=true also temporarily disables stray reflection.
% The original values are restored on scope exit via onCleanup.
if nargin<2,includeReflection=false;end
names={'Rayleigh 0=wyl 1=wl','Kerr 0=wyl 1=wl'};
if includeReflection
    names=[{'Odbicie 0=wyl 1=wl'},names];
end
paths={};prior={};
for k=1:numel(names)
    p=[char(model) '/' names{k}];
    if getSimulinkBlockHandle(p)~=-1
        paths{end+1}=p; %#ok<AGROW>
        prior{end+1}=get_param(p,'Value'); %#ok<AGROW>
        set_param(p,'Value','0');
    end
end
restore=onCleanup(@()revert(paths,prior));
end

function revert(paths,prior)
for k=1:numel(paths)
    set_param(paths{k},'Value',prior{k});
end
end
