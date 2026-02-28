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
    %   % 计算Hypervolume
    %   hv = MOMetrics.hypervolume(paretoFront, referencePoint);
    %
    %   % 计算IGD
    %   igd = MOMetrics.IGD(paretoFront, trueParetoFront);
    %
    %   % 计算所有指标
    %   metrics = MOMetrics.computeAll(approxPF, truePF, refPoint);
    %
    % 参考文献:
    %   [1] Riquelme, N., et al. (2015). Performance metrics in multi-objective 
    %       optimization. CLEI 2015.
    %   [2] While, L., et al. (2006). A faster algorithm for calculating 
    %       hypervolume. IEEE TEVC.
    %
    % 版本: 1.0.0
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

            pf = sortrows(pf);
            
            if m == 2
                hv = MOMetrics.hypervolume2D(pf, refPoint);
            else
                hv = MOMetrics.hypervolumeND(pf, refPoint);
            end
        end

        function hv = hypervolume2D(pf, refPoint)
            % 2D情况的快速计算
            pf = sortrows(pf, 1);
            n = size(pf, 1);
            
            hv = 0;
            for i = 1:n
                width = refPoint(1) - pf(i, 1);
                if width < 0
                    width = 0;
                end
                
                if i == n
                    height = refPoint(2) - pf(i, 2);
                else
                    height = pf(i+1, 2) - pf(i, 2);
                end
                if height < 0
                    height = 0;
                end
                
                hv = hv + width * height;
            end
        end

        function hv = hypervolumeND(pf, refPoint)
            % 高维情况的HSO算法实现
            [n, m] = size(pf);
            
            if m == 1
                minVal = min(pf(:, 1));
                hv = max(0, refPoint(1) - minVal);
                return;
            end

            pf = sortrows(pf, m);
            hv = 0;
            
            for i = 1:n
                if pf(i, m) < refPoint(m)
                    limits = pf(1:i-1, 1:m-1);
                    if i > 1 && ~isempty(limits)
                        if any(all(limits <= pf(i, 1:m-1), 2))
                            continue;
                        end
                    end
                    
                    sliceVol = MOMetrics.hypervolumeND(pf(i, 1:m-1), refPoint(1:m-1));
                    if i == n
                        height = refPoint(m) - pf(i, m);
                    else
                        height = pf(i+1, m) - pf(i, m);
                    end
                    hv = hv + sliceVol * max(0, height);
                end
            end
        end

        function gd = GD(pf, truePF)
            % GD Generational Distance - 世代距离
            %
            % 衡量近似Pareto前沿到真实Pareto前沿的平均距离
            % GD值越小越好
            %
            % 输入参数:
            %   pf     - 近似Pareto前沿 (N x M)
            %   truePF - 真实Pareto前沿 (P x M)
            %
            % 输出参数:
            %   gd - 世代距离值

            arguments
                pf (:,:) double
                truePF (:,:) double
            end

            n = size(pf, 1);
            if n == 0
                gd = Inf;
                return;
            end

            totalDist = 0;
            for i = 1:n
                minDist = Inf;
                for j = 1:size(truePF, 1)
                    dist = norm(pf(i,:) - truePF(j,:));
                    if dist < minDist
                        minDist = dist;
                    end
                end
                totalDist = totalDist + minDist^2;
            end
            
            gd = sqrt(totalDist) / n;
        end

        function igd = IGD(pf, truePF)
            % IGD Inverted Generational Distance - 逆世代距离
            %
            % 衡量真实Pareto前沿到近似Pareto前沿的平均距离
            % 同时考虑收敛性和多样性
            % IGD值越小越好
            %
            % 输入参数:
            %   pf     - 近似Pareto前沿 (N x M)
            %   truePF - 真实Pareto前沿 (P x M)
            %
            % 输出参数:
            %   igd - 逆世代距离值

            arguments
                pf (:,:) double
                truePF (:,:) double
            end

            p = size(truePF, 1);
            if p == 0
                igd = Inf;
                return;
            end

            if size(pf, 1) == 0
                igd = Inf;
                return;
            end

            totalDist = 0;
            for i = 1:p
                minDist = Inf;
                for j = 1:size(pf, 1)
                    dist = norm(truePF(i,:) - pf(j,:));
                    if dist < minDist
                        minDist = dist;
                    end
                end
                totalDist = totalDist + minDist;
            end
            
            igd = totalDist / p;
        end

        function spacing = Spacing(pf)
            % Spacing 解集间距指标
            %
            % 衡量解集中各个解之间距离的均匀性
            % Spacing值越小表示分布越均匀
            %
            % 输入参数:
            %   pf - 近似Pareto前沿 (N x M)
            %
            % 输出参数:
            %   spacing - 间距值

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
                minDist = Inf;
                for j = 1:n
                    if i ~= j
                        dist = sum(abs(pf(i,:) - pf(j,:)));
                        if dist < minDist
                            minDist = dist;
                        end
                    end
                end
                d(i) = minDist;
            end

            dMean = mean(d);
            spacing = sqrt(sum((d - dMean).^2) / (n - 1));
        end

        function delta = Spread(pf, truePF)
            % Spread (Delta) 扩展度指标
            %
            % 衡量解集在Pareto前沿上的分布程度
            % 考虑边界解的覆盖和中间解的分布均匀性
            % Delta值越小越好
            %
            % 输入参数:
            %   pf     - 近似Pareto前沿 (N x M)
            %   truePF - 真实Pareto前沿 (P x M) (用于确定边界)
            %
            % 输出参数:
            %   delta - 扩展度值

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
                minDist = Inf;
                for j = 1:n
                    if i ~= j
                        dist = norm(pf(i,:) - pf(j,:));
                        if dist < minDist
                            minDist = dist;
                        end
                    end
                end
                d(i) = minDist;
            end
            dMean = mean(d);

            extremes = zeros(m, 2);
            for k = 1:m
                [~, idx] = min(pf(:, k));
                extremes(k, 1) = idx;
                [~, idx] = max(pf(:, k));
                extremes(k, 2) = idx;
            end
            extremeIdx = unique(extremes(:));

            dExtremes = 0;
            for idx = extremeIdx'
                dExtremes = dExtremes + d(idx);
            end

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
            % C值越大表示A相对B越优
            %
            % 输入参数:
            %   pfA - 近似Pareto前沿A (N x M)
            %   pfB - 近似Pareto前沿B (P x M)
            %
            % 输出参数:
            %   c - 覆盖度 [0,1]

            arguments
                pfA (:,:) double
                pfB (:,:) double
            end

            nB = size(pfB, 1);
            if nB == 0
                c = 0;
                return;
            end

            dominated = 0;
            for i = 1:nB
                for j = 1:size(pfA, 1)
                    if MOMetrics.dominates(pfA(j,:), pfB(i,:))
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
            % 最小的epsilon值，使得A中每个解平移epsilon后都能支配B中某解
            % 值越小越好，小于0表示A优于B
            %
            % 输入参数:
            %   pfA - 近似Pareto前沿A (N x M)
            %   pfB - 近似Pareto前沿B (P x M)
            %
            % 输出参数:
            %   eps - epsilon值

            arguments
                pfA (:,:) double
                pfB (:,:) double
            end

            nA = size(pfA, 1);
            nB = size(pfB, 1);
            m = size(pfA, 2);

            if nA == 0 || nB == 0
                eps = Inf;
                return;
            end

            eps = -Inf;
            for i = 1:nA
                minEps = Inf;
                for j = 1:nB
                    maxDiff = max(pfA(i,:) - pfB(j,:));
                    if maxDiff < minEps
                        minEps = maxDiff;
                    end
                end
                if minEps > eps
                    eps = minEps;
                end
            end
        end

        function metrics = computeAll(pf, truePF, refPoint)
            % computeAll 计算所有指标
            %
            % 输入参数:
            %   pf       - 近似Pareto前沿 (N x M)
            %   truePF   - 真实Pareto前沿 (P x M)
            %   refPoint - 参考点 (1 x M)
            %
            % 输出参数:
            %   metrics - 包含所有指标的结构体

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
            %
            % 输入参数:
            %   truePF - 真实Pareto前沿 (P x M)
            %   margin - 边界裕度 (默认0.1, 即10%)
            %
            % 输出参数:
            %   refPoint - 建议的参考点

            arguments
                truePF (:,:) double
                margin (1,1) double = 0.1
            end

            maxVals = max(truePF, [], 1);
            rangeVals = maxVals - min(truePF, [], 1);
            refPoint = maxVals + margin * rangeVals;
        end
    end

    methods (Static, Access = private)
        function tf = dominates(a, b)
            % 判断解a是否支配解b
            tf = all(a <= b) && any(a < b);
        end
    end
end
