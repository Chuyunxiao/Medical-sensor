% this code is writted by "Omid Ghahary" to read all data from 
% "The CTU-UHB Intrapartum Cardiotocography Database" located in
% "https://www.physionet.org/pn3/ctu-uhb-ctgdb/".
% by this file you can load this database in matlab format.
% for more information contanct me by this email address: 
% mg_omidy@yahoo.com

close all
clear
clc

Pname = 'dataset\';
fid = fopen('RECORDS.txt');
DataName = textscan(fid,'%d');
DataName = DataName{1};
fclose(fid);

N_files = length(DataName);
Data = repmat(struct('cParams',[],'FHR',[],'UC',[],'Time',[]), N_files,1);
for i = 1:N_files
    Name = num2str(DataName(i));

    fid = fopen([Pname Name '.hea']);
    z = fgetl(fid);
    fistline = sscanf(z, '%*s %d %d %d',[1,3]);
    nNrSignals = fistline(1);  % number of signals
    nFs = fistline(2);   % sample rate of data
    nNrSamples =fistline(3);   

    cHeader = struct([]);
    for k=1:nNrSignals

        z = fgetl(fid);
        if ~isempty(strfind(z,'FHR'))
            A = sscanf(z, '%*s %d %d(0)/bpm %d %d %d %d');
        elseif ~isempty(strfind(z,'UC'))
            A = sscanf(z, '%*s %d %d/nd %d %d %d %d');
        end

        cHeader(k).dformat = A(1);          % format; 
        cHeader(k).gain= A(2);              % number of integers per mV
        cHeader(k).bitres= A(3);            % bitresolution
        cHeader(k).zerovalue= A(4);         % integer value of ECG zero point
        cHeader(k).firstvalue= A(5);        % first integer value of signal (to test for errors)
        cHeader(k).checksum= A(6);          % checksum
    end;

    % read clinical information
    paramCounter = 0;
    eof = 0;
    cParams = [];

    while ~eof
        tline = fgetl(fid);
        if tline==-1
            eof = 1;
        else
            if ~isempty(tline) && ~strcmp(tline(2),'-')
                paramCounter = paramCounter+1;

                param_name = strtrim(tline(2:14));
                param_name(param_name == ' ') = '_';
                param_name(param_name == '.') = '';
                param_name(param_name == '(') = '_';
                param_name(param_name == ')') = '';
                param_name(param_name == '/') = '_';
                cParams.(param_name) = str2double(tline(15:end));
            end
        end
    end
%     disp(cParams)

    fclose(fid);

    % read data from a file
    fid = fopen([Pname Name , '.dat']);
    data = fread(fid, [nNrSignals, nNrSamples], 'uint16');
    fclose(fid);

    % convert for output
    FHR  = (data(1,:) - cHeader(1).zerovalue)/cHeader(1).gain;
    UC  = (data(2,:) - cHeader(2).zerovalue)/cHeader(2).gain;
    Time = (0:(nNrSamples-1))/nFs;
    
    Data(i).cParams = cParams;
    Data(i).FHR = FHR;
    Data(i).UC = UC;
    Data(i).Time = Time;
end
save('Data.mat', 'Data')
