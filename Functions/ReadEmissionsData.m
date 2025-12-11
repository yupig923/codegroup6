function [emissions_data]=ReadEmissionsData(fuel)

volperc = 0.01; % Emissions are in volume percentages
ppm     = 1e-6;


folder = fullfile('Data', fuel);
filename = fullfile(folder,'emissions.txt');

delimiter = ','; % Used normal comma
sort_columns = {'CA_exp', 'Load'}; 

fprintf('Attempting to read data from: %s\n', filename);


    % Read the data into a MATLAB table
    opts = delimitedTextImportOptions('NumVariables', 8);
    opts.Delimiter = delimiter;
    opts.VariableNames = {'Load', 'CA_exp', 'CO_vol', 'CO2_vol', 'HC_ppm', 'O2_vol', 'NOx_ppm', 'Lambda'};
    opts.VariableTypes = {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'};

    % Read the data
    EmissionsTable = readtable(filename, opts);

    fprintf('Successfully read %d data rows.\n\n', size(EmissionsTable, 1));

    % Sort the data based on the specified columns: CA_exp then Load.
    SortedEmissionsTable = sortrows(EmissionsTable, sort_columns);

        % 3. Extract Load and CA_exp vectors from the sorted table
    Load_vals   = SortedEmissionsTable.Load';
    Ca_exp_vals = SortedEmissionsTable.CA_exp';

    % 4. Convert the table rows into the required structure array
    numRows = height(SortedEmissionsTable);
    emissions_data = struct('CO', {}, 'CO2', {}, 'HC', {}, 'O2', {}, 'NOx', {}, 'lambda', {});
    
    for k = 1:numRows
        % Apply unit conversions while assigning to the structure
        new_data = struct();
        new_data.CO     = SortedEmissionsTable.CO_vol(k) * volperc;
        new_data.CO2    = SortedEmissionsTable.CO2_vol(k) * volperc;
        new_data.HC     = SortedEmissionsTable.HC_ppm(k) * ppm;
        new_data.O2     = SortedEmissionsTable.O2_vol(k) * volperc;
        new_data.NOx    = SortedEmissionsTable.NOx_ppm(k) * ppm;
        new_data.lambda = SortedEmissionsTable.Lambda(k);

        emissions_data(k) = new_data;
    end

