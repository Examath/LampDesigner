classdef Lamp < handle
    %% Lamp Class
    % Represents a lamp consisting of multiple LightStep components.
    
    properties
        Name (1,1) string          % Name of the lamp
        LightSteps LightStep = LedArray.empty(); % Array of LightStep objects
    end
    
    methods
        %% Constructor
        function obj = Lamp(name)
            % Initializes the Lamp with a given name.
            % Inputs:
            %   name - Name of the lamp (string)
            arguments
                name (1,1) string
            end
            obj.Name = name;
        end
        
        %% Add LightStep
        function obj = Add(obj, step)
            % Adds a LightStep component to the lamp.
            % Inputs:
            %   step - An instance of a LightStep subclass
            arguments
                obj
                step (1,1) LightStep
            end
            obj.LightSteps(end+1) = step;
        end
        
        %% Get Far Field Pattern
        function pattern = GetFarFieldPattern(obj, h, v, mode)
            % Computes the far-field pattern by sequentially applying all LightSteps.
            % Inputs:
            %   h, v  - Matrices representing horizontal and vertical angles
            %   mode  - 0 (min) or 1 (max) luminous intensity mode
            % Output:
            %   pattern - Resulting luminous intensity matrix
            
            arguments
                obj
                h (:,:) double
                v (:,:) double
                mode (1,1) double
            end
            
            % Initialize pattern with zeros
            pattern = zeros(size(h));
            
            % Apply each LightStep sequentially
            for i = 1:numel(obj.LightSteps)
                pattern = obj.LightSteps(i).GetFarFieldPattern(h, v, pattern, mode);
            end
        end
    end
end