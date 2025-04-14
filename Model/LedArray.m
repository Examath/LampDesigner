classdef LedArray < LightStep
    %% LedArray Class
    % Represents an array of LEDs contributing to the overall light pattern.
    
    properties
        Led Led  % Instance of the Led class
        Quantity (1,1) double        % Number of LEDs in the array
        HorizontalAngle (1,1) double % Horizontal mounting angles (degrees)
        VerticalAngle (1,1) double   % Vertical mounting angles (degrees)
    end
    
    methods
        %% Constructor
        function obj = LedArray(led, quantity, horizAngle, vertAngle)
            % Initializes an LED array with specified parameters.
            % Inputs:
            %   led - Instance of the Led class
            %   quantity - Number of LEDs in the array
            %   horizAngle - Horizontal mounting angles
            %   vertAngle - Vertical mounting angles

            arguments
                led Led
                quantity
                horizAngle (1,1)
                vertAngle (1,1)
            end
            
            obj.Led = led;
            obj.Quantity = quantity;
            obj.HorizontalAngle = horizAngle;
            obj.VerticalAngle = vertAngle;
        end
        
        %% GetFarFieldPattern Implementation
        function pattern = GetFarFieldPattern(obj, h, v, previous, mode)
            % Computes the far-field luminous intensity pattern for the LED array.
            % Inputs:
            %   h, v     - Angular grid matrices (degrees)
            %   previous - Previous luminous intensity pattern matrix
            %   mode     - 0 (min) or 1 (max) for luminous intensity scaling
            % Output:
            %   pattern  - Updated luminous intensity pattern

            arguments
                obj (1,1) LedArray
                h
                v
                previous
                mode (1,1)
            end
            
            % Compute distance from LED center to each point in the pattern
            angleOffset = atand(sqrt(tand(h - obj.HorizontalAngle).^2 + tand(v - obj.VerticalAngle).^2));
            
            % Round to nearest integer and ensure within bounds
            angleIndices = floor(angleOffset);
            angleRemainder = mod(angleOffset, 1);
            maxLength = length(obj.Led.FarFieldPattern) - 2;
            angleIndices(angleIndices > maxLength) = maxLength;
            
            % Fetch corresponding intensity values from the 1D pattern
            farField2D = obj.Led.FarFieldPattern(angleIndices + 1) .* (1 - angleRemainder) ...
                       + obj.Led.FarFieldPattern(angleIndices + 2) .* angleRemainder;

            % Get the peak intensity
            intensity = obj.Led.LuminousIntensity(1) * (1 - mode) + obj.Led.LuminousIntensity(2) * mode;
            
            % Compute final pattern
            pattern = previous + (prod(obj.Quantity) * intensity * farField2D);
        end
    end
end