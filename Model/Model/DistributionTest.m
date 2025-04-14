classdef DistributionTest
    %% DistributionTest Class
    % Tests whether a given lamp meets UNECE 148 regulations.

    properties
        MinimumIntensity (1,1) double  % Minimum allowable intensity (cd)
        MinimumPeakIntensity (1,1) double % Minimum peak intensity (cd)
        MaximumPeakIntensity (1,1) double % Maximum peak intensity (cd)
        
        InboardAngle (1,1) double  % Inboard measurement angle
        OutboardAngle (1,1) double % Outboard measurement angle
        UpwardAngle (1,1) double   % Upward measurement angle
        DownwardAngle (1,1) double % Downward measurement angle

        TestPoints (:,3) double % [h, v, f] - measurement angles and required intensity factor
    end

    methods
        %% Constructor
        function obj = DistributionTest(minInt, minPeak, maxPeak, inAngle, outAngle, upAngle, downAngle, testPoints)
            % Initializes the DistributionTest with regulatory parameters.
            % Inputs:
            %   minInt   - Minimum intensity (cd)
            %   minPeak  - Minimum peak intensity (cd)
            %   maxPeak  - Maximum peak intensity (cd)
            %   inAngle  - Inboard angle (degrees)
            %   outAngle - Outboard angle (degrees)
            %   upAngle  - Upward angle (degrees)
            %   downAngle - Downward angle (degrees)
            %   testPoints - Nx3 matrix with [h, v, f] test points

            arguments
                minInt (1,1) double {mustBePositive}
                minPeak (1,1) double {mustBePositive}
                maxPeak (1,1) double {mustBePositive}
                inAngle (1,1) double
                outAngle (1,1) double
                upAngle (1,1) double
                downAngle (1,1) double
                testPoints (:,3) double
            end

            obj.MinimumIntensity = minInt;
            obj.MinimumPeakIntensity = minPeak;
            obj.MaximumPeakIntensity = maxPeak;
            obj.InboardAngle = inAngle;
            obj.OutboardAngle = outAngle;
            obj.UpwardAngle = upAngle;
            obj.DownwardAngle = downAngle;
            obj.TestPoints = testPoints;
        end

        %% Test Lamp Compliance
        function result = Validate(obj, lamp)
            % Validates whether a lamp meets UNECE 148 requirements.
            % Inputs:
            %   lamp - Lamp object to be tested
            % Output:
            %   result - Boolean indicating pass/fail status

            arguments
                obj
                lamp (1,1) Lamp
            end

            % Define measurement range
            hRange = obj.InboardAngle-10 : obj.OutboardAngle+10;
            vRange = obj.DownwardAngle-10 : obj.UpwardAngle+10;
            [h, v] = meshgrid(hRange, vRange);
            
            % Validate at min and typical mode
            modes = [0, 0.5];
            result = true;

            % Ticks
            tickVals = [obj.MinimumIntensity; ...
                sortrows(unique(obj.TestPoints(:,3))) / 100 * obj.MinimumPeakIntensity]';
            
            tiledlayout(2,1);
            
            for mode = modes
                LightDistribution = lamp.GetFarFieldPattern(h, v, mode);
                
                % Plot contour               
                nexttile;
                contourf(h, v, LightDistribution, tickVals);
                hold on;
                axis equal;
                title(sprintf('Lamp Validation - Mode %.1f', mode));
                xlabel('Horizontal Angle (deg)');
                ylabel('Vertical Angle (deg)');
                
                % Iterate through test points
                for i = 1:size(obj.TestPoints, 1)
                    hTest = obj.TestPoints(i, 1);
                    vTest = obj.TestPoints(i, 2);
                    factor = obj.TestPoints(i, 3) / 100;
                    
                    % Find closest indices in h and v matrices
                    [~, hIdx] = min(abs(h(1,:) - hTest));
                    [~, vIdx] = min(abs(v(:,1) - vTest));
                    
                    % Extract intensity at test point
                    intensity = LightDistribution(vIdx, hIdx);
                    
                    % Compute required intensity
                    requiredIntensity = factor * obj.MinimumPeakIntensity;
                    
                    % Determine pass/fail
                    pass = intensity >= requiredIntensity;
                    if ~pass
                        result = false;
                    end
                    
                    % Plot test points
                    color = 'g';
                    if ~pass
                        color = 'r';
                    end
                    text(hTest, vTest, sprintf('%.0f\n%.1f', intensity, intensity / requiredIntensity), ...
                        'Color', color, 'HorizontalAlignment', 'center', 'FontSize',8);
                end
                hold off;
            end

            cb = colorbar('Ticks', tickVals);
            cb.Layout.Tile = 'east';
        end
    end
end