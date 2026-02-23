classdef (Abstract) CrossoverOperator < handle
    % CrossoverOperator 交叉算子抽象基类
    %
    % 定义遗传算法交叉算子的统一接口。所有具体交叉算子
    % (单点、双点、均匀、算术交叉等)必须继承此类。
    %
    % 参考规范: metaheuristic_spec.md §3.2
    %
    % 使用示例:
    %   classdef UniformCrossover < CrossoverOperator
    %       methods
    %           function [offspring1, offspring2] = cross(obj, parent1, parent2)
    %               % 实现具体交叉逻辑
    %           end
    %       end
    %   end
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties
        crossoverRate double = 0.9  % 交叉概率
    end

    methods
        function obj = CrossoverOperator(crossoverRate)
            % CrossoverOperator 构造函数
            %
            % 输入参数:
            %   crossoverRate - 交叉概率 (默认: 0.9)

            if nargin > 0
                if crossoverRate < 0 || crossoverRate > 1
                    error('CrossoverOperator:InvalidParam', ...
                        'crossoverRate must be in [0, 1]');
                end
                obj.crossoverRate = crossoverRate;
            end
        end
    end

    methods (Abstract)
        [offspring1, offspring2] = cross(obj, parent1, parent2)
        % cross 执行交叉操作
        %
        % 输入参数:
        %   parent1 - 第一个父代 (1 x Dim)
        %   parent2 - 第二个父代 (1 x Dim)
        %
        % 输出参数:
        %   offspring1 - 第一个子代 (1 x Dim)
        %   offspring2 - 第二个子代 (1 x Dim)
    end

    methods
        function [offspring1, offspring2] = crossWithRate(obj, parent1, parent2)
            % crossWithRate 带交叉概率的交叉操作
            %
            % 以 crossoverRate 的概率执行交叉，否则直接复制父代
            %
            % 输入参数:
            %   parent1 - 第一个父代 (1 x Dim)
            %   parent2 - 第二个父代 (1 x Dim)
            %
            % 输出参数:
            %   offspring1 - 第一个子代 (1 x Dim)
            %   offspring2 - 第二个子代 (1 x Dim)

            if rand() < obj.crossoverRate
                [offspring1, offspring2] = obj.cross(parent1, parent2);
            else
                offspring1 = parent1;
                offspring2 = parent2;
            end
        end

        function newPopulation = crossPopulation(obj, population, fitness, selector)
            % crossPopulation 对整个种群执行交叉
            %
            % 输入参数:
            %   population - 种群矩阵 (N x Dim)
            %   fitness - 适应度向量 (N x 1)
            %   selector - 选择算子
            %
            % 输出参数:
            %   newPopulation - 交叉后的新种群 (N x Dim)

            popSize = size(population, 1);
            dim = size(population, 2);
            newPopulation = zeros(popSize, dim);

            for i = 1:2:popSize
                % 选择两个父代
                parentIndices = selector.select(population, fitness, 2);
                parent1 = population(parentIndices(1), :);
                parent2 = population(parentIndices(2), :);

                % 交叉
                [offspring1, offspring2] = obj.crossWithRate(parent1, parent2);

                % 存储子代
                newPopulation(i, :) = offspring1;
                if i + 1 <= popSize
                    newPopulation(i + 1, :) = offspring2;
                end
            end
        end
    end
end
