classdef (Abstract) LightStep < matlab.mixin.Heterogeneous
    %% Step (Abstract Class)
    % Represents a step in the optical system that modifies the far-field luminous intensity pattern.
    % Derived classes must implement the GetFarFieldPattern method.
    
    methods (Abstract)
        GetFarFieldPattern(obj, h, v, previous, mode)
        % Computes the far-field luminous intensity pattern
    end
end
