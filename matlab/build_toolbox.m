function outputFile = build_toolbox(outputFile)
%BUILD_TOOLBOX Package this directory as a MATLAB Toolbox.
if nargin < 1
    outputFile = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'dist', 'yunlink-sunray-matlab.mltbx');
end

root = fileparts(mfilename('fullpath'));
outputDirectory = fileparts(outputFile);
if ~isempty(outputDirectory) && ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
opts = matlab.addons.toolbox.ToolboxOptions(root, 'yunlink-sunray');
opts.ToolboxName = 'YunLink Sunray MATLAB Support';
opts.ToolboxVersion = '1.1.0';
opts.AuthorName = 'YunDrone Team';
opts.Summary = 'MATLAB wrappers for controlling Sunray vehicles through YunLink';
opts.Description = opts.Summary;
opts.OutputFile = outputFile;
opts.MinimumMatlabRelease = 'R2026a';
matlab.addons.toolbox.packageToolbox(opts);
fprintf('Created %s\n', outputFile);
end
