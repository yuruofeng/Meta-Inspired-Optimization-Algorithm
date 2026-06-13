classdef MOMetrics < handle
    % MOMetrics 多目标优化性能评价指标
    %
    % 提供常用的多目标优化算法性能评价指标:
    %   - Hypervolume (HV): 超体积指标
    %   - Generational Distance (GD): 世代距离
    %   - Inverted Generational Distance (IGD): 逆世代距离
    %   - Spacing: 解集间距
    %   - Spread (Delta): 扩展度
    %   - Epsilon Indicator: epsilon指标
    %   - Set Coverage (C-metric): 集合覆盖度
    %
    % 使用示例:
    %   hv = MOMetrics.hypervolume(paretoFront, referencePoint);
    %   igd = MOMetrics.IGD(paretoFront, trueParetoFront);
    %   metrics = MOMetrics.computeAll(approxPF, truePF, refPoint);
    %
    % 参考文献:
    %   [1] Riquelme, N., et al. (2015). Performance metrics in multi-objective 
    %       optimization. CLEI 2015.
    %   [2] While, L., et al. (2006). A faster algorithm for calculating 
    %       hypervolume. IEEE TEVC.
    %
    % 版本: 1.1.0
    % 日期: 2026
    % 作者: RUOFENG YU

    methods (Static)
        
        function hv = hypervolume(pf, refPoint)
            % hypervolume 计算超体积指标
            %
            % 衡量目标空间中被近似Pareto前沿覆盖的体积
            % HV值越大越好
            %
            % 输入参数:
            %   pf       - 近似Pareto前沿 (N x M矩阵, N个解, M个目标)
            %   refPoint - 参考点 (1 x M向量, 应比所有解更差)
            %
            % 输出参数:
            %   hv - 超体积值

            arguments
                pf (:,:) double
                refPoint (1,:) double
            end

            [n, m] = size(pf);
            if length(refPoint) ~= m
                error('MOMetrics:DimensionMismatch', ...
                    'Reference point dimension must match number of objectives');
            end

            if n == 0
                hv = 0;
                return;
            end

            validMask = all(pf < refPoint, 2);
            pf = pf(validMask, :);
            
            if isempty(pf)
                hv = 0;
                return;
            end
            
            pf = MOMetrics.filterDominated(pf);
            
            if m == 2
                hv = MOMetrics.hypervolume2D(pf, refPoint);
            elseif m == 3
                hv = MOMetrics.hypervolume3D(pf, refPoint);
            else
                hv = MOMetrics.hypervolumeWFG(pf, refPoint);
            end
        end

        function hv = hypervolume2D(pf, refPoint)
            % hypervolume2D 2D情况的O(n log n)快速计算
            %
            % 使用扫描线算法，复杂度O(n log n)

            pf = sortrows(pf, 1);
            n = size(pf, 1);
            
            hv = 0;
            prevY = refPoint(2);
            
            for i = n:-1:1
                if pf(i, 2) < prevY
                    width = refPoint(1) - pf(i, 1);
                    height = prevY - pf(i, 2);
                    if width > 0 && height > 0
                        hv = hv + width * height;
                    end
                    prevY = pf(i, 2);
                end
            end
        end

        function hv = hypervolume3D(pf, refPoint)
            % hypervolume3D 3D情况的O(n^2)计算
            %
            % 使用改进的切片算法

            pf = sortrows(pf, 3);
            n = size(pf, 1);
            
            hv = 0;
            prevZ = refPoint(3);
            
            for i = n:-1:1
                if pf(i, 3) < prevZ
                    sliceHV = MOMetrics.hypervolume2D(pf(i:end, 1:2), refPoint(1:2));
                    height = prevZ - pf(i, 3);
                    hv = hv + sliceHV * height;
                    prevZ = pf(i, 3);
                end
            end
        end

        function hv = hypervolumeWFG(pf, refPoint)
            % hypervolumeWFG WFG算法实现 (Walking Fish Group)
            %
            % 对高维问题更高效的实现
            % 复杂度: O(n^{d/2})

            [n, m] = size(pf);
            
            if n > 100
                hv = MOMetrics.hypervolumeMonteCarlo(pf, refPoint, 10000);
                return;
            end
            
            pf = sortrows(pf, m);
            hv = 0;
            
            for i = 1:n
                if pf(i, m) < refPoint(m)
                    exclusiveVol = MOMetrics.computeExclusiveHV(pf, i, refPoint);
                    if i == n
                        height = refPoint(m) - pf(i, m);
                    else
                        height = pf(i+1, m) - pf(i, m);
                    end
                    hv = hv + exclusiveVol * max(0, height);
                end
            end
        end

        function vol = computeExclusiveHV(pf, idx, refPoint)
            % computeExclusiveHV 计算某个解的排他性贡献
            [n, m] = size(pf);
            point = pf(idx, :);
            
            lowerBounds = -inf(1, m);
            for i = 1:n
                if i ~= idx
                    dominated = true;
                    for d = 1:m
                        if pf(i, d) < point(d)
                            dominated = false;
                            break;
                        end
                    end
                    if dominated
                        for d = 1:m
                            lowerBounds(d) = max(lowerBounds(d), pf(i, d));
                        end
                    end
                end
            end
            
            vol = prod(max(0, refPoint - max(point, lowerBounds)));
        end

        function hv = hypervolumeMonteCarlo(pf, refPoint, numSamples)
            % hypervolumeMonteCarlo 蒙特卡洛近似计算
            %
            % 用于高维、大规模问题的快速近似

            arguments
                pf (:,:) double
                refPoint (1,:) double
                numSamples (1,1) double = 10000
            end

            [n, m] = size(pf);
            
            minVals = min(pf, [], 1);
            ranges = refPoint - minVals;
            totalVol = prod(ranges);
            
            samples = rand(numSamples, m);
            samples = samples .* ranges + minVals;
            
            dominated = false(numSamples, 1);
            for i = 1:n
                dominated = dominated | all(samples <= pf(i, :), 2);
            end
            
            hv = totalVol * sum(dominated) / numSamples;
        end

        function pf = filterDominated(pf)
            % filterDominated 过滤掉被支配的解
            n = size(pf, 1);
            if n <= 1
                return;
            end
            
            isDominated = false(n, 1);
            
            for i = 1:n
                if ~isDominated(i)
                    for j = i+1:n
                        if ~isDominated(j)
                            if all(pf(i, :) <= pf(j, :)) && any(pf(i, :) < pf(j, :))
                                isDominated(j) = true;
                            elseif all(pf(j, :) <= pf(i, :)) && any(pf(j, :) < pf(i, :))
                                isDominated(i) = true;
                            end
                        end
                    end
                end
            end
            
            pf = pf(~isDominated, :);
        end

        function gd = GD(pf, truePF)
            % GD Generational Distance - 世代距离
            %
            % 衡量近似Pareto前沿到真实Pareto前沿的平均距离
            % GD值越小越好

            arguments
                pf (:,:) double
                truePF (:,:) double
            end

            n = size(pf, 1);
            if n == 0
                gd = Inf;
                return;
            end

            nTrue = size(truePF, 1);
            
            distMatrix = zeros(n, nTrue);
            for i = 1:nTrue
                diff = pf - truePF(i, :);
                distMatrix(:, i) = sqrt(sum(diff.^2, 2));
            end
            
            minDists = min(distMatrix, [], 2);
            
            gd = sqrt(sum(minDists.^2)) / n;
        end

        function igd = IGD(pf, truePF)
            % IGD Inverted Generational Distance - 逆世代距离
            %
            % 衡量真实Pareto前沿到近似Pareto前沿的平均距离
            % IGD值越小越好

            arguments
                pf (:,:) double
                truePF (:,:) double
            end

            p = size(truePF, 1);
            if p == 0
                igd = Inf;
                return;
            end

            n = size(pf, 1);
            if n == 0
                igd = Inf;
                return;
            end

            distMatrix = zeros(p, n);
            for i = 1:n
                diff = truePF - pf(i, :);
                distMatrix(:, i) = sqrt(sum(diff.^2, 2));
            end
            
            minDists = min(distMatrix, [], 2);
            
            igd = sum(minDists) / p;
        end

        function spacing = Spacing(pf)
            % Spacing 解集间距指标
            %
            % Spacing值越小表示分布越均匀

            arguments
                pf (:,:) double
            end

            n = size(pf, 1);
            if n <= 1
                spacing = 0;
                return;
            end

            d = zeros(n, 1);
            
            for i = 1:n
                others = pf([1:i-1, i+1:n], :);
                if ~isempty(others)
                    d(i) = min(sum(abs(others - pf(i, :)), 2));
                end
            end

            dMean = mean(d);
            spacing = sqrt(sum((d - dMean).^2) / (n - 1));
        end

        function delta = Spread(pf, truePF)
            % Spread (Delta) 扩展度指标
            %
            % Delta值越小越好
            % Note: truePF parameter is reserved for future use

            arguments
                pf (:,:) double
                truePF (:,:) double
            end

            n = size(pf, 1);
            m = size(pf, 2);
            
            if n <= 1
                delta = 1;
                return;
            end

            d = zeros(n, 1);
            for i = 1:n
                others = pf([1:i-1, i+1:n], :);
                d(i) = min(sqrt(sum((others - pf(i, :)).^2, 2)));
            end
            dMean = mean(d);

            extremeIdx = unique([...
                argmin(pf(:, 1)), argmax(pf(:, 1)); ...
                argmin(pf(:, 2)), argmax(pf(:, 2)) ...
            ]');
            if m > 2
                for k = 3:m
                    extremeIdx = unique([extremeIdx, argmin(pf(:, k)), argmax(pf(:, k))]);
                end
            end

            dExtremes = sum(d(extremeIdx));

            nEff = n - length(extremeIdx);
            if nEff > 0 && dMean > 0
                delta = (dExtremes + sum(abs(d - dMean))) / (dExtremes + nEff * dMean);
            else
                delta = 1;
            end
        end

        function c = SetCoverage(pfA, pfB)
            % SetCoverage C-metric 集合覆盖度
            %
            % C(A,B) = 被A支配的B中解的比例

            arguments
                pfA (:,:) double
                pfB (:,:) double
            end

            nB = size(pfB, 1);
            if nB == 0
                c = 0;
                return;
            end

            nA = size(pfA, 1);
            dominated = 0;
            
            for i = 1:nB
                for j = 1:nA
                    if all(pfA(j, :) <= pfB(i, :)) && any(pfA(j, :) < pfB(i, :))
                        dominated = dominated + 1;
                        break;
                    end
                end
            end

            c = dominated / nB;
        end

        function eps = EpsilonIndicator(pfA, pfB)
            % EpsilonIndicator 加法epsilon指标
            %
            % 值越小越好，小于0表示A优于B

            arguments
                pfA (:,:) double
                pfB (:,:) double
            end

            nA = size(pfA, 1);
            nB = size(pfB, 1);

            if nA == 0 || nB == 0
                eps = Inf;
                return;
            end

            eps = -Inf;
            for i = 1:nA
                minEps = min(max(pfA(i, :) - pfB, [], 2));
                if minEps > eps
                    eps = minEps;
                end
            end
        end

        function metrics = computeAll(pf, truePF, refPoint)
            % computeAll 计算所有指标

            arguments
                pf (:,:) double
                truePF (:,:) double
                refPoint (1,:) double
            end

            metrics = struct(...
                'hypervolume', MOMetrics.hypervolume(pf, refPoint), ...
                'GD', MOMetrics.GD(pf, truePF), ...
                'IGD', MOMetrics.IGD(pf, truePF), ...
                'spacing', MOMetrics.Spacing(pf), ...
                'spread', MOMetrics.Spread(pf, truePF) ...
            );
        end

        function refPoint = suggestReferencePoint(truePF, margin)
            % suggestReferencePoint 根据真实Pareto前沿建议参考点

            arguments
                truePF (:,:) double
                margin (1,1) double = 0.1
            end

            maxVals = max(truePF, [], 1);
            rangeVals = maxVals - min(truePF, [], 1);
            refPoint = maxVals + margin * rangeVals;
        end
    end
end

function idx = argmin(v)
    [~, idx] = min(v);
end

function idx = argmax(v)
    [~, idx] = max(v);
end
