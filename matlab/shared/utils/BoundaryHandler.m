classdef BoundaryHandler < handle
    % BoundaryHandler 统一的边界处理工具
    %
    % 消除9+个算法中重复的边界检查代码，支持多种处理策略：
    %   1. clip - 传统裁剪策略（最常用）
    %   2. midpoint - 中点修复策略（L-SHADE风格）
    %   3. reflect - 反射策略
    %   4. random - 随机重置策略
    %
    % 使用示例:
    %   % 对象式调用
    %   handler = BoundaryHandler('clip');
    %   positions = handler.apply(positions, lb, ub);
    %
    %   % 静态方法调用（最常用）
    %   positions = BoundaryHandler.quickClip(positions, lb, ub);
    %
    % 版本: 1.0.0
    % 日期: 2026

    properties (Constant)
        STRATEGY_CLIP = 'clip'
        STRATEGY_MIDPOINT = 'midpoint'
        STRATEGY_REFLECT = 'reflect'
        STRATEGY_RANDOM = 'random'
    end

    properties
        strategy string = "clip"
    end

    methods
        function obj = BoundaryHandler(strategy)
            % BoundaryHandler 构造函数
            %
            % 输入参数:
            %   strategy - 边界处理策略 (默认: 'clip')
            %              可选: 'clip', 'midpoint', 'reflect', 'random'

            if nargin > 0
                validStrategies = {'clip', 'midpoint', 'reflect', 'random'};
                if ~ismember(lower(strategy), validStrategies)
                    error('BoundaryHandler:InvalidStrategy', ...
                        'Strategy must be one of: clip, midpoint, reflect, random');
                end
                obj.strategy = lower(strategy);
            end
        end

        function positions = apply(obj, positions, lb, ub, currentPositions)
            % apply 应用边界处理
            %
            % 输入参数:
            %   positions - 待处理的位置矩阵 (PopSize x Dim)
            %   lb - 下界（标量或向量）
            %   ub - 上界（标量或向量）
            %   currentPositions - 当前位置（用于midpoint策略，可选）
            %
            % 输出参数:
            %   positions - 处理后的位置矩阵

            switch obj.strategy
                case BoundaryHandler.STRATEGY_CLIP
                    positions = obj.clipBounds(positions, lb, ub);
                case BoundaryHandler.STRATEGY_MIDPOINT
                    if nargin < 5
                        error('BoundaryHandler:MissingParameter', ...
                            'midpoint strategy requires currentPositions');
                    end
                    positions = obj.midpointRepair(positions, lb, ub, currentPositions);
                case BoundaryHandler.STRATEGY_REFLECT
                    positions = obj.reflectBounds(positions, lb, ub);
                case BoundaryHandler.STRATEGY_RANDOM
                    positions = obj.randomRepair(positions, lb, ub);
            end
        end
    end

    methods (Access = protected)
        function positions = clipBounds(obj, positions, lb, ub)
            % clipBounds 传统裁剪策略
            %
            % 替换9+个算法中的重复代码
            % 将超出边界的值裁剪到边界值

            % 处理标量边界
            if isscalar(lb) && isscalar(ub)
                flagUb = positions > ub;
                flagLb = positions < lb;
                positions = positions .* ~(flagUb | flagLb) + ub .* flagUb + lb .* flagLb;
            else
                % 处理向量边界
                for i = 1:size(positions, 2)
                    flagUb = positions(:, i) > ub(i);
                    flagLb = positions(:, i) < lb(i);
                    positions(:, i) = positions(:, i) .* ~(flagUb | flagLb) + ...
                        ub(i) .* flagUb + lb(i) .* flagLb;
                end
            end
        end

        function positions = midpointRepair(obj, positions, lb, ub, currentPositions)
            % midpointRepair 中点修复策略
            %
            % 将超出边界的值修复到边界和当前位置的中点
            % 适用于需要保持搜索方向的场景

            % 处理标量边界
            if isscalar(lb) && isscalar(ub)
                flagUb = positions > ub;
                flagLb = positions < lb;

                % 上界修复
                positions(flagUb) = (ub + currentPositions(flagUb)) / 2;
                % 下界修复
                positions(flagLb) = (lb + currentPositions(flagLb)) / 2;
            else
                % 处理向量边界
                for i = 1:size(positions, 2)
                    flagUb = positions(:, i) > ub(i);
                    flagLb = positions(:, i) < lb(i);

                    % 上界修复
                    positions(flagUb, i) = (ub(i) + currentPositions(flagUb, i)) / 2;
                    % 下界修复
                    positions(flagLb, i) = (lb(i) + currentPositions(flagLb, i)) / 2;
                end
            end
        end

        function positions = reflectBounds(obj, positions, lb, ub)
            % reflectBounds 反射策略
            %
            % 将超出边界的值反射回搜索空间
            % 有助于探索边界附近的区域

            % 处理标量边界
            if isscalar(lb) && isscalar(ub)
                % 上界反射
                flagUb = positions > ub;
                positions(flagUb) = 2 * ub - positions(flagUb);

                % 下界反射
                flagLb = positions < lb;
                positions(flagLb) = 2 * lb - positions(flagLb);

                % 再次检查是否在边界内（处理大幅度超出）
                flagUb = positions > ub;
                flagLb = positions < lb;
                positions(flagUb) = ub;
                positions(flagLb) = lb;
            else
                % 处理向量边界
                for i = 1:size(positions, 2)
                    flagUb = positions(:, i) > ub(i);
                    flagLb = positions(:, i) < lb(i);

                    positions(flagUb, i) = 2 * ub(i) - positions(flagUb, i);
                    positions(flagLb, i) = 2 * lb(i) - positions(flagLb, i);

                    flagUb = positions(:, i) > ub(i);
                    flagLb = positions(:, i) < lb(i);
                    positions(flagUb, i) = ub(i);
                    positions(flagLb, i) = lb(i);
                end
            end
        end

        function positions = randomRepair(obj, positions, lb, ub)
            % randomRepair 随机重置策略
            %
            % 将超出边界的值随机重置到搜索空间内
            % 增加种群多样性

            % 处理标量边界
            if isscalar(lb) && isscalar(ub)
                flagUb = positions > ub;
                flagLb = positions < lb;

                positions(flagUb) = lb + rand(sum(flagUb), 1) * (ub - lb);
                positions(flagLb) = lb + rand(sum(flagLb), 1) * (ub - lb);
            else
                % 处理向量边界
                for i = 1:size(positions, 2)
                    flagUb = positions(:, i) > ub(i);
                    flagLb = positions(:, i) < lb(i);

                    nUb = sum(flagUb);
                    nLb = sum(flagLb);

                    if nUb > 0
                        positions(flagUb, i) = lb(i) + rand(nUb, 1) * (ub(i) - lb(i));
                    end
                    if nLb > 0
                        positions(flagLb, i) = lb(i) + rand(nLb, 1) * (ub(i) - lb(i));
                    end
                end
            end
        end
    end

    methods (Static)
        function positions = quickClip(positions, lb, ub)
            % quickClip 静态方法，快速裁剪（最常用场景）
            %
            % 输入参数:
            %   positions - 待处理的位置矩阵 (PopSize x Dim)
            %   lb - 下界（标量或向量）
            %   ub - 上界（标量或向量）
            %
            % 输出参数:
            %   positions - 处理后的位置矩阵
            %
            % 使用示例:
            %   positions = BoundaryHandler.quickClip(positions, -100, 100);

            % 处理标量边界
            if isscalar(lb) && isscalar(ub)
                flagUb = positions > ub;
                flagLb = positions < lb;
                positions = positions .* ~(flagUb | flagLb) + ub .* flagUb + lb .* flagLb;
            else
                % 处理向量边界
                for i = 1:size(positions, 2)
                    flagUb = positions(:, i) > ub(i);
                    flagLb = positions(:, i) < lb(i);
                    positions(:, i) = positions(:, i) .* ~(flagUb | flagLb) + ...
                        ub(i) .* flagUb + lb(i) .* flagLb;
                end
            end
        end
    end
end
