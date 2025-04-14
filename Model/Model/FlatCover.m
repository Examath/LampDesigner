classdef FlatCover < LightStep
    %% FlatCover Class
    % Represents a flat transparent cover that absorbs and reflects light.
    %    Define the material using the constructor FlatCover(n, hvl, t).
    %    Use the Angle(horizAngle, vertAngle) method to rotate the cover

    properties
        RefractiveIndex (1,1) double  % Refractive index of the cover material
        AttenuationCoefficient (1,1) double   % Attenuation coefficient (mu) of the material (m^-1)
        Thickness (1,1) double        % Thickness of the cover (m)

        HorizontalAngle (1,1) double = 0  % Rotation angle in horizontal direction
        VerticalAngle (1,1) double = 0    % Rotation angle in vertical direction
    end

    methods
        %% Constructor
        function obj = FlatCover(n, mu, t)
            % Initializes the FlatCover with optical properties.
            % Inputs:
            %   n   - Refractive index
            %   mu  - Attenuation coefficient of the material (m^-1)
            %   t   - Cover thickness (m)

            arguments
                n (1,1)
                mu (1,1)
                t (1,1)
            end

            obj.RefractiveIndex = n;
            obj.AttenuationCoefficient = mu;
            obj.Thickness = t;
        end
        
        %% Set Angle
        function obj = Angle(obj, horizAngle, vertAngle)
            % Sets the horizontal and vertical angles of the cover.
            obj.HorizontalAngle = horizAngle;
            obj.VerticalAngle = vertAngle;
        end
        
        %% GetFarFieldPattern
        function pattern = GetFarFieldPattern(obj, h, v, previous, ~)
            % Computes the modified light pattern after passing through the cover.
            % Inputs:
            %   h, v      - Horizontal and vertical angle matrices
            %   previous  - Previous intensity pattern
            % Output:
            %   pattern   - Modified intensity pattern

            % Compute incidence angles relative to the rotated cover.
            % Angles greater than 90 are trimmed
            theta = min(sqrt((h - obj.HorizontalAngle).^2 + (v - obj.VerticalAngle).^2),90);
            cosTheta = cosd(theta);

            % Compute the cos of the internal incidence angle
            cosPhi = sqrt(1 - sind(theta)/obj.RefractiveIndex);

            % Absorption using exponential decay (Beer-Lambert Law)
            transmittanceAbsorption = exp(-obj.AttenuationCoefficient * obj.Thickness ./ cosPhi);

            % Fresnel reflection (assuming unpolarized light)
            R_s = abs((cosTheta - obj.RefractiveIndex * cosPhi) ./ ...
                      (cosTheta + obj.RefractiveIndex * cosPhi)).^2;
            R_p = abs((cosPhi - obj.RefractiveIndex * cosTheta) ./ ...
                      (cosPhi + obj.RefractiveIndex * cosTheta)).^2;
            
            transmittanceFresnel = ((1 - R_s).^2 + (1 - R_p).^2) / 2;

            % Final intensity after losses
            pattern = previous .* transmittanceFresnel .* transmittanceAbsorption;
        end
    end
end