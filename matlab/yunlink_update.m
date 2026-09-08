function result = yunlink_update(varargin)
%YUNLINK_UPDATE Upgrade the Python SDK and optional YunLink binding.
%   With no arguments this opens the same setup wizard as yunlink_setup.
if nargin == 0
    result = yunlink_setup();
else
    result = yunlink_setup(varargin{:});
end
end
