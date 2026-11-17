function finishSettingsDialog(src, ~, accepted)
%FINISHSETTINGSDIALOG Resume BLASST settings modal window.
% UI callback helper; method/algorithm parameters are not changed here.
% SPDX-License-Identifier: Apache-2.0
h = ancestor(src,'figure');
if isempty(h) || ~isgraphics(h)
    return
end
setappdata(h,'BLASSTSettingsAccepted',logical(accepted));
uiresume(h);
end
