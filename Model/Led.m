classdef Led < handle
    %% LED Class: Defines the luminance and chromaticity of a single LED
    % This class reads an XML file and extracts LED properties such as:
    % - Part Name
    % - Luminous Intensity (Min & Max)
    % - Dominant Wavelength (Min & Max)
    % - Far Field Pattern
    
    properties
        PartName string                % Name of the LED Part
        LuminousIntensity(2,1) double  % Peak Intensity [Min; Max] in cd
        DominantWavelength(2,1) double % Dominant Colour [Min; Max] in nm
        FarFieldPattern(:,1) double    % Vector representing far-field light distribution
    end
    
    methods
        %% Constructor
        function obj = Led(xmlFilePath)
            % Constructor: Reads LED properties from an XML file
            % Inputs:
            %   xmlFilePath - Path to the XML file containing LED specifications
            
            if nargin == 0
                error('XML file path must be provided.');
            end
            
            if ~isfile(xmlFilePath)
                error('File does not exist: %s', xmlFilePath);
            end

            % Set name
            [~, obj.PartName, ~] = fileparts(xmlFilePath);
            
            % Read XML file
            xmlDoc = xmlread(xmlFilePath);
            
            % Parse Far Field Pattern (comma-separated string -> numeric vector)
            farFieldStr = getNodeValue(xmlDoc, 'FarFieldPattern');
            obj.FarFieldPattern = str2double(strsplit(farFieldStr, ','));
            
            % Parse Luminous Intensity
            obj.LuminousIntensity = [...
                str2double(getNodeValue(xmlDoc, 'LuminousIntensityMin'));
                str2double(getNodeValue(xmlDoc, 'LuminousIntensityMax')) 
            ];
            
            % Parse Dominant Wavelength
            obj.DominantWavelength = [...
                str2double(getNodeValue(xmlDoc, 'DominantWavelengthMin'));
                str2double(getNodeValue(xmlDoc, 'DominantWavelengthMax'))
            ];
        end

        function disp(obj)
            fprintf('  LED "%s": %0.3fcd - %0.3fcd, %0.0fnm - %0.0fnm\n', ...
                obj.PartName, ...
                obj.LuminousIntensity(1), obj.LuminousIntensity(2), ...
                obj.DominantWavelength(1), obj.DominantWavelength(2));
        end
    end
end

%% Helper Function
function value = getNodeValue(xmlDoc, tagName)
    % Extracts text content from XML node
    nodeList = xmlDoc.getElementsByTagName(tagName);
    if nodeList.getLength == 0
        error('Tag not found in XML: %s', tagName);
    end
    value = char(nodeList.item(0).getTextContent);
end
