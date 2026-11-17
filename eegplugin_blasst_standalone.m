function versionstr = eegplugin_blasst_standalone(fig, trystrs, catchstrs)
%EEGPLUGIN_BLASST_STANDALONE Add BLASST to EEGLAB's Tools menu.
% SPDX-License-Identifier: Apache-2.0
versionstr = '1.0.0';
if nargin ~= 3
    error('BLASST:EEGLAB', 'EEGLAB must invoke this plugin with three arguments.');
end
toolsmenu = findobj(fig,'tag','tools');
if isempty(toolsmenu)
    error('BLASST:EEGLAB', 'Cannot find the EEGLAB Tools menu.');
end
callback = [trystrs.no_check, ...
    '[EEG, LASTCOM] = pop_blasst_standalone(EEG);', ...
    catchstrs.store_and_hist];
uimenu(toolsmenu(1),'Label','BLASST', ...
    'ForegroundColor',[0 0 0.4], ...
    'Separator','on','Callback',callback);
end
