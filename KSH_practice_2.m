%% Matlabworks - ERS SAR Raw Data Extraction and Image Formation
% https://kr.mathworks.com/help/radar/ug/ers-sar-raw-data-extraction-and-image-formation.html
% 

%% Download Dataset

outputFolder = pwd;
dataURL = ['https://ssd.mathworks.com/supportfiles/radar/data/' ...
    'ERSData.zip'];
helperDownloadERSData(outputFolder,dataURL);

