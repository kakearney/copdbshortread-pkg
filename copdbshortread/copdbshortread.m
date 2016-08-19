function A = copdbshortread(file)
%COPDBSHORTREAD Reads a short-format file from the NMFS Copepod database
%
% Input variables:
%
%   file:   filename of short-format COPEPOD database file
%
% Output variables:
%
%   A:      n x 1 structure, where n is the number of observations in the
%           file, with the following fields:  
% 
%           SHP_CRUISE:     NODC ship code and NMFS-COPEPOD cruise
%                           identifier 
% 
%           YEAR:           year of the tow or sample
% 
%           MON:            month of the observatin/measurement
% 
%           DAY:            GMT-based day of the tow or sample
% 
%           TIMEloc:        LOCAL time of the tow or sample (decimal hours)
% 
%           LATITUDE:       latitude of the tow or sample (+ = North, 
%                           - = South)
% 
%           LONGITDE:       longitude of the tow or sample (+ = East, 
%                           - = West) 
% 
%           UPPER_Z:        upper depth (range) of the tow or sample
% 
%           LOWER_Z:        lower depth (range) of the tow or sample
%
%           T:              tow type
%                           V:  vertical
%                           H:  horizontal
%                           O:  oblique
% 
%           MESH:           net mesh size (micrometers - um) used
%
%           NMFS_PGC:       COPEPOD Plankton Grouping Code (PGC) for the
%                           observation 
% 
%           ITIS_TSN:       ITIS Taxonomic Serial Number (TSN) (if < 0,
%                           then  NMFS-COPEPOD-SN)  
%
%           PSC:            COPEPOD Plankton [Life] Staging Code for the
%                           observation 
%                           0 = unspecified
%                           1 = adult or sub-adult
%                           2 = juvenile or larvae
%                           3 = nauplius-like 4 = eggs 5 = incomplete body
%                               fragments
% 
%           V:              Type of measurement in the Count/Biomass Field
%                           B = Biomass
%                           C = Count,
%                           L = Biomass (where large plankter (e.g.
%                               jellyfish) were NOT removed before
%                               measurement)
%
%           VALUE_per_volu: per-water-volume count or biomass measurement
%                           of the observation  
%
%           VALUE_per_area: per-surface-area count or biomass measurement
%                           of the observation  
%
%           VALUE_[]_UNITS: units for count or biomass measurement
%
%           VALUE_[]_F1:    COPEPOD-2007 global-annual range flag
%
%           VALUE_[]_F2:    COPEPOD-2007 basin-annual range flag
%
%           VALUE_[]_F3:    COPEPOD-2007 basin-seasonal range flag
%
%           VALUE_[]_F4:    COPEPOD-2007 basin-monthly range flag
% 
%           SCIENTIFIC_NAME:test description of the observation
% 
%           RECORD_ID:      NMFS-COPEPOD unique record identifier
% 
%           DATASET_ID:     NMFS-COPEPOD data set identifier
%
%           SHIP:           numeric ship (vessel) identifier
%
%           PROJ:           numeric project identifier


