function test_blasst_gui_presentation()
%TEST_BLASST_GUI_PRESENTATION Verify menu integration and GUI default source.
% Run in MATLAB Desktop after adding the plugin directory to the path.
% The user should also open the actual modal dialog and inspect its colors.
% SPDX-License-Identifier: Apache-2.0

root = fileparts(fileparts(mfilename('fullpath')));
menuSource = fileread(fullfile(root,'eegplugin_blasst_standalone.m'));
wrapperSource = fileread(fullfile(root,'pop_blasst_standalone.m'));
dialogSource = fileread(fullfile(root,'+blasstdispatch','settingsDialog.m'));
assert(contains(menuSource,'''Label'',''BLASST'''));
assert(contains(wrapperSource,'''Inf'',''serial'',''optimized'''));
assert(~contains(wrapperSource,'defaultMode = ''parallel'''));
assert(contains(dialogSource,'eeGLABBackground = [0.66 0.76 1]'));
assert(contains(dialogSource,'eeGLABForeground = [0 0 0.4]'));
assert(contains(dialogSource,'eeGLABInputForeground = [0 0 0]'));
assert(contains(dialogSource,'eeGLABButtonBackground = [0.93 0.96 1]'));
assert(count(dialogSource,'''BackgroundColor'',eeGLABButtonBackground,''ForegroundColor'',eeGLABForeground')==2);
assert(count(dialogSource,'''BackgroundColor'',''white'',''ForegroundColor'',eeGLABInputForeground')==3);
assert(contains(menuSource,'''ForegroundColor'',[0 0 0.4]'));

% Exercise actual EEGLAB Tools-menu registration in a standalone figure.
f = figure('Visible','off','Name','BLASST menu regression fixture');
cleanup = onCleanup(@() delete(f)); %#ok<NASGU>
uimenu(f,'Label','Tools','Tag','tools');
trys = struct('no_check','');
catchs = struct('store_and_hist','');
version = eegplugin_blasst_standalone(f,trys,catchs);
assert(strcmp(version,'1.0.0'));
menu = findobj(f,'Type','uimenu','Label','BLASST');
assert(numel(menu)==1);
assert(isequal(get(menu,'ForegroundColor'),[0 0 0.4]));
assert(contains(get(menu,'Callback'),'pop_blasst_standalone'));
fprintf('PASS BLASST GUI: menu label, serial/optimized defaults, palette.\n');
end
