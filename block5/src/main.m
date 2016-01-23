%% Main Script
% M4. Video Analysis Project
% This script computes all the tasks that are done for the block 5 of the
% project.
% 

%% Setup
setup;

%% Config
enable_homography = 'false'; % 'before', 'false'

%% Morpho to detect objects !! FALTA DEFINIRLA
morphoFunction = @detectionMorpho;

%% Learn foreground estimator and apply homography
% Primero aprendemos el modelo para estimar que son coches y que no.
learnDetector;


%% Read the rest of the sequence
idSequenceDemo = {setdiff(1:1700, idSequenceLearn{1}); setdiff(1:1570, idSequenceLearn{2})};

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
maxDistanceMeasurement = 50;
minDistanceMerge = 20;
mergePenalize = 16;
maxLive = 10;
stepLive = 2;
trackers = TrackingObjects(limits, maxDistanceMeasurement, minDistanceMerge, mergePenalize, maxLive, stepLive);

for iSeq = 1:length(inputFolders),
    for id=idSequenceDemo{iSeq}
            imName = sprintf('%06d', id);
            fileName = [ inputFolders{iSeq} , imName , fileFormat ];
            % Si esta activada aplicamos la tform a cada imagen
            im = imread( fileName );
            imOrig = im;
            
            % Aplicamos la homografia antes de la mascara
            if strcmp(enable_homography, 'before')
                im = imwarp(im, tform{iSeq});
            end
            
            % obtenemos la mascara
            mask = detector{iSeq}.detectForeground(im);
            
            % Aplicamos la homografia despues de la mascara
            if strcmp(enable_homography, 'after')
                mask = imwarp(mask, tform{iSeq});
            end
           
            %subplot(1,2,1), imshow(imOrig,[]), subplot(1,2,2), imshow(imOut,[]), pause(0.001);
            
            % Aplicamos el pipeline
            [objects, CC] = getCentroids(mask);
            trackers.checkMeasurements(objects, CC);
            
            positions = trackers.getTrackers();
            
            
            
            imshow(mask), hold on;
            %disp('----------');
            for i=1:length(positions)
                aux = positions{i};
                
                %aux
                
                plot(aux(1), aux(2), 'r*');
            end
            %disp('----------');
            hold off;
            pause(0.001);
            
    end
    
end