% Figure out number of comment lines at top (indicated by #)

fid = fopen(file, 'rt');
data = textscan(fid, '%s', 20, 'delimiter', '\n'); % Shouldn't be more than a few lines, so 20 is safe
fclose(fid);
data = data{1};

iscomment = strncmp(data, '#', 1);
headerline = find(iscomment, 2, 'last');
headers = data{headerline(1)};
headers = regexprep(headers, '^#', '');
hasextracomma = strcmp(headers(end), ',');
headers = regexp(headers, ',', 'split');

nheader = sum(iscomment);

% Make some adjustment to header names, since not all are valid as field
% names, and some are repeats

headers = regexprep(headers, '-', '_');

isval = strncmp(headers, 'VALUE', 5);
validx = find(isval);
isunit = strcmp(headers, 'UNITS');
unitidx = find(isunit);
isf = regexpfound(headers, '^F\d$');
fidx = find(isf);

idx = arrayfun(@(x) find(x > validx, 1, 'last'), unitidx);
unitfld = cellfun(@(x) sprintf('%s_UNITS', x), headers(validx(idx)), 'uni', 0);

headers(isunit) = unitfld;

idx = arrayfun(@(x) find(x > validx, 1, 'last'), fidx);
ffld = cellfun(@(x,y) sprintf('%s_%s', x,y), headers(validx(idx)), headers(fidx), 'uni', 0);

headers(isf) = ffld;

issname = regexpfound(headers, 'SCIENTIFIC NAME');
headers{issname} = 'SCIENTIFIC_NAME';

headers = matlab.lang.makeValidName(headers, 'replacementstyle', 'delete');

% Format (speeds up considerably if I specify which are numeric)

numfld = {'YEAR', 'MON', 'DAY', 'TIMEgmt', 'TIMEloc', 'LATITUDE', 'LONGITDE', ...
    'UPPER_Z', 'LOWER_Z', 'GEAR', 'MESH', 'NMFS_PGC', 'ITIS_TSN', 'MOD', ...
    'LIF', 'PSC', 'SEX', 'Original_VALUE', 'VALUE_per_volu', ...
    'VALUE_per_volu_F1', 'VALUE_per_volu_F2', 'VALUE_per_volu_F3', ...
    'VALUE_per_volu_F4', 'VALUE_per_area', 'VALUE_per_area_F1', ...
    'VALUE_per_area_F2', 'VALUE_per_area_F3', 'VALUE_per_area_F4'};
fmt = cell(size(headers));
[fmt{:}] = deal('%s');
[fmt{ismember(headers, numfld)}] = deal('%f');
fmt = [fmt{:}];

% Read the data

A = readtable(file, 'delimiter', ',', 'headerlines', nheader, 'format', fmt, 'treatasempty', 'null');
A.Properties.VariableNames = headers;

if hasextracomma
    A = A(:,1:end-1);
end


% data = readtext(file, ',', '', '');
% iscomment = strncmp(data(:,1), '#', 1);
% 
% % Assume second-to-last row of comments is column names
% 
% headerline = find(iscomment, 2, 'last');
% headers = data(headerline(1),:);
% 
% headers = regexprep(headers, '^#', '');
% 
% % Make some adjustment to header names, since not all are valid as field
% % names, and some are repeats
% 
% headers = regexprep(headers, '-', '_');
% 
% isval = strncmp(headers, 'VALUE', 5);
% validx = find(isval);
% isunit = strcmp(headers, 'UNITS');
% unitidx = find(isunit);
% isf = regexpfound(headers, '^F\d$');
% fidx = find(isf);
% 
% idx = arrayfun(@(x) find(x > validx, 1, 'last'), unitidx);
% unitfld = cellfun(@(x) sprintf('%s_UNITS', x), headers(validx(idx)), 'uni', 0);
% 
% headers(isunit) = unitfld;
% 
% idx = arrayfun(@(x) find(x > validx, 1, 'last'), fidx);
% ffld = cellfun(@(x,y) sprintf('%s_%s', x,y), headers(validx(idx)), headers(fidx), 'uni', 0);
% 
% headers(isf) = ffld;
% 
% issname = regexpfound(headers, 'SCIENTIFIC NAME');
% headers{issname} = 'SCIENTIFIC_NAME';
% 
% headers = regexprep(headers, '[^a-zA-Z0-9_]*', '_'); % Anything non alphanumeric or underscore becomes underscore
% 
% % Parse data
% 
% data = data(~iscomment,:);
% 
% ndata = size(data,1);
% 
% % 
% % fields = {'cruise', 'year', 'month', 'day', 'time', 'lat', 'lon', 'zupper', ...
% %           'zlower', 'mesh', 'tsn', 'bgc', 'bsc', 'type', 'count', 'unit', ...
% %           'qf', 'name', 'record', 'dataset'};
%       
% A = cell2struct(data, headers, 2);
