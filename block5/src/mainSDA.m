%% Main Script
% M4. Video Analysis Project
% This script computes all the tasks that are done for the block 5 of the
% project.
% 

%% Setup
setup;
storeFigures = true;
%% Config
enable_homography = 'false'; % 'before', 'false'

%% Morpho in learn Detector
morphoForegroundFunction = @foregroundMorpho;

%% Morpho to detect objects
morphoObjDetectionFunction = @detectionMorpho;

%% Learn foreground estimator and apply homography
% Primero aprendemos el modelo para estimar que son coches y que no.
learnDetector;


%% Read the rest of the sequence
idSequenceDemo = {setdiff(1:1700, idSequenceLearn{1}); setdiff(1:1570, idSequenceLearn{2}); ...
    1:168; 1:262; 1:193; 1:232};


addpath(genpath('Wang2013/'));
% El pipeline debera ser:
% - Segmentar la imagen (usando el detector de foreground)
% - Aplicar morphologia para separar varios coches (multipleObjectsMorpho)
% - Aplicar un algoritmo de componentes conexas
% - Aplicar kalman por cada componente conexa.
%       a) Si aparece una nueva componente conexa, se debera comprovar si
%       esta cerca de algun filtro de kalman (con distance), si esta muy
%       lejos querra decir que es un nuevo coche.
%       b) Las medidas que se hagan deben superar un threshold  (por
%       ejemplo fillratio de puntos segmentados) si este es muy peque�o no
%       se considera medida. Si pasa el suficiente tiempo (X frames), se
%       supondra que el coche ha desaparecido y ya no hace falta seguirlo
%       O del mismo modo que si la estimaci�n hace que se salga de los
%       rangos de la imagen.
limits = [0, sizeIm(2); 0, sizeIm(1)];
maxDistanceMeasurement = 20;
minDistanceMerge = 20;
mergePenalize = 16;
maxLive = 10;
stepLive = 1;
timeThres = 16;
timeStopThres = 15;
fps = 30;

historialSeq = cell(2,1);

showResults = true;
numShowResults = 10;

for iSeq = 1:length(inputFolders),
    % Set velocityEstimation for each sequence
    trackers = TrackingObjectsSDA(limits, maxDistanceMeasurement, minDistanceMerge, mergePenalize, maxLive, stepLive, timeThres, timeStopThres, velocityEstimator(1), fps);
    trackers = trackers.setVelocityEstimator(velocityEstimator(iSeq));
    folderName = ['..' filesep 'figures' filesep int2str(iSeq) filesep];
    if ~exist(folderName,'dir')
        mkdir(folderName);
    end
    
    for id=idSequenceDemo{iSeq}           
        imName = sprintf('%06d', id);
        fileName = [inputFolders{iSeq}, imName, fileFormat];
        fileName = strrep(fileName, '\', filesep);
        % Si esta activada aplicamos la tform a cada imagen
        im = imread(fileName);

        % obtenemos la mascara
        mask = detector{iSeq}.detectForeground(im);
        mask = morphoObjDetectionFunction(mask);
        %imshow(mask);
        %pause(0.0001);

        % Aplicamos el pipeline
        trackers.checkMeasurements(mask, im);

        positions = trackers.getTrackers(im, homographySeq{iSeq});

        % Actualizamos el historial
        trackers.historialTrackers(positions)
        
%         if mod(id, numShowResults)==0
%             id
%             % Mostrar los resultados onlive
%             if showResults
                trackers.showTrackers(im, mask, positions);
                if storeFigures
                    saveas(1, [folderName int2str(id) '.jpg']) ;
                end
%             end
%         end
            
    end
       
    % Guardamos el historial de cada sequencia
    historialSeq{iSeq} = trackers.getHistorial();
    % displayHistorial(historialSeq{iSeq});
    
end