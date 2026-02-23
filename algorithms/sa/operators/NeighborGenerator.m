classdef NeighborGenerator < handle
    % NeighborGenerator 邻居生成器
    %
    % 用于模拟退火算法的邻居解生成。支持高斯、均匀、柯西
    % 三种邻居生成策略。
    %
    % 策略说明:
    %   - gaussian: 高斯扰动，适合连续优化
    %   - uniform: 均匀扰动，探索范围更广
    %   - cauchy: 柯西扰动，具有长尾特性，适合跳出局部最优
    %
    % 参考文献:
    %   X. Yao, Y. Liu, G. Liu
    %   "Evolutionary Programming Made Faster"
    %   IEEE Trans. Evolutionary Computation, 1999
    %
    % 使用示例:
    %   generator = NeighborGenerator('gaussian', 0.1);
    %   neighbor = generator.generate(solution, lb, ub);
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties
        neighborType char = 'gaussian'  % 邻居类型: gaussian, uniform, cauchy
        stepSize double = 0.1           % 步长 (相对于搜索范围的比例)
    end

    methods
        function obj = NeighborGenerator(varargin)
            % NeighborGenerator 构造函数
            %
            % 输入参数 (键值对):
            %   'neighborType' - 邻居类型 (默认: 'gaussian')
            %   'stepSize' - 步长比例 (默认: 0.1)

            p = inputParser;
            addParameter(p, 'neighborType', 'gaussian', ...
                @(x) any(validatestring(x, {'gaussian', 'uniform', 'cauchy'})));
            addParameter(p, 'stepSize', 0.1, @(x) x > 0);

            parse(p, varargin{:});

            obj.neighborType = p.Results.neighborType;
            obj.stepSize = p.Results.stepSize;
        end

        function neighbor = generate(obj, solution, lb, ub)
            % generate 生成邻居解
            %
            % 输入参数:
            %   solution - 当前解向量 (1 x Dim)
            %   lb - 下界 (标量或向量)
            %   ub - 上界 (标量或向量)
            %
            % 输出参数:
            %   neighbor - 邻居解向量

            dim = length(solution);

            % 计算搜索范围
            if isscalar(lb)
                range = ub - lb;
            else
                range = ub - lb;
            end

            % 计算步长
            step = obj.stepSize * range;

            % 根据策略生成扰动
            switch lower(obj.neighborType)
                case 'gaussian'
                    perturbation = randn(1, dim) .* step;
                case 'uniform'
                    perturbation = (rand(1, dim) * 2 - 1) .* step;
                case 'cauchy'
                    % 柯西分布：具有长尾特性
                    perturbation = tan(pi * (rand(1, dim) - 0.5)) .* step;
                otherwise
                    perturbation = randn(1, dim) .* step;
            end

            % 生成邻居
            neighbor = solution + perturbation;

            % 边界处理
            neighbor = max(neighbor, lb);
            neighbor = min(neighbor, ub);
        end

        function neighbor = generateWithScale(obj, solution, lb, ub, temperature, initialTemp)
            % generateWithScale 带温度缩放的邻居生成
            %
            % 输入参数:
            %   solution - 当前解向量
            %   lb - 下界
            %   ub - 上界
            %   temperature - 当前温度
            %   initialTemp - 初始温度
            %
            % 输出参数:
            %   neighbor - 邻居解向量
            %
            % 说明:
            %   步长随温度降低而减小，初期大步探索，后期小步精细搜索

            % 计算温度缩放因子
            scale = sqrt(temperature / initialTemp);
            dim = length(solution);

            % 计算搜索范围
            if isscalar(lb)
                range = ub - lb;
            else
                range = ub - lb;
            end

            % 缩放后的步长
            step = obj.stepSize * range * scale;

            % 生成扰动
            switch lower(obj.neighborType)
                case 'gaussian'
                    perturbation = randn(1, dim) .* step;
                case 'uniform'
                    perturbation = (rand(1, dim) * 2 - 1) .* step;
                case 'cauchy'
                    perturbation = tan(pi * (rand(1, dim) - 0.5)) .* step;
                otherwise
                    perturbation = randn(1, dim) .* step;
            end

            neighbor = solution + perturbation;
            neighbor = max(neighbor, lb);
            neighbor = min(neighbor, ub);
        end
    end

    methods (Static)
        function neighbor = generateStatic(solution, lb, ub, stepSize, neighborType)
            % generateStatic 静态版本的邻居生成
            %
            % 输入参数:
            %   solution - 当前解向量
            %   lb - 下界
            %   ub - 上界
            %   stepSize - 步长比例
            %   neighborType - 邻居类型
            %
            % 输出参数:
            %   neighbor - 邻居解向量

            if nargin < 5
                neighborType = 'gaussian';
            end

            dim = length(solution);
            range = ub - lb;
            step = stepSize * range;

            switch lower(neighborType)
                case 'gaussian'
                    perturbation = randn(1, dim) .* step;
                case 'uniform'
                    perturbation = (rand(1, dim) * 2 - 1) .* step;
                case 'cauchy'
                    perturbation = tan(pi * (rand(1, dim) - 0.5)) .* step;
                otherwise
                    perturbation = randn(1, dim) .* step;
            end

            neighbor = solution + perturbation;
            neighbor = max(neighbor, lb);
            neighbor = min(neighbor, ub);
        end
    end
end
