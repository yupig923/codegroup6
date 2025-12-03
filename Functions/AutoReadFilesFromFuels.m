function read_file_results = AutoReadFilesFromFuels(fuel)
% AutoReadFilesFromFuels
% ReadDataFIles For the given fuel
%
% Inputs:
%Fuel: Name as the folder names
% Output:
%   read_file_results : struct containing:
%FAstFiles
%Slowfiles
%CA
%Load


% Build folder path
folder = fullfile('Data', fuel);

% Load files
fastfiles = dir(fullfile(folder, '*fdaq.txt'));
slowfiles = dir(fullfile(folder, '*sdaq.txt'));

% Add relative paths
for i = 1:numel(fastfiles)
    fastfiles(i).relpath = fullfile('Data', fuel, fastfiles(i).name);
end
for i = 1:numel(slowfiles)
    slowfiles(i).relpath = fullfile('Data', fuel, slowfiles(i).name);
end

% Initialize arrays
numFiles = numel(fastfiles);
CA_vals  = zeros(numFiles,1);
P_vals   = zeros(numFiles,1);

% Extract CA and P from filenames
for k = 1:numFiles
    % Extract CA (e.g., "CA50-")
    tokensCA = regexp(fastfiles(k).name, 'CA(\d+)-', 'tokens');
    if ~isempty(tokensCA)
        CA_vals(k) = str2double(tokensCA{1}{1});
    else
        CA_vals(k) = NaN;
    end

    % Extract Percent (e.g., "-20P")
    tokensP = regexp(fastfiles(k).name, '-(\d+)P', 'tokens');
    if ~isempty(tokensP)
        P_vals(k) = str2double(tokensP{1}{1});
    else
        P_vals(k) = NaN;
    end
end

% Sort by CA → P
[~, idx] = sortrows([CA_vals, P_vals]);

fastfiles = fastfiles(idx);
slowfiles = slowfiles(idx);
CA_vals   = CA_vals(idx);
P_vals    = P_vals(idx);

% Package output cleanly in a struct
read_file_results.fastfiles = fastfiles;
read_file_results.slowfiles = slowfiles;
read_file_results.CA_vals   = CA_vals;
read_file_results.P_vals    = P_vals;

end