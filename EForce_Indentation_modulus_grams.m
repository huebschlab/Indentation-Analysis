% Use this code to get the toughness, elastic modulus, max stress, and max
% strain from mechanical testing.
%
%%Instructions
%It may be helpful to rename the .csv files to be names other than Specimen_RawData_#.csv before running.
%
% Run "Modulus_toughness_peak_forces.m" and select the raw data files to analyze. The code currently only works if the compressive stress is in kgf/cm^2, MPa, or kPa. If using different units, the conversion needs to be added to the switch at line 57
%
% After the stress-strain plot shows up, see if there was an increase of stress after the point of failure. If yes, select the appropriate option and choose the actual point of failure using the strain value of the failure.
%
% Next, input the start and end of the intial linear region. See if the plot and r-squared of the linear region are acceptable. If so, you may save and close. Otherwise, select to redo picking the linear region points.
%
% Automatically compile the data into an excel sheet using the "avg_MechData.m" code by selecting all of the .mat files saved in the folder titled "Compiled Data"







[files,pathname] = uigetfile('*.csv', 'Select One or More Files' , 'MultiSelect', 'on');


if isa(files, 'char') == 1
    total = 1;
else
    total = max(size(files));
end

count = 1;

nfiles = cell(1,total);

if ispc
    delim = '\';
elseif ismac
    delim = '/';
end


if contains(pathname, '.is_comp_RawData')
    npathname = pathname(1:end-17);
    movefile(pathname,npathname)
    pathname = [npathname delim];
end


% thickCheck = 0;
% while thickCheck == 0
%     thick = str2double(cell2mat(inputdlg('Height of Gel (mm)?')));
%     if ~isempty(thick) && isa(thick,'double') && thick > 0
%         thickCheck = 1;
%     end
% end


% shape = questdlg('Specimen Cross-Section Shape?','Shape','Rectangle','Circle','Circle');
%
% switch shape
%
%     case 'Rectangle'
%         rectlength = str2double(cell2mat(inputdlg('Length of Sample (mm)?')));
%         rectlength = .001.*rectlength; % to meters
%         rectwidth = str2double(cell2mat(inputdlg('Width of Sample (mm)?')));
%         rectwidth = .001.*rectwidth; % to meters
%         area = rectlength*rectwidth; %m^2
%     case 'Circle'
%         diamCheck = 0;
%         while diamCheck == 0
%             diameter = str2double(cell2mat(inputdlg('Diameter of Sample (mm)?')));
%             if ~isempty(diameter) && isa(diameter,'double') && diameter > 0
%                 diamCheck = 1;
%             end
%         end
%         diameter = .001 * diameter;
%         area = pi.*(diameter/2)^2;
%
% end

indentradius = str2double(cell2mat(inputdlg('Radius of Indentor (mm)')));

