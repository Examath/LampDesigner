classdef DistributionTest
    %% DistributionTest Class
    % Tests whether a given lamp meets UNECE 148 regulations.

    properties (SetAccess = protected)
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
                minInt (1,1) double
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
            obj.TestPoints = testPoints( ...
                testPoints(:,1) >= obj.InboardAngle & ...
                testPoints(:,1) <= obj.OutboardAngle & ...
                testPoints(:,2) <= obj.UpwardAngle  & ...
                testPoints(:,2) >= obj.DownwardAngle, :);
        end

        %% Test Lamp Compliance
        function sf = Validate(obj, lamp)
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
            hRange = obj.InboardAngle : obj.OutboardAngle;
            vRange = obj.DownwardAngle : obj.UpwardAngle;
            [h, v] = meshgrid(hRange, vRange);

            margin = 10;
            hRange2 = obj.InboardAngle-margin : obj.OutboardAngle+margin;
            vRange2 = obj.DownwardAngle-margin : obj.UpwardAngle+margin;
            [h2, v2] = meshgrid(hRange2, vRange2);
            
            % Validate at min and typical mode
            modes = [0, 0.5];
            modeTxt = ["Min LED Brightness", "Average LED Brightness"];
            sf = inf;

            % Ticks
            tickVals = [obj.MinimumIntensity; ...
                sortrows(unique(obj.TestPoints(:,3))) / 100 * obj.MinimumPeakIntensity]';
            
            tl = tiledlayout(2,1);
            
            for mode = modes
                LightDistribution2 = lamp.GetFarFieldPattern(h2, v2, mode);
                LightDistribution = LightDistribution2(1+margin:end-margin,1+margin:end-margin);
                
                % Plot contour               
                nexttile;
                contourf(h2, v2, LightDistribution2, 20, LineStyle="none");
                hold on;
                [cmatrix, cobj] = contour(h, v, LightDistribution, tickVals, 'LineColor', 'k');
                clabel(cmatrix, cobj, fontsize=8);

                

                % Test Points
                intensity = zeros(size(obj.TestPoints,1),1);
                
                % Iterate through test points
                for i = 1:size(obj.TestPoints, 1)                    
                    % Find closest indices in h and v matrices
                    [~, hIdx] = min(abs(h(1,:) - obj.TestPoints(i, 1)));
                    [~, vIdx] = min(abs(v(:,1) - obj.TestPoints(i, 2)));
                    
                    % Extract intensity at test point
                    intensity(i) = LightDistribution(vIdx, hIdx);
                end                

                passFactor = intensity ./ (obj.TestPoints(:,3) * obj.MinimumPeakIntensity / 100);
                sf = min(min(passFactor), sf);

                % Whole Field Test
                isPass = all(passFactor >= 1) && all(LightDistribution >= obj.MinimumIntensity, "all");
                if (isPass)
                    title(modeTxt(1) + ' ✅Passed');
                else 
                    title(modeTxt(1) + ' ❌FAIL');
                end
                obj.PlotDist(passFactor);
                modeTxt(1) = modeTxt(2);

                hold off;
            end

            cb = colorbar('Ticks', tickVals);
            cb.Layout.Tile = 'east';
            title(tl, sprintf('Validating %s | SF: %.2f', lamp.Name, sf));
            hold off;
        end

        function PlotDist(obj, passFactor)
            % PlotDist plots the test points and optionally compares to actual values.
            % 
            % Parameters:
            %   pass (optional) - A column vector indicating 

            % Plot field limits
            plot([obj.InboardAngle obj.InboardAngle obj.OutboardAngle obj.OutboardAngle, obj.InboardAngle], ...
                    [obj.UpwardAngle, obj.DownwardAngle, obj.DownwardAngle, obj.UpwardAngle, obj.UpwardAngle], ...
                    '-k');
                axis equal;
                xlabel('H (deg)');
                ylabel('V (deg)');
            hold on;

            h = obj.TestPoints(:,1);
            v = obj.TestPoints(:,2);

            % Plot test points
            plot(h, v, 'k.');

            % Plot labels
            if nargin < 2 || isempty(passFactor)
                for i = 1:length(h)
                    text(h(i), v(i), ...
                        sprintf('%.0f', obj.TestPoints(i,3)), ...
                        HorizontalAlignment='center', FontSize=8)
                end
            else
                colors = repmat('r', length(h), 1);
                colors(passFactor >= 1) = 'g';
                for i = 1:length(h)
                    text(h(i), v(i), ...
                        sprintf('%.1f', passFactor(i)), ...
                        Color = colors(i), HorizontalAlignment='center', FontSize=8)
                end
            end

            hold off;
        end
    end
end