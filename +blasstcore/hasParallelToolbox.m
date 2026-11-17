function available = hasParallelToolbox()
%HASPARALLELTOOLBOX Check PCT installation and license without starting pool.
% SPDX-License-Identifier: Apache-2.0
available = false;
try
    available = ~isempty(ver('parallel')) && ...
        logical(license('test','Distrib_Computing_Toolbox'));
catch
    available = false;
end
end