while count <= total
    % choose specific file
    tic
    if isa(files, 'char') == 1
        filename = files;
    else

        filename = files{1,count};
    end
    disp(filename);

    nfilename = filename(1:end-8);


    filedata = readcell([pathname filename],'DatetimeType','text','LineEnding','\r');
    [r,c] = find(cellfun(@isnumeric,filedata) == 1);
    c = unique(c);

    runique = unique(r);

    for i = 1:length(runique)
        numrow = sum(r(:) == runique(i));
        if numrow ~= length(c)
            runique(i) = 0;
        end
    end

    runique(runique == 0 ) = [];
    r = runique;



    filedata1 = filedata(r(1)-2:r(end),c(1):c(end));
    filedata1(cellfun(@(x) isa(x,'missing'), filedata1)) = {nan};
    gaps = cell2mat(cellfun(@isnan, filedata1(3:end,1), 'UniformOutput', false));
    gaps = find(gaps);
    gaps = gaps + 2;

    header = string(filedata(r(1)-2:r-1,c(1):c(end)));

    switch strtrim(header(2,3))
        case "N"
            conversion = 1;
        case "g"
            conversion = 0.0098;
            header(2,3) = "N";
        otherwise
            convsersion = 1;
    end



    fullTest = cell2mat(filedata1(3:end,:));

    correct0 = mean(fullTest(gaps(2)-1:gaps(3)-3,2));
    fullTest_cor = fullTest; fullTest_cor(:,2) = fullTest_cor(:,2) - correct0;
    fullTest_cor(:,3) = fullTest_cor(:,3)*conversion;

    sec1 = fullTest_cor(1:gaps(1)-3,:); % Initial indent to find surface
    sec2 = fullTest_cor(gaps(1)-1:gaps(2)-3,:); % Back up to top of surface
    sec3 = fullTest_cor(gaps(2)-1:gaps(3)-3,:); % Wait at top of surface for substrate to relax
    sec4 = fullTest_cor(gaps(3)-1:gaps(4)-3,:); % Indent surface prescribed amount
    sec5 = fullTest_cor(gaps(4)-1:end,:); % Wait at indented depth for any relaxation

    fullTest_cor_stitch = [sec1;sec2;sec3;sec4;sec5];

    E = 1000*(((9/16).*abs(sec5(:,3)))./((indentradius^(1/2)).*(abs(sec5(:,2)).^(3/2)))); %kPa

    E_mean = mean(E);

    fig = figure;
    ax = axes(fig);
    title(ax,nfilename(1:end-4),'Interpreter','none')
    xlabel(ax,strcat(strtrim(header(1,1))," (",strtrim(header(2,1)),")"))
    yyaxis(ax,'left')
    plot(ax,fullTest_cor_stitch(:,1),fullTest_cor_stitch(:,2));
    dispDiff = max(fullTest_cor_stitch(:,2)) - min(fullTest_cor_stitch(:,2));
    ylim([min(fullTest_cor_stitch(:,2))-(0.05*dispDiff) max(fullTest_cor_stitch(:,2))+(0.05*dispDiff)])
    yyaxis(ax,'right')
    plot(ax,fullTest_cor_stitch(:,1),fullTest_cor_stitch(:,3));
    ylabel(ax,strcat(strtrim(header(1,3))," (",strtrim(header(2,3)),")"))
    hold on
    plot(ax,fullTest_cor_stitch(:,1),smooth(fullTest_cor_stitch(:,3),50),'--k');
    yyaxis(ax,'left')
    ylabel(ax,strcat(strtrim(header(1,2))," (",strtrim(header(2,2)),")"))
    legend(ax,strcat(strtrim(header(1,2))," (",strtrim(header(2,2)),")")...
        ,strcat(strtrim(header(1,3))," (",strtrim(header(2,3)),")")...
        ,strcat("Smoothed ",strtrim(header(1,3))," (",strtrim(header(2,3)),")"))
    annotation(fig,'textbox',[.1339 .119 .334 .056],'String',strcat("Elastic Modulus: ",num2str(E_mean),"kPa"))


    dirname = pathname;


    if isequal(exist([dirname  nfilename], 'dir'),0)
        mkdir([dirname  nfilename])
        dirname = ([dirname nfilename delim]);
    else
        dirname = ([dirname nfilename delim]);
    end



    saveas(fig, [dirname nfilename '_Indent Fig.jpg'])
    savefig(fig, [dirname nfilename '_Indent Fig.fig'])


    if isequal(exist([pathname  'Indent Data'], 'dir'),0)
        mkdir([pathname  'Indent Data'])
        dirname = ([pathname 'Indent Data' delim]);
    else
        dirname = ([pathname 'Indent Data' delim]);
    end

    save([dirname nfilename '.mat'], 'E_mean')

    
    count = count + 1;




end

%%
count2 = 1;
addpath(dirname);
tic

files2 = dir(fullfile(dirname, '*.mat'));
nfiles2 = {};
for i = 1:length(files2)
    nfiles2(i) = {files2(i).name};
end

total = length(nfiles2);
splitpath = strsplit(pathname, delim);

% create empty arrays/vectors to be filled
filenames = {}; % Added by Soore - empty cell array to be filled with filenames
elasticModulus = zeros(total,1);



while count2 <= total

    filename2 = nfiles2{1,count2};


    load([dirname filename2]);
    disp(filename2)

    filenames{count2} = filename2(1:length(filename2)-4);
    elasticModulus(count2) = E_mean;
    

    count2 = count2 + 1;
end

filenames;
elasticModulus;


% Create and Save Table into Folder where Data is Taken From

headers = {'filename','Elastic Modulus'};
units = {' ','kPa'};
name = char(splitpath(length(splitpath)-1));
writecell(headers,[dirname name '.xlsx'],'Sheet',1,'Range','A1');
writecell(units,[dirname name '.xlsx'],'Sheet',1,'Range','A2');
writecell(filenames',[dirname name '.xlsx'],'Sheet',1,'Range','A3');
writematrix(elasticModulus,[dirname name '.xlsx'],'Sheet',1,'Range','B3');



